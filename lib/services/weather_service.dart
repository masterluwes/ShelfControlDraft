import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shelf_control/secrets.dart';

class _PhCity {
  final String name;
  final double lat;
  final double lon;
  const _PhCity(this.name, this.lat, this.lon);
}

// Feel free to tweak this list
const List<_PhCity> _phSample = [
  _PhCity('Metro Manila', 14.5995, 120.9842),
  _PhCity('Cebu City', 10.3157, 123.8854),
  _PhCity('Davao City', 7.1907, 125.4553),
  _PhCity('Baguio City', 16.4023, 120.5960),
  _PhCity('Iloilo City', 10.7202, 122.5621),
  _PhCity('Cagayan de Oro', 8.4542, 124.6319),
];

String _windowTextWithAdvisory(DateTime now, {required bool hasOfficialAlert}) {
  final fmt = DateFormat('EEE, MMM d, h:mm a');
  final today = 'Today, ${fmt.format(now)}';
  final tomorrow = fmt.format(now.add(const Duration(hours: 24)));
  final tail = hasOfficialAlert ? 'Advisories present' : 'No active advisories';
  return '$today - $tomorrow • $tail';
}

enum WeatherLevel { red, green, blue }

class WeatherAlert {
  final WeatherLevel level;
  final String headline; // e.g., Severe Weather: Metropolitan Manila
  final String windowText; // e.g., Thu, Sep 25, 5:35 PM - Fri, Sep 26, 5:35 AM
  final String body; // advisory text
  final String source; // "PAG-ASA"
  final List<String> stockUpList;
  final String areaName; // "Metropolitan Manila"

  const WeatherAlert({
    required this.level,
    required this.headline,
    required this.windowText,
    required this.body,
    required this.source,
    required this.areaName,
    this.stockUpList = const [],
  });
}

class WeatherService {
  WeatherService._();
  static final WeatherService instance = WeatherService._();

  // Philippine bounding box (rough) to validate emulator/real GPS
  static bool isInPhilippines(double lat, double lon) {
    // Approx box: 4.5°N–21.5°N, 116°E–127°E
    return lat >= 4.5 && lat <= 21.5 && lon >= 116.0 && lon <= 127.0;
  }

  static String windowTextWithAdvisory(DateTime now,
      {required bool hasOfficialAlert}) {
    final fmt = DateFormat('EEE, MMM d, h:mm a');
    final today = 'Today, ${fmt.format(now)}';
    final tomorrow = fmt.format(now.add(const Duration(hours: 24)));
    final tail =
        hasOfficialAlert ? 'Advisories present' : 'No active advisories';
    return '$today - $tomorrow • $tail';
  }

  /// Step 1: Get user position (prompts permission if needed)
  Future<Position> getPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }
    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied)
      perm = await Geolocator.requestPermission();
    if (perm == LocationPermission.denied) {
      throw Exception('Location permission denied.');
    }
    if (perm == LocationPermission.deniedForever) {
      throw Exception('Location permission permanently denied.');
    }
    return Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
  }

  /// Step 2: Reverse-geocode to a friendly area string ("Metropolitan Manila", etc.)
  Future<String> getAreaName(Position pos) async {
    final placemarks =
        await placemarkFromCoordinates(pos.latitude, pos.longitude);
    if (placemarks.isEmpty) return 'Your Area';
    final p = placemarks.first;

    // Try to produce a nice Philippine-style area label
    // Examples: "Metropolitan Manila" (if administrativeArea == NCR), otherwise "City, Province"
    final admin = (p.administrativeArea ?? '').trim();
    final locality = (p.locality ?? '').trim();
    final subAdmin = (p.subAdministrativeArea ?? '').trim();

    // Treat NCR variants
    if (admin.toUpperCase().contains('NCR') ||
        admin.toUpperCase().contains('METRO MANILA')) {
      return 'Metropolitan Manila';
    }

    // Prefer "Locality, Province/SubAdmin"
    if (locality.isNotEmpty && admin.isNotEmpty) return '$locality, $admin';
    if (locality.isNotEmpty && subAdmin.isNotEmpty)
      return '$locality, $subAdmin';
    return locality.isNotEmpty
        ? locality
        : (admin.isNotEmpty ? admin : 'Your Area');
  }

  /// Metro Manila fallback when user location is unavailable/denied.
  Future<WeatherAlert> fetchAlertForDefaultPH() async {
    // Metro Manila coords
    const double lat = 14.5995;
    const double lon = 120.9842;
    const String areaOverride = 'Metro Manila, Philippines';

    final uri = Uri.parse(
      'https://api.weatherapi.com/v1/forecast.json'
      '?key=$weatherApiKey'
      '&q=$lat,$lon'
      '&days=3'
      '&aqi=no'
      '&alerts=yes',
    );

    final res = await http.get(uri).timeout(const Duration(seconds: 10));
    if (res.statusCode != 200) {
      throw Exception('WeatherAPI ${res.statusCode}: ${res.body}');
    }

    final Map<String, dynamic> data =
        json.decode(res.body) as Map<String, dynamic>;
    final Map<String, dynamic> current =
        (data['current'] ?? {}) as Map<String, dynamic>;
    final Map<String, dynamic> forecast =
        (data['forecast'] ?? {}) as Map<String, dynamic>;
    final List<Map<String, dynamic>> alerts =
        (((data['alerts'] ?? {}) as Map)['alert'] as List? ?? const [])
            .map((e) => (e as Map).cast<String, dynamic>())
            .toList();

    // Reuse the same decision rules as fetchAlert()
    final String condText =
        (((current['condition'] ?? {}) as Map)['text'] ?? '')
            .toString()
            .toLowerCase();
    final bool isRainingNow =
        condText.contains('rain') || condText.contains('shower');
    final bool isThunderNow = condText.contains('thunder');

    WeatherLevel level;
    if (alerts.isNotEmpty) {
      level = WeatherLevel.red;
    } else if (isRainingNow || isThunderNow) {
      level = WeatherLevel.blue;
    } else {
      level = WeatherLevel.green;
    }

    final now = DateTime.now();
    final windowText = WeatherService.windowTextWithAdvisory(
      now,
      hasOfficialAlert: alerts.isNotEmpty,
    );

    if (level == WeatherLevel.red) {
      return WeatherAlert(
        level: WeatherLevel.red,
        headline: 'Severe Weather: $areaOverride',
        windowText: windowText,
        body:
            'Official advisories detected. Expect heavy rain and/or damaging wind gusts.',
        source: 'WeatherAPI',
        areaName: areaOverride,
      );
    }

    if (level == WeatherLevel.blue) {
      return WeatherAlert(
        level: WeatherLevel.blue,
        headline: 'Rain/Thunderstorms Possible: $areaOverride',
        windowText: windowText,
        body:
            'Isolated rainshowers or thunderstorms. Possible flash floods or landslides during severe thunderstorms.',
        source: 'WeatherAPI',
        areaName: areaOverride,
      );
    }

    return WeatherAlert(
      level: WeatherLevel.green,
      headline: 'Fair to Partly Cloudy: $areaOverride',
      windowText: windowText,
      body:
          'Fair to partly cloudy conditions. Keep normal pantry routines and watch near-expiry items.',
      source: 'WeatherAPI',
      areaName: areaOverride,
    );
  }

  /// Step 3: Fetch an advisory. For now:
  /// - Try a placeholder PAG-ASA adapter (TODO: wire to their official feed/API).
  /// - Fallback to a general forecast provider to infer green/blue.
  Future<WeatherAlert> fetchAlert(
      {required Position pos, required String areaName}) async {
    final uri = Uri.parse(
      'https://api.weatherapi.com/v1/forecast.json'
      '?key=$weatherApiKey'
      '&q=${pos.latitude},${pos.longitude}'
      '&days=3'
      '&aqi=no'
      '&alerts=yes',
    );

    final res = await http.get(uri).timeout(const Duration(seconds: 10));
    if (res.statusCode != 200) {
      throw Exception('WeatherAPI ${res.statusCode}: ${res.body}');
    }

    // ---- Parse JSON ----
    final Map<String, dynamic> data =
        json.decode(res.body) as Map<String, dynamic>;
    final Map<String, dynamic> current =
        (data['current'] ?? {}) as Map<String, dynamic>;
    final Map<String, dynamic> forecast =
        (data['forecast'] ?? {}) as Map<String, dynamic>;
    final List<Map<String, dynamic>> forecastDays =
        ((forecast['forecastday'] as List?) ?? const [])
            .map((e) => (e as Map).cast<String, dynamic>())
            .toList();

    final List<Map<String, dynamic>> alerts =
        (((data['alerts'] ?? {}) as Map)['alert'] as List? ?? const [])
            .map((e) => (e as Map).cast<String, dynamic>())
            .toList();

    final Map<String, dynamic> loc =
        (data['location'] ?? {}) as Map<String, dynamic>;
    final String city = (loc['name'] ?? '').toString();
    final String region = (loc['region'] ?? '').toString();
    final String country = (loc['country'] ?? '').toString();
    final String areaLabel =
        [city, region].where((s) => s.isNotEmpty).join(', ');
    final String finalArea = areaLabel.isNotEmpty
        ? areaLabel
        : (country.isNotEmpty ? country : 'Your Area');

    // ----- Improved decision using "current" conditions -----
    final String condText =
        (((current['condition'] ?? {}) as Map)['text'] ?? '')
            .toString()
            .toLowerCase();
    final double precipMmNow = ((current['precip_mm'] ?? 0) as num).toDouble();
    final int cloudNow = ((current['cloud'] ?? 0) as num).toInt();

    final bool isRainingNow = condText.contains('rain') ||
        condText.contains('shower') ||
        precipMmNow > 0.0;
    final bool isThunderNow = condText.contains('thunder');

    int maxChanceRain = 0;
    double maxGustKph = 0.0;
    bool thunderMentionNext = false;

    for (final day in forecastDays) {
      final List<Map<String, dynamic>> hours =
          ((day['hour'] as List?) ?? const [])
              .map((e) => (e as Map).cast<String, dynamic>())
              .toList();
      for (final h in hours) {
        final int chance = ((h['chance_of_rain'] ?? 0) as num).toInt();
        final double gust =
            ((h['gust_kph'] ?? h['wind_gust_kph'] ?? h['wind_kph'] ?? 0) as num)
                .toDouble();
        final String hText = (((h['condition'] ?? {}) as Map)['text'] ?? '')
            .toString()
            .toLowerCase();

        if (chance > maxChanceRain) maxChanceRain = chance;
        if (gust > maxGustKph) maxGustKph = gust;
        if (hText.contains('thunder')) thunderMentionNext = true;
      }
    }

    final bool hasOfficialAlert = alerts.isNotEmpty;
    final bool veryWindyNow =
        ((current['gust_kph'] ?? 0) as num).toDouble() >= 70.0;

    WeatherLevel level;
    if (hasOfficialAlert || veryWindyNow) {
      level = WeatherLevel.red;
    } else if (isRainingNow ||
        isThunderNow ||
        maxChanceRain >= 40 ||
        maxGustKph >= 45 ||
        thunderMentionNext) {
      level = WeatherLevel.blue;
    } else {
      level = WeatherLevel.green;
    }

    final now = DateTime.now();
    final windowText = WeatherService.windowTextWithAdvisory(now,
        hasOfficialAlert: hasOfficialAlert);

    // RED
    if (level == WeatherLevel.red) {
      String headline = 'Severe Weather: $finalArea';
      String body =
          'Advisory in effect. Expect heavy rain and/or damaging wind gusts.';
      if (hasOfficialAlert) {
        final a0 = alerts.first;
        final ev = (a0['event'] ?? 'Severe Weather').toString();
        final desc = (a0['desc'] ?? 'Adverse conditions expected.').toString();
        headline = '$ev: $finalArea';
        body = desc;
      }
      return WeatherAlert(
        level: WeatherLevel.red,
        headline: headline,
        windowText: windowText,
        body: body,
        source: 'WeatherAPI',
        areaName: finalArea,
      );
    }

    // BLUE
    if (level == WeatherLevel.blue) {
      final bool rainingOrThunder = isRainingNow || isThunderNow;
      final String body = rainingOrThunder
          ? 'Isolated rainshowers or thunderstorms in the area. Localized heavy downpours may occur. '
              'Possible flash floods or landslides during severe thunderstorms.'
          : 'Next 24–72 hours: Prepare for rain or gusty winds. Showers or thunderstorms possible.';
      return WeatherAlert(
        level: WeatherLevel.blue,
        headline: rainingOrThunder
            ? 'Showers/Thunderstorms: $finalArea'
            : 'Storm Watch: $finalArea',
        windowText: windowText,
        body: body,
        source: 'WeatherAPI',
        areaName: finalArea,
        stockUpList: const [
          'Drinking water',
          'Rice/grains',
          'Canned fish/beans/veggies',
          'UHT milk',
          'Ready-to-eat snacks',
          'Butane/charcoal',
          'Matches/lighter',
          'Charge power banks',
        ],
      );
    }

    // GREEN
    final bool partlyCloudy = condText.contains('cloud') || cloudNow >= 50;
    final String headline =
        partlyCloudy ? 'Partly Cloudy: $finalArea' : 'Fair Weather: $finalArea';
    return WeatherAlert(
      level: WeatherLevel.green,
      headline: headline,
      windowText: windowText,
      body:
          'Fair to partly cloudy conditions with low rain risk. Keep normal pantry routines and watch near-expiry items for meal planning. '
          'Store heat-sensitive goods away from sunlight and the stove.',
      source: 'WeatherAPI',
      areaName: finalArea,
    );
  }

  // --------- INTERNALS ----------

  Future<WeatherAlert?> _fetchPagasaStub({required String areaName}) async {
    // TODO: Replace with a real PAG-ASA data source.
    // Return null to indicate "no advisory" most of the time.
    // You can temporarily force a RED to test UI:
    // return WeatherAlert(
    //   level: WeatherLevel.red,
    //   headline: 'Severe Weather: $areaName',
    //   windowText: _window(now: DateTime.now(), hours: 12),
    //   body: 'Moderate General Flood Advisory in effect until Friday, 5:35 AM PHT',
    //   source: 'PAG-ASA',
    //   areaName: areaName,
    // );
    return null;
  }

  Future<WeatherAlert> _fallbackForecastToAlert(
      {required Position pos, required String areaName}) async {
    // Use any free forecast you prefer; here we do a simple GET to Open-Meteo (no key) as an example
    // to derive GREEN vs BLUE. If heavy rainfall or strong wind in next 48h -> BLUE, else GREEN.
    try {
      final url = Uri.parse(
        'https://api.open-meteo.com/v1/forecast'
        '?latitude=${pos.latitude}&longitude=${pos.longitude}'
        '&hourly=precipitation_probability,wind_gusts_10m'
        '&forecast_days=2&timezone=Asia%2FManila',
      );
      final res = await http.get(url).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final data = json.decode(res.body) as Map<String, dynamic>;
        final hourly = (data['hourly'] ?? {}) as Map<String, dynamic>;
        final probs =
            (hourly['precipitation_probability'] as List?)?.cast<num>() ??
                const [];
        final gusts =
            (hourly['wind_gusts_10m'] as List?)?.cast<num>() ?? const [];
        final maxProb =
            probs.isEmpty ? 0 : probs.reduce((a, b) => a > b ? a : b).toInt();
        final maxGust = gusts.isEmpty
            ? 0
            : gusts.reduce((a, b) => a > b ? a : b).toDouble();

        final now = DateTime.now();
        final window = _window(now: now, hours: 24);

        if (maxProb >= 60 || maxGust >= 45) {
          // BLUE – approaching storm (next 24–72h)
          return WeatherAlert(
            level: WeatherLevel.blue,
            headline: 'Storm Watch: $areaName',
            windowText: window,
            body:
                'Next 24–72 hours: Prepare for an incoming storm. Showers and gusty winds possible.',
            source: 'PAG-ASA', // keep the label; UI will say "Source: PAG-ASA"
            areaName: areaName,
            stockUpList: const [
              'Drinking water',
              'Rice/grains',
              'Canned fish/beans/veggies',
              'UHT milk',
              'Ready-to-eat snacks',
              'Butane/charcoal',
              'Matches/lighter',
              'Charge power banks'
            ],
          );
        } else {
          // GREEN – fair weather
          return WeatherAlert(
            level: WeatherLevel.green,
            headline: 'Sunny Weather: $areaName',
            windowText: window,
            body:
                'Fair Weather Advisory in effect: No urgent actions needed.\n\nClear skies with low rain risk. Keep normal pantry routines and watch near-expiry items for meal planning. Store heat-sensitive goods away from sunlight and the stove.\n\nQuick pantry reminders:\n• Reseal opened packs (flour, sugar, snacks) in airtight containers.\n• Keep oils, coffee, and spices in a cool, dark cabinet; tighten lids.\n• Rotate stock (FIFO) and label open dates.',
            source: 'PAG-ASA',
            areaName: areaName,
          );
        }
      }
    } catch (_) {
      // fall through
    }

    // If forecast failed, default GREEN.
    return WeatherAlert(
      level: WeatherLevel.green,
      headline: 'Sunny Weather: $areaName',
      windowText: _window(now: DateTime.now(), hours: 24),
      body:
          'Fair Weather Advisory in effect: No urgent actions needed.\n\nClear skies with low rain risk. Keep normal pantry routines and watch near-expiry items for meal planning. Store heat-sensitive goods away from sunlight and the stove.',
      source: 'PAG-ASA',
      areaName: areaName,
    );
  }

  Future<WeatherAlert> fetchNationalAlertPH() async {
    bool anyOfficialAlert = false;
    bool anyRainingNowOrThunder = false;
    int maxChanceRain = 0;
    double maxGustKph = 0.0;
    final List<String> advisoryPlaces = [];

    for (final city in _phSample) {
      final uri = Uri.parse(
        'https://api.weatherapi.com/v1/forecast.json'
        '?key=$weatherApiKey'
        '&q=${city.lat},${city.lon}'
        '&days=3'
        '&aqi=no'
        '&alerts=yes',
      );

      try {
        final res = await http.get(uri).timeout(const Duration(seconds: 10));
        if (res.statusCode != 200) continue;
        final data = json.decode(res.body) as Map<String, dynamic>;

        final current = (data['current'] ?? {}) as Map<String, dynamic>;
        final forecast = (data['forecast'] ?? {}) as Map<String, dynamic>;
        final List<Map<String, dynamic>> forecastDays =
            ((forecast['forecastday'] as List?) ?? const [])
                .map((e) => (e as Map).cast<String, dynamic>())
                .toList();
        final List<Map<String, dynamic>> alerts =
            (((data['alerts'] ?? {}) as Map)['alert'] as List? ?? const [])
                .map((e) => (e as Map).cast<String, dynamic>())
                .toList();

        if (alerts.isNotEmpty) {
          anyOfficialAlert = true;
          advisoryPlaces.add(city.name);
        }

        final String condText =
            (((current['condition'] ?? {}) as Map)['text'] ?? '')
                .toString()
                .toLowerCase();
        final double precipMmNow =
            ((current['precip_mm'] ?? 0) as num).toDouble();
        final bool isRainingNow = condText.contains('rain') ||
            condText.contains('shower') ||
            precipMmNow > 0.0;
        final bool isThunderNow = condText.contains('thunder');
        if (isRainingNow || isThunderNow) anyRainingNowOrThunder = true;

        for (final day in forecastDays) {
          final List<Map<String, dynamic>> hours =
              ((day['hour'] as List?) ?? const [])
                  .map((e) => (e as Map).cast<String, dynamic>())
                  .toList();
          for (final h in hours) {
            final int chance = ((h['chance_of_rain'] ?? 0) as num).toInt();
            final double gust = ((h['gust_kph'] ??
                    h['wind_gust_kph'] ??
                    h['wind_kph'] ??
                    0) as num)
                .toDouble();
            if (chance > maxChanceRain) maxChanceRain = chance;
            if (gust > maxGustKph) maxGustKph = gust;
          }
        }
      } catch (_) {
        // ignore single-city failure, continue
      }
    }

    WeatherLevel level;
    if (anyOfficialAlert) {
      level = WeatherLevel.red;
    } else if (anyRainingNowOrThunder ||
        maxChanceRain >= 40 ||
        maxGustKph >= 45) {
      level = WeatherLevel.blue;
    } else {
      level = WeatherLevel.green;
    }

    final now = DateTime.now();
    final windowText =
        _windowTextWithAdvisory(now, hasOfficialAlert: anyOfficialAlert);

    if (level == WeatherLevel.red) {
      final where = advisoryPlaces.isEmpty
          ? ''
          : ' (e.g., ${advisoryPlaces.take(3).join(', ')})';
      return WeatherAlert(
        level: WeatherLevel.red,
        headline: 'Severe Weather: Philippines (national outlook)',
        windowText: windowText,
        body:
            'Official advisories detected$where. Expect heavy rain and/or damaging wind gusts in affected regions.',
        source: 'WeatherAPI',
        areaName: 'Philippines',
      );
    }

    if (level == WeatherLevel.blue) {
      return WeatherAlert(
        level: WeatherLevel.blue,
        headline: 'Rain/Thunderstorms Possible: Philippines (national outlook)',
        windowText: windowText,
        body:
            'Isolated rainshowers or thunderstorms are possible in parts of the country. '
            'Localized heavy downpours may occur. Possible flash floods or landslides during severe thunderstorms.',
        source: 'WeatherAPI',
        areaName: 'Philippines',
        stockUpList: const [
          'Drinking water',
          'Rice/grains',
          'Canned goods',
          'UHT milk',
          'Ready-to-eat snacks',
          'Butane/charcoal',
          'Matches/lighter',
          'Charge power banks',
        ],
      );
    }

    return WeatherAlert(
      level: WeatherLevel.green,
      headline: 'Fair to Partly Cloudy: Philippines (national outlook)',
      windowText: windowText,
      body:
          'Fair to partly cloudy conditions in most areas. Keep normal pantry routines and watch near-expiry items for meal planning.',
      source: 'WeatherAPI',
      areaName: 'Philippines',
    );
  }

  String _window({required DateTime now, int hours = 24}) {
    final fmtDay = DateFormat('EEE, MMM d, h:mm a');
    final start = DateFormat('EEE, MMM d, h:mm a').format(now);
    final end = DateFormat('EEE, MMM d, h:mm a')
        .format(now.add(const Duration(hours: 24)));
    return '$start - $end';
  }
}
