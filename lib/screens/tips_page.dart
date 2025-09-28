import 'package:flutter/material.dart';

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
    'General': {
      'General': [
        {
          'title': 'Know your food labels',
          'subtitle':
              'Not sure what "Best Before" really means? Read labels the right way.',
          'details':
              'Food labels provide important info like expiry dates, storage instructions, and nutritional values. "Best Before" = quality; "Use By" = safety.',
          'icon': Icons.label_important_outline,
        },
        {
          'title': 'How to store items properly',
          'subtitle':
              'Keep your food fresh for longer! Find out where and how to store each item.',
          'details':
              'Proper storage prevents spoilage. Keep potatoes in a cool dark place, bread in a breadbox, leafy greens in the fridge with a damp paper towel.',
          'icon': Icons.inventory_2_outlined,
        },
        {
          'title': 'Nutrition facts check!',
          'subtitle':
              'Want to know what’s in your food? Quickly check the nutrition info.',
          'details':
              'Checking nutrition facts helps you make informed choices. Compare sugar, sodium, and fats to choose healthier options.',
          'icon': Icons.fact_check_outlined,
        },
        {
          'title': 'Reduce food waste',
          'subtitle':
              'Small changes make a big difference. Try these simple tips to waste less.',
          'details':
              'Plan meals, store food properly, and use leftovers creatively. Donate excess food where possible.',
          'icon': Icons.recycling_outlined,
        },
      ],
    },
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 16, 20, 15),
          child: Text(
            'Tips & Suggestions',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E7D32),
            ),
          ),
        ),
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
        final itemTips = allTips[selectedCategory]?[itemName] ?? [];

        // Use the new _buildItemCard widget for each pantry item.
        return _buildItemCard(itemName, itemTips);
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
