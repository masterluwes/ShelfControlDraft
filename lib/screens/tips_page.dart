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

// Your TipsPage class with the updated tip card UI.
class TipsPage extends StatefulWidget {
  const TipsPage({super.key});

  @override
  State<TipsPage> createState() => _TipsPageState();
}

class _TipsPageState extends State<TipsPage> {
  // --- DATA ---

  final List<Map<String, dynamic>> categories = [
    {'name': 'General', 'icon': Icons.restaurant_menu_outlined},
    {'name': 'Meat', 'icon': Icons.kebab_dining},
    {'name': 'Fish', 'icon': Icons.set_meal},
    {'name': 'Dairy', 'icon': Icons.icecream_outlined},
    {'name': 'Produce', 'icon': Icons.grass},
    {'name': 'Grains', 'icon': Icons.breakfast_dining_outlined},
  ];

  String selectedCategory = 'General';

  final Map<String, List<Map<String, dynamic>>> allTips = {
    'General': [
      {
        'title': 'Know your food labels',
        'subtitle':
            'Not sure what "Best Before" really means? We\'ll help you read labels the right way so you don\'t toss food too early.',
        'details':
            'Food labels provide important info like expiry dates, storage instructions, and nutritional values. "Best Before" = quality; "Use By" = safety.',
        'icon': Icons.label_important_outline,
      },
      {
        'title': 'How to store items properly',
        'subtitle':
            'Keep your food fresh for longer! Find out where and how to store each item the smart way.',
        'details':
            'Proper storage prevents spoilage. Keep potatoes in a cool dark place, bread in a breadbox, leafy greens in the fridge with a damp paper towel.',
        'icon': Icons.inventory_2_outlined,
      },
      {
        'title': 'Nutrition facts check!',
        'subtitle':
            'Want to know what’s in your food? Quickly check the nutrition info to stay on top of your health goals.',
        'details':
            'Checking nutrition facts helps you make informed choices. Compare sugar, sodium, and fats to choose healthier options.',
        'icon': Icons.fact_check_outlined,
      },
      {
        'title': 'Reduce food waste',
        'subtitle':
            'Small changes make a big difference. Try these simple tips to waste less and save more.',
        'details':
            'Plan meals, store food properly, and use leftovers creatively. Donate excess food where possible.',
        'icon': Icons.recycling_outlined,
      },
    ],
    'Meat': [
      {
        'title': 'Storing Meat Safely',
        'subtitle': 'Refrigerate raw meat at 40°F (4°C) or below.',
        'details':
            'Always store raw meat on the bottom shelf of your fridge to prevent juices from dripping onto other foods. Cook or freeze fresh poultry, fish, and ground meats within 2 days; other beef, pork, or lamb within 3 to 5 days.',
        'icon': Icons.kitchen,
      },
    ],
    'Fish': [
      {
        'title': 'Fresh Fish Guide',
        'subtitle': 'Fresh fish should smell like the ocean, not "fishy".',
        'details':
            'Look for clear, full eyes and firm flesh that springs back when touched. Store it in the coldest part of your fridge and use it within 1 to 2 days of purchase.',
        'icon': Icons.phishing,
      },
    ],
    'Dairy': [
      {
        'title': 'Keeping Dairy Fresh',
        'subtitle': 'Store milk in the main body of the fridge, not the door.',
        'details':
            'The temperature in the refrigerator door fluctuates more than the shelves, which can cause milk to spoil faster. Keep cheese tightly wrapped to prevent it from drying out.',
        'icon': Icons.icecream_outlined,
      },
    ],
    'Produce': [
      {
        'title': 'Stop Fruits from Ripening Too Fast',
        'subtitle':
            'Some fruits release gases that speed up ripening in others.',
        'details':
            'Keep ethylene-producing fruits like bananas, avocados, and apples separate from ethylene-sensitive produce like lettuce, broccoli, and carrots.',
        'icon': Icons.grass,
      },
    ],
    'Grains': [
      {
        'title': 'Store Grains Airtight',
        'subtitle':
            'Protect grains like rice, flour, and pasta from pests and moisture.',
        'details':
            'Transfer grains from their original packaging to airtight containers. Store them in a cool, dark, and dry place like a pantry.',
        'icon': Icons.breakfast_dining_outlined,
      },
    ],
  };

  // --- BUILD METHOD & HELPERS ---

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> filteredTips =
        allTips[selectedCategory] ?? [];

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
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            itemCount: filteredTips.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final t = filteredTips[index];
              return _buildTipCard(
                context,
                title: t['title'] as String? ?? 'No Title',
                subtitle: t['subtitle'] as String? ?? 'No subtitle available.',
                details: t['details'] as String? ?? 'No details available.',
                icon: t['icon'] as IconData? ?? Icons.help_outline,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryChip(
    BuildContext context, {
    required String text,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final Color backgroundColor = isSelected
        ? const Color(0xFFE8E5E1)
        : const Color(0xFFF8F5F1);
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
                Text(
                  text,
                  style: TextStyle(
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: contentColor,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // THIS WIDGET HAS BEEN UPDATED to match the new tip card UI
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
      // This is the new softer green color
      color: const Color(0xFFD4E4D5),
      shape: RoundedRectangleBorder(
        // This creates the subtle border
        side: BorderSide(
          color: const Color(0xFFADC2AD), // Border color
          width: 1.5,
        ),
        // This creates the highly rounded corners
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
              // Icon is now black
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
}
