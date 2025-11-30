import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shelf_control/services/weather_service.dart';
import 'package:shelf_control/services/tips_rules.dart';
import 'package:shelf_control/models/pantry_item_model.dart';
import 'package:shelf_control/services/firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:shelf_control/services/ai_tip_service.dart';

// --- Category normalization helpers ---
String _norm(String? s) => (s ?? '').trim().toLowerCase();

String _alias(String? s) {
  final x = _norm(s);
  if (x.isEmpty) return 'others';

  if (x.contains('bread') || x.contains('pastry') || x.contains('bake')) {
    return 'bakery';
  }

  if (x.contains('drink') ||
      x.contains('juice') ||
      x.contains('beverage') ||
      x.contains('coffee') ||
      x.contains('tea')) {
    return 'beverages';
  }

  if (x.contains('can') || x.contains('canned')) {
    return 'canned goods';
  }

  if (x.contains('condiment') ||
      x.contains('sauce') ||
      x.contains('seasoning') ||
      x.contains('spice')) {
    return 'condiments';
  }

  if (x.contains('milk') ||
      x.contains('cheese') ||
      x.contains('butter') ||
      x.contains('yogurt') ||
      x.contains('dairy')) {
    return 'dairy';
  }

  if (x.contains('dry') ||
      x.contains('pasta') ||
      x.contains('noodle') ||
      x.contains('rice') ||
      x.contains('grain')) {
    return 'dry goods';
  }

  if (x.contains('fruit') ||
      x.contains('vegetable') ||
      x.contains('produce') ||
      x.contains('fresh')) {
    return 'produce';
  }

  if (x.contains('snack') ||
      x.contains('chips') ||
      x.contains('biscuits') ||
      x.contains('candy')) {
    return 'snacks';
  }

  if (x.contains('general') || x.contains('misc')) {
    return 'general';
  }

  return 'others';
}

String _group(String? raw) {
  final cat = _alias(raw);

  switch (cat) {
    case 'general':
      return 'General';
    case 'bakery':
      return 'Bakery';
    case 'beverages':
      return 'Beverages';
    case 'canned goods':
      return 'Canned Goods';
    case 'condiments':
      return 'Condiments';
    case 'dairy':
      return 'Dairy';
    case 'dry goods':
      return 'Dry Goods';
    case 'produce':
      return 'Produce';
    case 'snacks':
      return 'Snacks';
    default:
      return 'Others';
  }
}

// --- NEW DATA MODEL ---
// A placeholder class to represent a full pantry item's data.
class PantryItem {
  final String name;
  final String category;
  final double quantity; // e.g., 2 pieces
  final double price; // e.g., ₱ 50.00
  final double netWeight; // e.g., 0.5 kg (using double for simplicity)
  final String weightUnit; // e.g., 'pcs', 'kg', 'L'
  final int daysUntilExpiration;
  // NOTE: In a real app, this would also have an 'imageUrl' or 'imagePath'

  PantryItem({
    required this.name,
    required this.category,
    this.quantity = 0,
    this.price = 0.0,
    this.netWeight = 0.0,
    this.weightUnit = 'pcs',
    this.daysUntilExpiration = 0,
  });
}
// -----------------------

// --- Color Helpers (Unchanged) ---

Color _levelColor(WeatherLevel lvl) {
  switch (lvl) {
    case WeatherLevel.red:
      return const Color(0xFFD32F2F); // red 700
    case WeatherLevel.green:
      return const Color(0xFF2E7D32); // green 800
    case WeatherLevel.blue:
      return const Color(0xFF1565C0); // blue 800
  }
}

Color _levelTint(WeatherLevel lvl) {
  switch (lvl) {
    case WeatherLevel.red:
      return const Color(0xFFFFEBEE); // red 50
    case WeatherLevel.green:
      return const Color(0xFFE8F5E9); // green 50
    case WeatherLevel.blue:
      return const Color(0xFFE3F2FD); // blue 50
  }
}

String _levelLabel(WeatherLevel lvl) {
  switch (lvl) {
    case WeatherLevel.red:
      return "RED";
    case WeatherLevel.green:
      return "GREEN";
    case WeatherLevel.blue:
      return "BLUE";
  }
}

// --- Weather Alert Banner (Unchanged) ---

class WeatherAlertBanner extends StatefulWidget {
  final WeatherAlert alert;
  final bool initiallyExpanded;
  const WeatherAlertBanner({
    super.key,
    required this.alert,
    this.initiallyExpanded = false,
  });

  @override
  State<WeatherAlertBanner> createState() => _WeatherAlertBannerState();
}

class _WeatherAlertBannerState extends State<WeatherAlertBanner> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    final lvl = widget.alert.level;
    final strip = _levelColor(lvl);
    final bg = _levelTint(lvl);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: strip.withOpacity(0.35), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // left colored strip
          Container(
            width: 6,
            decoration: BoxDecoration(
              color: strip,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
            ),
          ),

          // content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // top row
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: strip.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: strip.withOpacity(0.35)),
                        ),
                        child: Text(
                          _levelLabel(lvl),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: strip,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.alert.windowText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 12.5, fontWeight: FontWeight.w500),
                        ),
                      ),
                      InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () => setState(() => _expanded = !_expanded),
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: AnimatedRotation(
                            duration: const Duration(milliseconds: 180),
                            turns: _expanded ? 0.5 : 0.0,
                            child:
                                const Icon(Icons.keyboard_arrow_down, size: 22),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // headline
                  Text(
                    widget.alert.headline,
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                      color: _levelColor(lvl),
                    ),
                  ),
                  const SizedBox(height: 4),

                  // collapsed summary
                  if (!_expanded)
                    Text(
                      widget.alert.body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13.5, height: 1.25),
                    ),

                  // expanded details
                  AnimatedCrossFade(
                    firstChild: const SizedBox.shrink(),
                    secondChild: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.alert.body,
                          style: const TextStyle(fontSize: 13.5, height: 1.35),
                        ),
                        if (widget.alert.stockUpList.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          const Text(
                            "Suggested stock-up:",
                            style: TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 13.5),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: widget.alert.stockUpList
                                .map((e) => Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius:
                                            BorderRadius.circular(999),
                                        border: Border.all(
                                            color: strip.withOpacity(0.35)),
                                      ),
                                      child: Text(e,
                                          style:
                                              const TextStyle(fontSize: 12.5)),
                                    ))
                                .toList(),
                          ),
                        ],
                        const SizedBox(height: 8),
                      ],
                    ),
                    crossFadeState: _expanded
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                    duration: const Duration(milliseconds: 180),
                  ),

                  // source line
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.info_outline, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        "Source: ${widget.alert.source}",
                        style: const TextStyle(
                            fontSize: 12, color: Colors.black87),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- Tip Detail Page (UPDATED TO MATCH SCREENSHOT) ---

class TipDetailPage extends StatelessWidget {
  final String title;
  final String subtitle;
  final String details;

  const TipDetailPage({
    super.key,
    required this.title,
    required this.subtitle,
    required this.details,
  });

  /// This helper function parses a block of text into styled widgets.
  /// It assumes that a heading is a single line ending in a period or colon,
  /// followed by a body paragraph. Sections are separated by double newlines.
  List<Widget> _buildDetailWidgets() {
    final List<Widget> widgets = [];
    final tipSections = details.split('\n\n');

    for (var section in tipSections) {
      if (section.trim().isEmpty) continue;

      int separatorIndex = section.indexOf('. ');
      if (separatorIndex == -1) {
        separatorIndex = section.indexOf(': ');
      }

      String heading;
      String body;

      if (separatorIndex != -1 && !section.startsWith('•')) {
        heading = section.substring(0, separatorIndex + 1);
        body = section.substring(separatorIndex + 2);
      } else {
        heading = '';
        body = section;
      }

      if (heading.isNotEmpty) {
        widgets.add(
          Text(
            heading.trim(),
            style: const TextStyle(
              fontSize: 16.5,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              height: 1.5,
            ),
          ),
        );
        widgets.add(const SizedBox(height: 4));
      }

      widgets.add(
        Text(
          body.trim(),
          style: const TextStyle(
            fontSize: 16.5,
            color: Colors.black87,
            height: 1.5,
          ),
        ),
      );
      widgets.add(const SizedBox(height: 24));
    }
    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: const Color(0xFFFFFDF2), // Light cream background
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D32),
        elevation: 0,
        // The title in the app bar is optional as it's shown in the body
        title: Text(title,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Padding(
          // Add enough padding at the bottom to ensure content isn't hidden by the footer image
          padding: EdgeInsets.fromLTRB(
              24, 24, 24, 200 + MediaQuery.of(context).padding.bottom),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 17,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 32),
              // Use the helper to build the structured content
              ..._buildDetailWidgets(),
            ],
          ),
        ),
      ),
      // --- FOOTER IMPLEMENTATION FROM SCREENSHOT ---
      bottomNavigationBar: IgnorePointer(
        child: SizedBox(
          height: 180 + MediaQuery.of(context).padding.bottom,
          child: Image.asset(
            'assets/footer1e27d32-trans.png', // <-- REPLACE WITH YOUR IMAGE PATH
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}

// --- Item Tips Detail Page (WITH FOOTER) ---

class ItemTipsDetailPage extends StatefulWidget {
  final PantryItem item;
  final WeatherAlert? alert;

  const ItemTipsDetailPage({
    super.key,
    required this.item,
    this.alert,
  });

  @override
  State<ItemTipsDetailPage> createState() => _ItemTipsDetailPageState();
}

class _ItemTipsDetailPageState extends State<ItemTipsDetailPage> {
  Map<String, dynamic>? aiTips;
  bool aiLoading = true;

  IconData _getIconForItem(String itemName) {
    switch (itemName.toLowerCase()) {
      case 'apples':
        return Icons.apple;
      case 'lettuce':
        return Icons.eco;
      case 'chicken':
      case 'pork':
      case 'beef':
        return Icons.kebab_dining;
      case 'salmon':
      case 'tuna':
        return Icons.set_meal;
      case 'milk':
        return Icons.opacity;
      case 'cheese':
        return Icons.icecream_outlined;
      case 'rice':
        return Icons.rice_bowl;
      case 'bread':
        return Icons.breakfast_dining_outlined;
      default:
        return Icons.fastfood;
    }
  }

  // --- NEW: AI loader with safe fallback ---
  @override
  void initState() {
    super.initState();
    _loadAiTips(); // Fetch immediately on page load
  }

  Future<void> _loadAiTips() async {
    try {
      aiTips = await AiTipService().getItemTips(
        itemName: widget.item.name,
        category: widget.item.category,
        expDays: widget.item.daysUntilExpiration,
        weatherLevel: widget.alert?.level.toString() ?? "green",
      );
    } catch (e) {
      // Handle potential errors from AiTipService (e.g., API key missing, network issues, malformed JSON)
      print("Error loading AI tips: $e");
      aiTips = {}; // Ensure aiTips is not null, so fallback logic can be used
    } finally {
      if (!mounted) return;
      setState(() {
        aiLoading = false;
      });
    }
  }

  String _getAiTipOrFallback(String title) {
    // Always attempt to get AI tips if available, otherwise use fallback immediately.
    // The UI will rebuild when aiTips become available.
    if (aiTips == null) return _getTipDetails(title, widget.item);

    final t = title.toLowerCase().trim();

    // WEATHER — match ANY weather-related phrasing
    if (t.contains("weather") || t.contains("climate") || t.contains("heat")) {
      return aiTips!["weather"]?["details"] ??
          _getTipDetails("Current Suggestion (Weather)", widget.item);
    }

    // PRESERVATION — match ANY storage/safety/freshness keyword
    if (t.contains("preserv") ||
        t.contains("fresh") ||
        t.contains("safety") ||
        t.contains("store") ||
        t.contains("storage") ||
        t.contains("shelf life") ||
        t.contains("long-lasting") ||
        t.contains("freshness")) {
      return aiTips!["preservation"]?["details"] ??
          _getTipDetails("Food Preservation Tips", widget.item);
    }

    // WASTE — match ANY waste/reuse/repurpose keyword
    if (t.contains("waste") || t.contains("reuse") || t.contains("use up")) {
      return aiTips!["waste"]?["details"] ??
          _getTipDetails("Waste Reduction Tips", widget.item);
    }

    // LABELING — match any labeling/meaning keywords
    if (t.contains("label") ||
        t.contains("definition") ||
        t.contains("meaning")) {
      return aiTips!["labeling"]?["details"] ??
          _getTipDetails("Food Labeling & Definitions", widget.item);
    }

    // DEFAULT — force preservation instead of blank
    return aiTips!["preservation"]?["details"] ??
        _getTipDetails("Food Preservation Tips", widget.item);
  }

  // Fallback detailed content if AI fails or for offline use
  String _getTipDetails(String tipType, PantryItem item) {
    switch (tipType) {
      case 'Food Preservation Tips':
        // Example for dairy/milk to match your sample
        if (item.category.toLowerCase() == 'dairy') {
          return '''
Avoid the door. The refrigerator door is the warmest part of the fridge. It's best to store milk and other dairy products on the main shelves where the temperature is more consistent.

Keep it cold. Dairy products should be stored in the refrigerator at or below 40°F (4°C). This helps to slow down the growth of bacteria and keep your dairy fresh for longer.

Keep it in the original container. This helps to protect it from light, which can degrade some vitamins, and from absorbing odors from other foods.

Use within a week. Once opened, milk is typically good for about seven days.

Rotate your dairy. When you buy new dairy products, place them behind the older ones in your fridge. This will help you to use up the older products before they expire. This is known as the FIFO (First-In, First-Out) method and it's a great way to reduce food waste.
''';
        }
        // Fallback for other items
        return 'Food preservation tips specific to ${item.name}, like optimal temperature, humidity, and location for storage.';

      case 'Waste Reduction Tips':
        return 'Waste reduction ideas for ${item.name}, such as recipes, repurposing leftovers, or using slightly stale items in new dishes.';
      case 'Food Labeling & Definitions':
        return 'Definitions of common labels like "Best Before" and "Use By" as they apply to products like ${item.name}.';
      default:
        return 'No details available for this topic.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final weatherLevel = widget.alert?.level ?? WeatherLevel.green;

    // Existing rule-based weather advice (for hybrid fallback)
    final allDynamicTips =
        TipsRules.adviceFor(item.category, item.name, weatherLevel);
    final currentSuggestion =
        allDynamicTips.isNotEmpty ? allDynamicTips.first : null;

    String getExpirationText(int days) {
      if (days < 0) return 'Expired ${days.abs()} days ago';
      if (days == 0) return 'Expires today!';
      if (days == 1) return 'Expires in 1 day';
      return 'Expires in $days days';
    }

    Color getExpirationColor(int days) {
      if (days <= 0) return const Color(0xFFD32F2F); // Red
      if (days <= 3) return const Color(0xFFF9A825); // Amber
      return const Color(0xFF2E7D32); // Green
    }

    final expirationDays = item.daysUntilExpiration;
    final expColor = getExpirationColor(expirationDays);

    // --- HYBRID AI + RULES: compute titles/subtitles/details for each card ---

    Map<String, dynamic>? _section(String key) {
      final raw = aiTips;
      if (raw == null) return null;
      final value = raw[key];
      if (value is Map<String, dynamic>) return value;
      return null;
    }

    String _orDefault(Map<String, dynamic>? m, String field, String fallback) {
      if (m == null) return fallback;
      final v = m[field];
      if (v is String && v.trim().isNotEmpty) return v.trim();
      return fallback;
    }

    // Weather suggestion
    final weatherMap = _section('weather');
    final weatherTitle = _orDefault(
      weatherMap,
      'title',
      'Current Suggestion (Weather)',
    );
    final weatherSubtitle = _orDefault(
      weatherMap,
      'subtitle',
      currentSuggestion?.subtitle ??
          'Weather-based tips for optimal food storage.',
    );
    final weatherDetails = _orDefault(
      weatherMap,
      'details',
      currentSuggestion?.details ??
          'No specific weather tip for this item right now.',
    );

    // Preservation
    final preservationMap = _section('preservation');
    final preservationTitle = _orDefault(
      preservationMap,
      'title',
      'Food Preservation Tips',
    );
    final preservationSubtitle = _orDefault(
      preservationMap,
      'subtitle',
      'How to extend freshness & store items properly?',
    );
    final preservationDetails = _orDefault(
      preservationMap,
      'details',
      _getTipDetails('Food Preservation Tips', item),
    );

    // Waste reduction
    final wasteMap = _section('waste');
    final wasteTitle = _orDefault(
      wasteMap,
      'title',
      'Waste Reduction Tips',
    );
    final wasteSubtitle = _orDefault(
      wasteMap,
      'subtitle',
      'Discover recipes & ideas to use up your food',
    );
    final wasteDetails = _orDefault(
      wasteMap,
      'details',
      _getTipDetails('Waste Reduction Tips', item),
    );

    // Labeling / definitions
    final labelingMap = _section('labeling');
    final labelingTitle = _orDefault(
      labelingMap,
      'title',
      'Food Labeling & Definitions',
    );
    final labelingSubtitle = _orDefault(
      labelingMap,
      'subtitle',
      'Understand common food terms & what they mean.',
    );
    final labelingDetails = _orDefault(
      labelingMap,
      'details',
      _getTipDetails('Food Labeling & Definitions', item),
    );

    return Scaffold(
      extendBody: true,
      backgroundColor: const Color(0xFF2E7D32),
      body: Column(
        children: [
          // 🔴 Existing header – untouched
          Padding(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 10,
              bottom: 10,
              left: 10,
              right: 16,
            ),
            child: Row(
              children: [
                InkWell(
                  onTap: () => Navigator.pop(context),
                  child: const Padding(
                    padding: EdgeInsets.all(8.0),
                    child:
                        Icon(Icons.arrow_back, color: Colors.white, size: 24),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Smart Tips and Suggestions',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFFFFBE6),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(0),
                  topRight: Radius.circular(0),
                ),
              ),
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  bottom: 180 + MediaQuery.of(context).padding.bottom,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 🔴 Existing item header + stats – untouched
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                      color: Colors.grey.shade300, width: 1),
                                ),
                                child: Icon(
                                  _getIconForItem(item.name),
                                  size: 40,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.name,
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: expColor.withOpacity(0.1),
                                        borderRadius:
                                            BorderRadius.circular(999),
                                        border: Border.all(
                                            color: expColor.withOpacity(0.3)),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.schedule,
                                              size: 16, color: expColor),
                                          const SizedBox(width: 6),
                                          Text(
                                            getExpirationText(expirationDays),
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: expColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color(0xFFC8E6C9),
                                width: 1.0,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Column(
                                  children: [
                                    const Text('Quantity',
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.black54)),
                                    Text(item.quantity.toStringAsFixed(0),
                                        style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF222222))),
                                  ],
                                ),
                                Column(
                                  children: [
                                    const Text('Item Price',
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.black54)),
                                    Text('₱ ${item.price.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF222222))),
                                  ],
                                ),
                                Column(
                                  children: [
                                    const Text('Net weight',
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.black54)),
                                    Text(
                                        '${item.netWeight.toStringAsFixed(1)} ${item.weightUnit}',
                                        style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF222222))),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Padding(
                      padding: EdgeInsets.fromLTRB(20, 0, 20, 10),
                      child: Text(
                        'Smart Suggestions',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),

                    // Smart Suggestions List – same layout, dynamic content
                    _buildSuggestionCard(
                      context,
                      item: item,
                      title: weatherTitle,
                      subtitle: weatherSubtitle,
                      details: weatherDetails,
                      icon: Icons.light_mode,
                    ),
                    _buildSuggestionCard(
                      context,
                      item: item,
                      title: preservationTitle,
                      subtitle: preservationSubtitle,
                      details: preservationDetails,
                      icon: Icons.recycling,
                    ),
                    _buildSuggestionCard(
                      context,
                      item: item,
                      title: wasteTitle,
                      subtitle: wasteSubtitle,
                      details: wasteDetails,
                      icon: Icons.eco,
                    ),
                    _buildSuggestionCard(
                      context,
                      item: item,
                      title: labelingTitle,
                      subtitle: labelingSubtitle,
                      details: labelingDetails,
                      icon: Icons.label,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: IgnorePointer(
        child: SizedBox(
          height: 180 + MediaQuery.of(context).padding.bottom,
          child: Image.asset(
            'assets/footer1e27d32-trans.png',
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestionCard(
    BuildContext context, {
    required PantryItem item,
    required String title,
    required String subtitle,
    String? details, // AI or fallback
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => TipDetailPage(
                  title: title,
                  subtitle: subtitle,
                  // If AI gave us details, use it; otherwise use rule-based fallback
                  details: _getAiTipOrFallback(title),
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Icon(icon, size: 28, color: const Color(0xFF2E7D32)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios,
                    size: 16, color: Colors.grey),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ------------------------------------
// --- TipsPage Class (Unchanged) ---
// ------------------------------------

class TipsPage extends StatefulWidget {
  /// Optional: preselect a category (e.g., "Dairy") and open a specific item
  /// directly into its tips detail. `focusSection` can be "storage" to
  /// emphasize storage guidance, but it's optional.
  final String? deepLinkCategory;
  final String? deepLinkItemName;
  final String? focusSection; // e.g., "storage"

  const TipsPage({
    super.key,
    this.deepLinkCategory,
    this.deepLinkItemName,
    this.focusSection,
  });

  @override
  State<TipsPage> createState() => _TipsPageState();
}

class _TipsPageState extends State<TipsPage> {
  // --- DATA (Unchanged) ---
  WeatherAlert? _alert;
  bool _loadingWeather = true;
  String? _error;
  late final String _ownerId;
  String? _hhId; // runtime-selected household id
  bool _initializingHousehold = true;
  bool _bootstrapping = true;
  Stream<List<PantryItemModel>>? _pantryItemsStream; // Stream for pantry items
  String? _currentHouseholdId;
  VoidCallback? _hhListener;
  Future<WeatherAlert?>? _weatherFuture;
  bool _handledDeepLink = false;

  @override
  void initState() {
    super.initState();
    _bootstrap(); // resolve auth + household, then load weather
  }

  int _computeDaysUntil(DateTime? dt) {
    if (dt == null) return 9999;
    final now = DateTime.now();
    // compare against start of today to avoid off-by-hours
    final today = DateTime(now.year, now.month, now.day);
    return dt.difference(today).inDays;
  }

  Future<void> _bootstrap() async {
    // Ensure we are authenticated (anon is fine in dev)
    final auth = FirebaseAuth.instance;
    if (auth.currentUser == null) {
      await auth.signInAnonymously();
    }

    // Try FirestoreService’s stored household first
    final svc = Provider.of<FirestoreService>(context, listen: false);
    String? hhId = svc.selectedHouseholdId;

    // If none stored, pick the first household where this user is a member
    if (hhId == null || hhId.isEmpty) {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final snap = await FirebaseFirestore.instance
          .collection('households')
          .where('members', arrayContains: uid)
          .limit(1)
          .get();

      if (snap.docs.isNotEmpty) {
        hhId = snap.docs.first.id;

        // If your service has a setter, persist it (ignore if it doesn’t)
        try {
          svc.selectedHouseholdId = hhId;
        } catch (_) {}
      }
    }

    setState(() {
      _hhId = hhId; // may still be null if user is in no household
      _bootstrapping = false;
    });

    // Set up the pantry items stream
    _setupPantryItemsStream();

    // Load your weather banner (your existing logic)
    await _loadWeather();
  }

  void _setupPantryItemsStream() {
    if (_hhId != null) {
      _pantryItemsStream = FirebaseFirestore.instance
          .collection('pantryItems')
          .where('householdId', isEqualTo: _hhId)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => PantryItemModel.fromFirestore(doc))
              .toList());
    } else {
      _pantryItemsStream = Stream.value([]); // Empty stream if no household
    }
  }

  Future<void> _ensureAuth() async {
    final auth = FirebaseAuth.instance;
    if (auth.currentUser == null) {
      await auth.signInAnonymously();
    }
  }

  Future<void> _loadWeather() async {
    try {
      final pos = await WeatherService.instance.getPosition();
      if (!WeatherService.isInPhilippines(pos.latitude, pos.longitude)) {
        final alert = await WeatherService.instance.fetchAlertForDefaultPH();
        if (!mounted) return;
        setState(() {
          _alert = alert;
          _error = null;
          _loadingWeather = false;
        });
        return;
      }
      final alert =
          await WeatherService.instance.fetchAlert(pos: pos, areaName: '');
      if (!mounted) return;
      setState(() {
        _alert = alert;
        _error = null;
        _loadingWeather = false;
      });
    } catch (e) {
      try {
        final alert = await WeatherService.instance.fetchAlertForDefaultPH();
        if (!mounted) return;
        setState(() {
          _alert = alert;
          _error = null;
        });
      } catch (e2) {
        if (!mounted) return;
        setState(() {
          _error = 'Unable to load weather: $e2';
        });
      }
    } finally {
      if (mounted) _loadingWeather = false;
    }
  }

  final List<Map<String, dynamic>> categories = [
    {'name': 'General', 'icon': Icons.lightbulb},
    {'name': 'Bakery', 'icon': Icons.bakery_dining},
    {'name': 'Beverages', 'icon': Icons.local_cafe},
    {'name': 'Canned Goods', 'icon': Icons.inventory},
    {'name': 'Condiments', 'icon': Icons.soup_kitchen},
    {'name': 'Dairy', 'icon': Icons.local_drink},
    {'name': 'Dry Goods', 'icon': Icons.shopping_bag},
    {'name': 'Produce', 'icon': Icons.local_florist},
    {'name': 'Snacks', 'icon': Icons.fastfood},
    {'name': 'Others', 'icon': Icons.category},
  ];

  String selectedCategory = 'General';

  final Map<String, Map<String, List<Map<String, dynamic>>>> allTips = {};

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Text(
            'Tips & Suggestions',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E7D32),
            ),
          ),
        ),
        if (_loadingWeather)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: LinearProgressIndicator(minHeight: 3),
          )
        else if (_error != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Text(
              'Unable to load weather: $_error',
              style: const TextStyle(color: Colors.red),
            ),
          )
        else if (_alert != null)
          WeatherAlertBanner(alert: _alert!, initiallyExpanded: false),
        SizedBox(
          height: 90,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              final isSelected =
                  selectedCategory == (category['name'] as String? ?? '');
              return _buildCategoryChip(
                context,
                text: category['name'] as String? ?? 'Error',
                icon: category['icon'] as IconData? ?? Icons.error_outline,
                isSelected: isSelected,
                onTap: () {
                  setState(() {
                    selectedCategory = category['name'] as String? ?? 'General';
                  });
                },
              );
            },
          ),
        ),
        // Rebuild this page when FirestoreService notifies (household switch)
        Expanded(
          child: Builder(
            builder: (context) {
              final fs = context.watch<FirestoreService>();
              return _buildBodyContent(hhId: fs.selectedHouseholdId);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBodyContent({String? hhId}) {
    // 1) General tab stays as-is
    if (selectedCategory == 'General') {
      final generalTips = allTips['General']?['General'] ?? [];
      if (generalTips.isEmpty) {
        return _buildItemNavigationList([
          _buildTipCard(
            context,
            title: 'Know your food labels',
            subtitle: 'Read labels the right way: "Best Before" vs "Use By".',
            details:
                'Food labels provide important info like expiry dates, storage instructions, and nutritional values. "Best Before" = quality; "Use By" = safety.',
            icon: Icons.label_important_outline,
          ),
          _buildTipCard(
            context,
            title: 'How to store items properly',
            subtitle:
                'Keep your food fresh for longer! Find out where to store each item.',
            details:
                'Proper storage prevents spoilage. Keep potatoes in a cool dark place, bread in a breadbox, leafy greens in the fridge with a damp paper towel.',
            icon: Icons.inventory_2_outlined,
          ),
          _buildTipCard(
            context,
            title: 'Reduce food waste',
            subtitle:
                'Small changes make a big difference. Try these simple tips to waste less.',
            details:
                'Plan meals, store food properly, and use leftovers creatively. Donate excess food where possible.',
            icon: Icons.recycling_outlined,
          ),
        ]);
      }
      return _buildItemNavigationList(
        generalTips
            .map((tip) => _buildTipCard(
                  context,
                  title: tip['title'] as String,
                  subtitle: tip['subtitle'] as String,
                  details: tip['details'] as String,
                  icon: tip['icon'] as IconData,
                ))
            .toList(),
      );
    }

    // 2) Dynamic list from Firestore for all other categories
    if (_bootstrapping) {
      return const SizedBox(
        height: 80,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    // NOTE: prioritize the hhId passed from the ValueListenableBuilder
    final fs = context.read<FirestoreService>();
    final String? effectiveHhId = hhId ?? fs.selectedHouseholdId ?? _hhId;

    if (effectiveHhId == null || effectiveHhId.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            'Select or create a household to view pantry items.',
            style: const TextStyle(color: Colors.black54),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return StreamBuilder<List<PantryItemModel>>(
      stream: context
          .read<FirestoreService>()
          .getPantryItemsForHousehold(effectiveHhId!),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Text('Error loading pantry: ${snapshot.error}',
                style: const TextStyle(color: Colors.red)),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting ||
            !snapshot.hasData) {
          return const SizedBox(
            height: 80,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final pantryItemModels = snapshot.data!;

        // Convert PantryItemModel to PantryItem
        final parsedPantryItems = pantryItemModels.map((pantryItemModel) {
          final daysUntil = pantryItemModel.expirationDate == null
              ? 0
              : pantryItemModel.expirationDate!
                  .difference(DateTime.now())
                  .inDays;

          return PantryItem(
            name: pantryItemModel.name,
            category: pantryItemModel.category ?? 'Uncategorized',
            quantity: pantryItemModel.qty.toDouble(),
            price: pantryItemModel.price?.toDouble() ?? 0.0,
            netWeight:
                double.tryParse(pantryItemModel.netWeight ?? '0.0') ?? 0.0,
            weightUnit: pantryItemModel.quantityUnit ?? 'pcs',
            daysUntilExpiration: daysUntil,
          );
        }).toList();

        // Filter by the selected chip using normalized/aliased category names
        final byChip = parsedPantryItems
            .where((p) => _alias(p.category) == _alias(selectedCategory))
            .toList();

// IMPORTANT: no fallback to "all items" here
        final listToShow = byChip;

        if (listToShow.isEmpty) return _buildEmptyState();

        // --- Deep link handling: open the item's tips detail once, if requested ---
        if (!_handledDeepLink &&
            (widget.deepLinkItemName != null &&
                widget.deepLinkItemName!.trim().isNotEmpty)) {
          // Normalize helper (reuse yours if already present)
          String _norm(String? s) => (s ?? '').trim().toLowerCase();

          // If a category was provided, preselect it so the item is visible in this tab
          if (widget.deepLinkCategory != null &&
              widget.deepLinkCategory!.isNotEmpty) {
            setState(() {
              selectedCategory = widget.deepLinkCategory!;
            });
          }

          // Try to find the item (use the entire pantry set, not only listToShow,
          // to be robust even if categories were just switched)
          final allItems = snapshot.data ?? const <PantryItemModel>[];
          final match = allItems.firstWhere(
            (p) => _norm(p.name) == _norm(widget.deepLinkItemName),
            orElse: () =>
                allItems.isNotEmpty ? allItems.first : null as PantryItemModel,
          );

          if (match != null) {
            _handledDeepLink = true; // prevent repeated pushes
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (ctx) => ItemTipsDetailPage(
                    item: PantryItem(
                      name: match.name,
                      category: match.category ?? 'Uncategorized',
                      quantity: (match.qty ?? 0).toDouble(),
                      price: (match.price ?? 0).toDouble(),
                      netWeight: double.tryParse(match.netWeight ?? '0') ?? 0,
                      weightUnit: match.quantityUnit ?? 'pcs',
                      daysUntilExpiration:
                          _computeDaysUntil(match.expirationDate),
                    ),
                  ),
                ),
              );
            });
          }
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
          itemCount: listToShow.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, i) {
            final it = listToShow[i];
            return _buildItemNavigationCard(
              context,
              itemName: it.name,
              icon: _getIconForItem(it.name),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ItemTipsDetailPage(
                      item: it,
                      alert: _alert,
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildItemNavigationList(List<Widget> children) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      itemCount: children.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) => children[index],
    );
  }

  Widget _buildItemNavigationCard(
    BuildContext context, {
    required String itemName,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.grey.shade300, width: 1),
        borderRadius: BorderRadius.circular(15),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(icon, color: const Color(0xFF2E7D32), size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  itemName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 60, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No Items in Pantry',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add items to your pantry in the "$selectedCategory" category to see relevant tips here.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(
    BuildContext context, {
    required String text,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final Color backgroundColor =
        isSelected ? const Color(0xFFE8E5E1) : const Color(0xFFF8F5F1);
    final Color contentColor = isSelected ? Colors.black87 : Colors.black54;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Card(
        elevation: 3,
        shadowColor: Colors.black.withOpacity(0.2),
        color: backgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(15),
          child: Container(
            width: 80,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: contentColor, size: 28),
                const SizedBox(height: 4),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      text,
                      maxLines: 2,
                      softWrap: false,
                      overflow: TextOverflow.visible,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTipCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String details,
    required IconData icon,
  }) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.2),
      color: const Color(0xFFD4E4D5),
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: Color(0xFFADC2AD), width: 1.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TipDetailPage(
                title: title,
                subtitle: subtitle,
                details: details,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(icon, size: 36, color: Colors.black87),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIconForItem(String itemName) {
    switch (itemName.toLowerCase()) {
      case 'apples':
        return Icons.apple;
      case 'lettuce':
        return Icons.eco;
      case 'chicken':
        return Icons.kebab_dining;
      case 'pork':
        return Icons.kebab_dining;
      case 'beef':
        return Icons.kebab_dining;
      case 'salmon':
        return Icons.set_meal;
      case 'tuna':
        return Icons.set_meal;
      case 'milk':
        return Icons.opacity;
      case 'cheese':
        return Icons.icecream_outlined;
      case 'rice':
        return Icons.rice_bowl;
      case 'bread':
        return Icons.breakfast_dining_outlined;
      default:
        return Icons.fastfood;
    }
  }
}
