import 'package:flutter/material.dart';
import 'package:shelf_control/services/weather_service.dart';
import 'package:shelf_control/services/tips_rules.dart';

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
        // ❌ don't stretch vertically; parent Column doesn't give a fixed height
        // crossAxisAlignment: CrossAxisAlignment.stretch,  // <-- remove this
        crossAxisAlignment: CrossAxisAlignment.start, // <-- use start/center
        mainAxisSize: MainAxisSize.min, // <-- let content size height
        children: [
          // left colored strip; let it size naturally with content
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
                mainAxisSize:
                    MainAxisSize.min, // <-- don't claim infinite height
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
                      mainAxisSize: MainAxisSize.min, // <-- important
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

// Your original TipDetailPage, unchanged.
class TipDetailPage extends StatelessWidget {
  final String title;
  final String details;

  const TipDetailPage({super.key, required this.title, required this.details});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBE6),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D32),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(
            details,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black87,
              height: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}

// Your TipsPage class with the updated item-specific logic.
class TipsPage extends StatefulWidget {
  const TipsPage({super.key});

  @override
  State<TipsPage> createState() => _TipsPageState();
}

class _TipsPageState extends State<TipsPage> {
  // --- DATA ---
  WeatherAlert? _alert;
  bool _loadingWeather = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadWeather();
  }

// TEMP: local loader that sets a GREEN alert so page compiles even
// if you haven’t created WeatherService yet.
// When you’re ready to go live, replace this with the version that
// calls WeatherService (I’ll show that below).
  Future<void> _loadWeather() async {
  try {
    final pos = await WeatherService.instance.getPosition(); // may return emulator defaults

    // 🧭 If GPS is outside PH (e.g., Mountain View), force Metro Manila fallback
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

    // Otherwise, use the precise local coordinates
    final alert = await WeatherService.instance.fetchAlert(pos: pos, areaName: '');
    if (!mounted) return;
    setState(() {
      _alert = alert;
      _error = null;
      _loadingWeather = false;
    });
  } catch (e) {
    // Location denied/off or other failure -> Metro Manila fallback
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

  // UPDATED: Added 'Salmon' and 'Tuna' to the 'Fish' category in the pantry.
  final Map<String, List<String>> pantryItems = {
    'Meat': ['Chicken', 'Pork', 'Beef'],
    'Fish': ['Salmon', 'Tuna'],
    'Dairy': ['Milk', 'Cheese'],
    'Produce': ['Apples', 'Lettuce'],
    'Grains': ['Rice', 'Bread'],
  };

  final List<Map<String, dynamic>> categories = [
    {'name': 'General', 'icon': Icons.lightbulb},
    {'name': 'Beverages', 'icon': Icons.local_cafe},
    {'name': 'Canned goods', 'icon': Icons.inventory},
    {'name': 'Dairy', 'icon': Icons.local_drink},
    {'name': 'Dry goods', 'icon': Icons.shopping_bag},
    {'name': 'Snacks', 'icon': Icons.fastfood},
    {'name': 'Condiments', 'icon': Icons.soup_kitchen},
    {'name': 'Produce', 'icon': Icons.local_florist},
    {'name': 'Uncategorized', 'icon': Icons.help_outline},
    {'name': 'Others', 'icon': Icons.category},
  ];

  String selectedCategory = 'General';

  final Map<String, Map<String, List<Map<String, dynamic>>>> allTips = {
    // 'General': {
    //   'General': [
    //     {
    //       'title': 'Know your food labels',
    //       'subtitle':
    //           'Not sure what "Best Before" really means? Read labels the right way.',
    //       'details':
    //           'Food labels provide important info like expiry dates, storage instructions, and nutritional values. "Best Before" = quality; "Use By" = safety.',
    //       'icon': Icons.label_important_outline,
    //     },
    //     {
    //       'title': 'How to store items properly',
    //       'subtitle':
    //           'Keep your food fresh for longer! Find out where and how to store each item.',
    //       'details':
    //           'Proper storage prevents spoilage. Keep potatoes in a cool dark place, bread in a breadbox, leafy greens in the fridge with a damp paper towel.',
    //       'icon': Icons.inventory_2_outlined,
    //     },
    //     {
    //       'title': 'Nutrition facts check!',
    //       'subtitle':
    //           'Want to know what’s in your food? Quickly check the nutrition info.',
    //       'details':
    //           'Checking nutrition facts helps you make informed choices. Compare sugar, sodium, and fats to choose healthier options.',
    //       'icon': Icons.fact_check_outlined,
    //     },
    //     {
    //       'title': 'Reduce food waste',
    //       'subtitle':
    //           'Small changes make a big difference. Try these simple tips to waste less.',
    //       'details':
    //           'Plan meals, store food properly, and use leftovers creatively. Donate excess food where possible.',
    //       'icon': Icons.recycling_outlined,
    //     },
    //   ],
    // },
    'Meat': {
      'Chicken': [
        {
          'title': 'Storing Raw Chicken',
          'subtitle': 'Refrigerate at 40°F (4°C) or below on the bottom shelf.',
          'details':
              'Always store raw chicken on the bottom shelf of your fridge to prevent juices from dripping onto other foods. Cook or freeze within 2 days.',
          'icon': Icons.kitchen,
        },
      ],
      'Pork': [
        {
          'title': 'Safe Pork Temperature',
          'subtitle': 'Cook to an internal temperature of 145°F (63°C).',
          'details':
              'For safety and quality, cook pork chops, roasts, and tenderloins to an internal temperature of 145°F, then allow it to rest for three minutes before carving or consuming.',
          'icon': Icons.thermostat,
        },
      ],
      'Beef': [
        {
          'title': 'Resting Your Steak',
          'subtitle': 'Let steak rest after cooking for a juicier result.',
          'details':
              'After cooking, let your steak rest on a cutting board for 5-10 minutes before slicing. This allows the juices to redistribute throughout the meat, making it more tender and flavorful.',
          'icon': Icons.timer_outlined,
        },
      ],
    },
    // UPDATED: Added a new 'Fish' category with tips for each item.
    'Fish': {
      'Salmon': [
        {
          'title': 'Fresh Salmon Guide',
          'subtitle': 'Look for vibrant, moist flesh and a mild ocean scent.',
          'details':
              'Fresh salmon should have a bright, deep orange or pink color and firm flesh that springs back when pressed. Avoid any pieces with a strong "fishy" odor or brown spots.',
          'icon': Icons.remove_red_eye_outlined,
        },
        {
          'title': 'Storing Fresh Salmon',
          'subtitle': 'Use within 2 days or freeze for longer storage.',
          'details':
              'Store fresh salmon in the coldest part of your refrigerator, ideally on a bed of ice. If you don\'t plan to cook it within two days, wrap it tightly in plastic wrap and then foil, and place it in the freezer.',
          'icon': Icons.ac_unit,
        },
      ],
      'Tuna': [
        {
          'title': 'Storing Canned Tuna',
          'subtitle': 'Keep unopened cans in a cool, dark pantry.',
          'details':
              'Unopened canned tuna is shelf-stable for several years. Once opened, transfer any leftover tuna to an airtight container and store it in the refrigerator for up to 3-4 days.',
          'icon': Icons.inventory,
        },
      ],
    },
    'Dairy': {
      'Milk': [
        {
          'title': 'Keep Milk Fresh',
          'subtitle':
              'Store milk in the main body of the fridge, not the door.',
          'details':
              'The temperature in the refrigerator door fluctuates more than the shelves, which can cause milk to spoil faster. Always seal it tightly after use.',
          'icon': Icons.opacity,
        },
      ],
      'Cheese': [
        {
          'title': 'Cheese Storage 101',
          'subtitle': 'Wrap cheese in parchment paper, not plastic wrap.',
          'details':
              'Cheese needs to breathe. Wrapping it in parchment or wax paper allows for air circulation while preventing it from drying out.',
          'icon': Icons.icecream_outlined,
        },
      ],
    },
    'Produce': {
      'Apples': [
        {
          'title': 'Storing Apples',
          'subtitle': 'Keep apples in the crisper drawer of your fridge.',
          'details':
              'Refrigerating apples helps them stay crisp and fresh for weeks. Keep them separate from other produce, as they release ethylene gas that can speed up ripening.',
          'icon': Icons.apple,
        },
      ],
      'Lettuce': [
        {
          'title': 'Keep Lettuce Crisp',
          'subtitle': 'Store lettuce with a paper towel to absorb moisture.',
          'details':
              'Wash and dry your lettuce leaves thoroughly. Store them in a container or sealed bag with a dry paper towel to absorb excess water, which helps prevent wilting.',
          'icon': Icons.eco,
        },
      ],
    },
    'Grains': {
      'Rice': [
        {
          'title': 'Store Rice Airtight',
          'subtitle': 'Protect rice from pests and moisture.',
          'details':
              'Transfer rice from its original packaging to an airtight container. Store it in a cool, dark, and dry place like a pantry to maintain its quality.',
          'icon': Icons.rice_bowl,
        },
      ],
      'Bread': [
        {
          'title': 'Best Way to Store Bread',
          'subtitle':
              'Keep bread at room temperature in a breadbox or paper bag.',
          'details':
              'Refrigerating bread can cause it to go stale faster. For long-term storage, slice it and store it in the freezer in a well-sealed bag.',
          'icon': Icons.breakfast_dining_outlined,
        },
      ],
    },
  };

  // --- BUILD METHOD & HELPERS ---

  @override
  Widget build(BuildContext context) {
    // Temporary demo alert so you can see the layout now:
    if (_loadingWeather)
      Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: LinearProgressIndicator(minHeight: 3),
      );
    else if (_alert != null)
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          WeatherAlertBanner(alert: _alert!, initiallyExpanded: false),
          if (_error != null)
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 6),
              child: Text(
                'Showing advisory with fallback info.',
                style: TextStyle(fontSize: 11.5, color: Colors.black54),
              ),
            ),
        ],
      );
    else
      const SizedBox.shrink();

    // (Optional) tiny note if we fell back due to an error, but DO NOT block the banner

    // Final safety — shouldn’t happen because we set a fallback above

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

        // Weather banner area
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

        Expanded(child: _buildBodyContent()),
      ],
    );
  }

  /// Builds the main content area based on the selected category.
  Widget _buildBodyContent() {
    if (selectedCategory == 'General') {
      final generalTips = allTips['General']?['General'] ?? [];
      return ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
        itemCount: generalTips.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final tip = generalTips[index];
          return _buildTipCard(
            context,
            title: tip['title'] as String,
            subtitle: tip['subtitle'] as String,
            details: tip['details'] as String,
            icon: tip['icon'] as IconData,
          );
        },
      );
    }

    // For specific categories, get the items from the pantry.
    final availableItems = pantryItems[selectedCategory] ?? [];

    if (availableItems.isEmpty) {
      return _buildEmptyState();
    }

    // MODIFIED: Use a ListView.separated for better spacing between item cards.
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      itemCount: availableItems.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final itemName = availableItems[index];
        final weatherLevel = _alert?.level ?? WeatherLevel.green;

        // Dynamic, weather-aware tips
        final dynamicTips =
            TipsRules.adviceFor(selectedCategory, itemName, weatherLevel);

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Card(
            elevation: 0,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(_getIconForItem(itemName), size: 22),
                      const SizedBox(width: 8),
                      Text(
                        itemName,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: dynamicTips.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final tip = dynamicTips[i];
                      return _buildTipCard(
                        context,
                        title: tip.title,
                        subtitle: tip.subtitle,
                        details: tip.details,
                        icon: tip.icon,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// NEW WIDGET: Builds a card for a single pantry item, containing its name and tips.
  /// This matches the format of the last generated UI.
  Widget _buildItemCard(String itemName, List<Map<String, dynamic>> tips) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Item Header
            Row(
              children: [
                // A placeholder for an item icon, you can customize this
                Icon(
                  _getIconForItem(itemName), // Helper to get a matching icon
                  color: const Color(0xFF2E7D32),
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    itemName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
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
            const Divider(height: 24, thickness: 1),

            // Tips Section
            const Text(
              'Tips & Suggestions',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 12),
            // Create a Column of clickable tip rows for the current item.
            Column(
              children: tips.map((tip) {
                return InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TipDetailPage(
                          title: tip['title'] as String,
                          details: tip['details'] as String,
                        ),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      children: [
                        Icon(
                          tip['icon'] as IconData,
                          color: Colors.green[700],
                          size: 22,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            tip['subtitle'] as String,
                            style: const TextStyle(
                              fontSize: 15,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  /// A helper widget to show when no items are in the pantry for a category.
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

  // --- Unchanged Helper Widgets ---

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
              builder: (_) => TipDetailPage(title: title, details: details),
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

  // NEW HELPER: Provides a relevant icon for the item name.
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
        return Icons.fastfood; // A generic fallback icon
    }
  }
}
