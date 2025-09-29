import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shelf_control/secrets.dart';

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
  static final instance = WeatherService._();

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

  /// Step 3: Fetch an advisory. For now:
  /// - Try a placeholder PAG-ASA adapter (TODO: wire to their official feed/API).
  /// - Fallback to a general forecast provider to infer green/blue.
  Future<WeatherAlert> fetchAlert(
      {required Position pos, required String areaName}) async {

        
        
    // We’ll ignore the passed-in areaName and use WeatherAPI’s location label for accuracy.
    final uri = Uri.parse(
      'https://api.weatherapi.com/v1/forecast.json'
      '?key=$weatherApiKey'
      '&q=${pos.latitude},${pos.longitude}'
      '&days=3'
      '&aqi=no'
      '&alerts=yes',

      
    );

    

    try {
      final res = await http.get(uri).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) {
        throw Exception('WeatherAPI ${res.statusCode}: ${res.body}');
      }

      final data = json.decode(res.body) as Map<String, dynamic>;
      final loc = (data['location'] ?? {}) as Map<String, dynamic>;
      final current = (data['current'] ?? {}) as Map<String, dynamic>;
      final forecast = (data['forecast'] ?? {}) as Map<String, dynamic>;
      final forecastDays =
          (forecast['forecastday'] as List? ?? const []).cast<Map>();
      final alerts =
          ((data['alerts'] ?? {})['alert'] as List? ?? const []).cast<Map>();

      final city = (loc['name'] ?? '') as String;
      final region = (loc['region'] ?? '') as String;
      final country = (loc['country'] ?? '') as String;
      final area =
          [city, region].where((s) => (s as String).isNotEmpty).join(', ');
      final areaLabel =
          area.isNotEmpty ? area : (country.isNotEmpty ? country : 'Your Area');

      // Collect next-72h precip chances and wind gusts
      int maxPrecip = 0;
      double maxGustKph = 0.0;

      for (final day in forecastDays) {
        final hours = (day['hour'] as List? ?? const []).cast<Map>();
        for (final h in hours) {
          final p = (h['chance_of_rain'] ?? h['precipitation_probability'] ?? 0)
              as num;
          final g = (h['gust_kph'] ?? h['wind_gust_kph'] ?? h['wind_kph'] ?? 0)
              as num;
          if (p.toInt() > maxPrecip) maxPrecip = p.toInt();
          if (g.toDouble() > maxGustKph) maxGustKph = g.toDouble();
        }
      }

      // Decide RED / BLUE / GREEN
      // RED if WeatherAPI issues alerts OR very severe conditions now
      final hasOfficialAlert = alerts.isNotEmpty;
      final veryWindyNow =
          ((current['gust_kph'] ?? 0) as num).toDouble() >= 70.0;

      WeatherLevel level;
      if (hasOfficialAlert || veryWindyNow) {
        level = WeatherLevel.red;
      } else if (maxPrecip >= 60 || maxGustKph >= 45) {
        level = WeatherLevel.blue; // storm approaching (next 24–72h)
      } else {
        level = WeatherLevel.green;
      }

      // Build window text (next 24h)
      final now = DateTime.now();
      final start = DateFormat('EEE, MMM d, h:mm a', 'en_PH').format(now);
      final end = DateFormat('EEE, MMM d, h:mm a', 'en_PH')
          .format(now.add(const Duration(hours: 24)));
      final windowText = '$start - $end';

      // Headline + body per level
      if (level == WeatherLevel.red) {
        // If WeatherAPI gave an alert, use its headline/desc. Otherwise, generic severe.
        String body;
        String headline = 'Severe Weather: $areaLabel';
        if (hasOfficialAlert) {
          final a0 = alerts.first;
          final ev = (a0['event'] ?? 'Severe Weather') as String;
          final desc = (a0['desc'] ?? 'Adverse conditions expected.') as String;
          headline = '$ev: $areaLabel';
          body = desc;
        } else {
          body =
              'Severe weather conditions in effect. Expect heavy rain and/or damaging wind gusts.';
        }

        return WeatherAlert(
          level: WeatherLevel.red,
          headline: headline,
          windowText: windowText,
          body: body,
          source: 'WeatherAPI',
          areaName: areaLabel,
        );
      }

      if (level == WeatherLevel.blue) {
        return WeatherAlert(
          level: WeatherLevel.blue,
          headline: 'Storm Watch: $areaLabel',
          windowText: windowText,
          body:
              'Next 24–72 hours: Prepare for an incoming storm. Showers and gusty winds possible.',
          source: 'WeatherAPI',
          areaName: areaLabel,
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
      }

      // GREEN
      return WeatherAlert(
        level: WeatherLevel.green,
        headline: 'Sunny Weather: $areaLabel',
        windowText: windowText,
        body: 'Fair Weather Advisory in effect: No urgent actions needed.\n\n'
            'Clear skies with low rain risk. Keep normal pantry routines and watch near-expiry items for meal planning. '
            'Store heat-sensitive goods away from sunlight and the stove.\n\n'
            'Quick pantry reminders:\n'
            '• Reseal opened packs (flour, sugar, snacks) in airtight containers.\n'
            '• Keep oils, coffee, and spices in a cool, dark cabinet; tighten lids.\n'
            '• Rotate stock (FIFO) and label open dates.',
        source: 'WeatherAPI',
        areaName: areaLabel,

        
      );
      

      
      
    } catch (e) {
      // Final fallback
      return WeatherAlert(
        level: WeatherLevel.green,
        headline: 'Sunny Weather: Your Area',
        windowText: 'Today • No active advisories',
        body: 'Fair Weather Advisory in effect: No urgent actions needed.\n\n'
            'Clear skies with low rain risk. Keep normal pantry routines and watch near-expiry items for meal planning. '
            'Store heat-sensitive goods away from sunlight and the stove.',
        source: 'WeatherAPI',
        areaName: 'Your Area',
      );
    }
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

  String _window({required DateTime now, int hours = 24}) {
    final fmtDay = DateFormat('EEE, MMM d, h:mm a', 'en_PH');
    final start = fmtDay.format(now);
    final end = fmtDay.format(now.add(Duration(hours: hours)));
    return '$start - $end';
  }
}
