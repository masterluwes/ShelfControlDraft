import 'package:flutter/material.dart';

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
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontFamily: 'Inter',
            fontWeight: FontWeight.bold,
          ),
        ),
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
              fontFamily: 'Roboto',
            ),
          ),
        ),
      ),
    );
  }
}

class TipsPage extends StatefulWidget {
  const TipsPage({super.key});

  @override
  State<TipsPage> createState() => _TipsPageState();
}

class _TipsPageState extends State<TipsPage> {
  // --- DATA ---
  final List<Map<String, dynamic>> categories = [
    {'name': 'General', 'icon': Icons.local_dining},
    {'name': 'Produce', 'icon': Icons.spa_outlined},
    {'name': 'Protein', 'icon': Icons.set_meal},
    {'name': 'Dairy & Eggs', 'icon': Icons.egg_alt_outlined},
    {'name': 'Grains', 'icon': Icons.grain},
    {'name': 'Staples', 'icon': Icons.inventory_2_outlined},
    {'name': 'Frozen', 'icon': Icons.ac_unit},
  ];

  final Map<String, List<String>> pantryItems = {
    'Protein': ['Chicken', 'Pork', 'Beef', 'Salmon', 'Tuna'],
    'Dairy & Eggs': ['Milk', 'Cheese'],
    'Produce': ['Apples', 'Lettuce'],
    'Grains': ['Rice', 'Bread'],
    'Staples': [],
    'Frozen': [],
  };

  String selectedCategory = 'General';

  final Map<String, Map<String, List<Map<String, dynamic>>>> allTips = {
    'General': {
      'General': [
        {
          'title': 'Know your food labels',
          'subtitle':
              'Not sure what "Best Before" really means? Read labels the right way.',
          'details':
              'Food labels provide important info like expiry dates, storage instructions, and nutritional values. "Best Before" indicates quality, while "Use By" indicates safety. Always check both to ensure your food is safe and at its best.',
          'icon': Icons.label_important_outline,
        },
        {
          'title': 'How to store items properly',
          'subtitle':
              'Keep your food fresh for longer! Find out where and how to store each item.',
          'details':
              'Proper storage is key to preventing spoilage. For example, keep potatoes in a cool, dark place (not the fridge), bread in a breadbox or freezer, and leafy greens in the fridge with a damp paper towel to maintain crispness.',
          'icon': Icons.inventory_2_outlined,
        },
        {
          'title': 'Nutrition facts check!',
          'subtitle':
              'Want to know what’s in your food? Quickly check the nutrition info.',
          'details':
              'Checking nutrition facts helps you make informed choices about your diet. Pay attention to serving sizes and compare sugar, sodium, and fat content between similar products to choose the healthier option.',
          'icon': Icons.fact_check_outlined,
        },
        {
          'title': 'Reduce food waste',
          'subtitle':
              'Small changes make a big difference. Try these simple tips to waste less.',
          'details':
              'You can significantly reduce food waste by planning your meals, storing food correctly, and using leftovers creatively. Consider composting scraps or donating excess non-perishable food to local food banks.',
          'icon': Icons.recycling_outlined,
        },
      ],
    },
    'Protein': {
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
    'Dairy & Eggs': {
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
    'Staples': {},
    'Frozen': {},
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(15, 12, 12, 6),
          child: Text(
            'Tips & Suggestions',
            style: TextStyle(
              color: Color(0xFF347928),
              fontFamily: 'Inter',
              fontSize: 34,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        SizedBox(
          height: 110,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              final isSelected =
                  selectedCategory == (category['name'] as String? ?? '');
              return _buildCategoryChip(
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

  // --- MODIFIED: This widget has been completely restyled ---
  Widget _buildCategoryChip({
    required String text,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final Color selectedBgColor = Colors.grey.shade800;
    final Color unselectedBgColor = const Color(0xFFF8F5F1);
    final Color selectedContentColor = Colors.white;
    final Color unselectedContentColor = Colors.black87;

    // --- MODIFIED: Added AnimatedOpacity for the fade effect ---
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: isSelected ? 0.6 : 0.6, // Unselected items are faded
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 90, // Made the container square
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected ? selectedBgColor : unselectedBgColor,
            borderRadius: BorderRadius.circular(15),
            boxShadow: !isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 5,
                      offset: const Offset(2, 2),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected
                    ? selectedContentColor
                    : unselectedContentColor,
                size: 30,
              ),
              const SizedBox(height: 8),
              Text(
                text,
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected
                      ? selectedContentColor
                      : unselectedContentColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the main content area based on the selected category.
  Widget _buildBodyContent() {
    if (selectedCategory == 'General') {
      return _buildGeneralTipsPage();
    }
    if (selectedCategory == 'Produce') {
      return _buildProduceTipsPage();
    }
    if (selectedCategory == 'Protein') {
      return _buildProteinTipsPage();
    }
    if (selectedCategory == 'Dairy & Eggs') {
      return _buildDairyAndEggsTipsPage();
    }
    if (selectedCategory == 'Grains') {
      return _buildGrainsTipsPage();
    }
    if (selectedCategory == 'Staples') {
      return _buildStaplesTipsPage();
    }
    if (selectedCategory == 'Frozen') {
      return _buildFrozenTipsPage();
    }

    // For other categories, fall back to the item-specific view.
    final availableItems = pantryItems[selectedCategory] ?? [];

    if (availableItems.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      itemCount: availableItems.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final itemName = availableItems[index];
        final itemTips = allTips[selectedCategory]?[itemName] ?? [];
        return _buildItemCard(itemName, itemTips);
      },
    );
  }

  // --- PAGE BUILDERS (DATA PREPARATION) ---

  Widget _buildGeneralTipsPage() {
    final generalTips = allTips['General']?['General'] ?? [];
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
      child: Column(
        children: List.generate(generalTips.length, (index) {
          final tip = generalTips[index];
          return Padding(
            padding: EdgeInsets.only(
              bottom: index < generalTips.length - 1
                  ? 16.0
                  : 0, // Increased spacing
            ),
            child: _ExpandableTipCard(
              key: ValueKey(tip['title']),
              title: tip['title'] as String,
              icon: tip['icon'] as IconData,
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tip['subtitle'] as String,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.black54,
                      height: 1.5,
                      fontFamily: 'Roboto',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    tip['details'] as String,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.black87,
                      height: 1.5,
                      fontFamily: 'Roboto',
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildProduceTipsPage() {
    final List<Map<String, dynamic>> cardData = [
      {
        'title': 'General Tips',
        'icon': Icons.info_outline,
        'content': _buildGeneralProduceTips(),
      },
      {
        'title': 'How to Clean',
        'icon': Icons.wash_outlined,
        'content': _buildCleaningTips(),
      },
      {
        'title': 'Vegetables',
        'icon': Icons.spa_outlined,
        'content': _buildVegetableTips(),
      },
      {
        'title': 'Fruits',
        'icon': Icons.apple_outlined,
        'content': _buildFruitTips(),
      },
      {
        'title': 'How to Preserve',
        'icon': Icons.inventory_2_outlined,
        'content': _buildPreservingTips(),
      },
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
      child: Column(
        children: List.generate(cardData.length, (index) {
          final card = cardData[index];
          return Padding(
            padding: EdgeInsets.only(
              bottom: index < cardData.length - 1
                  ? 16.0
                  : 0, // Increased spacing
            ),
            child: _ExpandableTipCard(
              key: ValueKey(card['title']),
              title: card['title'] as String,
              icon: card['icon'] as IconData,
              content: card['content'] as Widget,
            ),
          );
        }),
      ),
    );
  }

  Widget _buildProteinTipsPage() {
    final List<Map<String, dynamic>> cardData = [
      {
        'title': "Meat vs. Fish",
        'icon': Icons.difference_outlined,
        'content': _buildProteinDifferenceContent(),
      },
      {
        'title': "Refrigerator Storage",
        'icon': Icons.kitchen_outlined,
        'content': _buildRefrigeratorStorageContent(),
      },
      {
        'title': "Freezer Storage",
        'icon': Icons.ac_unit_outlined,
        'content': _buildFreezerStorageContent(),
      },
    ];
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
      child: Column(
        children: List.generate(cardData.length, (index) {
          final card = cardData[index];
          return Padding(
            padding: EdgeInsets.only(
              bottom: index < cardData.length - 1
                  ? 16.0
                  : 0, // Increased spacing
            ),
            child: _ExpandableTipCard(
              key: ValueKey(card['title']),
              title: card['title'] as String,
              icon: card['icon'] as IconData,
              content: card['content'] as Widget,
            ),
          );
        }),
      ),
    );
  }

  Widget _buildDairyAndEggsTipsPage() {
    final List<Map<String, dynamic>> cardData = [
      {
        'title': "Refrigerator Storage",
        'icon': Icons.kitchen_outlined,
        'content': _buildDairyFridgeContent(),
      },
      {
        'title': "Freezer Storage",
        'icon': Icons.ac_unit_outlined,
        'content': _buildDairyFreezerContent(),
      },
      {
        'title': "How to Store Eggs",
        'icon': Icons.egg_outlined,
        'content': _buildEggsContent(),
      },
    ];
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
      child: Column(
        children: List.generate(cardData.length, (index) {
          final card = cardData[index];
          return Padding(
            padding: EdgeInsets.only(
              bottom: index < cardData.length - 1
                  ? 16.0
                  : 0, // Increased spacing
            ),
            child: _ExpandableTipCard(
              key: ValueKey(card['title']),
              title: card['title'] as String,
              icon: card['icon'] as IconData,
              content: card['content'] as Widget,
            ),
          );
        }),
      ),
    );
  }

  Widget _buildGrainsTipsPage() {
    final List<Map<String, dynamic>> cardData = [
      {
        'title': "Dry Grains, Pasta & Cereals",
        'icon': Icons.inventory_2_outlined,
        'content': _buildDryGrainsContent(),
      },
      {
        'title': "Cooked Grains & Pasta",
        'icon': Icons.rice_bowl_outlined,
        'content': _buildCookedGrainsContent(),
      },
      {
        'title': "Bread & Baked Goods",
        'icon': Icons.bakery_dining_outlined,
        'content': _buildBreadContent(),
      },
    ];
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
      child: Column(
        children: List.generate(cardData.length, (index) {
          final card = cardData[index];
          return Padding(
            padding: EdgeInsets.only(
              bottom: index < cardData.length - 1
                  ? 16.0
                  : 0, // Increased spacing
            ),
            child: _ExpandableTipCard(
              key: ValueKey(card['title']),
              title: card['title'] as String,
              icon: card['icon'] as IconData,
              content: card['content'] as Widget,
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStaplesTipsPage() {
    final List<Map<String, dynamic>> cardData = [
      {
        'title': "Canned & Jarred Goods",
        'icon': Icons.kitchen,
        'content': _buildCannedGoodsContent(),
      },
      {
        'title': "Oils, Vinegars & Sauces",
        'icon': Icons.oil_barrel_outlined,
        'content': _buildOilsContent(),
      },
      {
        'title': "Spices, Herbs & Seasonings",
        'icon': Icons.grass,
        'content': _buildSpicesContent(),
      },
      {
        'title': "Nuts, Seeds & Dried Fruit",
        'icon': Icons.food_bank_outlined,
        'content': _buildNutsContent(),
      },
    ];
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
      child: Column(
        children: List.generate(cardData.length, (index) {
          final card = cardData[index];
          return Padding(
            padding: EdgeInsets.only(
              bottom: index < cardData.length - 1
                  ? 16.0
                  : 0, // Increased spacing
            ),
            child: _ExpandableTipCard(
              key: ValueKey(card['title']),
              title: card['title'] as String,
              icon: card['icon'] as IconData,
              content: card['content'] as Widget,
            ),
          );
        }),
      ),
    );
  }

  Widget _buildFrozenTipsPage() {
    final List<Map<String, dynamic>> cardData = [
      {
        'title': "The Golden Rule of Freezing",
        'icon': Icons.rule_sharp,
        'content': _buildFreezingRuleContent(),
      },
      {
        'title': "Frozen Fruits & Vegetables",
        'icon': Icons.ac_unit,
        'content': _buildFrozenProduceContent(),
      },
      {
        'title': "Frozen Meats & Meals",
        'icon': Icons.set_meal,
        'content': _buildFrozenMeatsContent(),
      },
      {
        'title': "Ice Cream & Desserts",
        'icon': Icons.icecream_outlined,
        'content': _buildFrozenDessertsContent(),
      },
    ];
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
      child: Column(
        children: List.generate(cardData.length, (index) {
          final card = cardData[index];
          return Padding(
            padding: EdgeInsets.only(
              bottom: index < cardData.length - 1
                  ? 16.0
                  : 0, // Increased spacing
            ),
            child: _ExpandableTipCard(
              key: ValueKey(card['title']),
              title: card['title'] as String,
              icon: card['icon'] as IconData,
              content: card['content'] as Widget,
            ),
          );
        }),
      ),
    );
  }

  // --- CONTENT HELPERS FOR EXPANDABLE CARDS ---

  Widget _buildRichTextTip({
    required String title,
    required String body,
    String? source,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0), // Increased spacing
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
            fontSize: 15,
            color: Colors.black87,
            height: 1.5,
            fontFamily: 'Roboto',
          ),
          children: [
            TextSpan(
              text: title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: 'Roboto',
              ),
            ),
            TextSpan(text: body),
            if (source != null)
              TextSpan(
                text: ' (Source: $source)',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                  fontFamily: 'Roboto',
                ),
              ),
          ],
        ),
      ),
    );
  }

  // PRODUCE
  Widget _buildGeneralProduceTips() {
    return const Text(
      'These essential rules apply to everything from leafy greens to hard-shelled melons. Storing produce correctly is the secret to making it last longer. The key is knowing which items need the cold and which prefer the counter.',
      style: TextStyle(height: 1.5, fontSize: 15, fontFamily: 'Roboto'),
    );
  }

  Widget _buildCleaningTips() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Always wash produce to remove dirt and germs before eating or cooking.",
          style: TextStyle(height: 1.5, fontSize: 15, fontFamily: 'Roboto'),
        ),
        const SizedBox(height: 16), // Increased spacing
        _buildRichTextTip(
          title: "Wash Just Before Using: ",
          body:
              "Rinse fruits and vegetables under cool, running tap water immediately before you plan to use them. Washing them too far in advance can remove their natural protective coating, causing them to spoil faster.",
        ),
        _buildRichTextTip(
          title: "Exception: ",
          body:
              "Leafy greens like lettuce and cabbage often stay crisper if you wash, dry, and refrigerate them right after buying.",
        ),
        _buildRichTextTip(
          title: "No Soap Needed: ",
          body:
              "Never use soap, detergent, or bleach to wash produce. Clean, running water is all you need.",
        ),
        _buildRichTextTip(
          title: "Wash Everything: ",
          body:
              "You should even wash produce with peels you don't eat, like bananas, melons, oranges, and mangoes. Germs on the outside can be transferred to the inside by your knife when you cut them.",
        ),
        _buildRichTextTip(
          title: "Pre-Washed is Ready to Go: ",
          body:
              "If a package says \"ready-to-eat,\" \"washed,\" or \"triple washed,\" you don't need to wash it again.",
        ),
      ],
    );
  }

  Widget _buildVegetableTips() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Store These in the Refrigerator:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            fontFamily: 'Inter',
          ),
        ),
        const SizedBox(height: 4),
        _buildRichTextTip(
          title: 'Best For: ',
          body:
              'Asparagus, beets, broccoli, Brussels sprouts, cabbage, carrots, cauliflower, celery, green beans, leafy greens (lettuce, spinach), mushrooms, and radishes.',
        ),
        _buildRichTextTip(
          title: 'How: ',
          body:
              'Place them in perforated plastic bags in the produce drawers to retain moisture.',
        ),
        const Divider(height: 32), // Increased spacing
        const Text(
          'Store These at Room Temperature:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            fontFamily: 'Inter',
          ),
        ),
        const SizedBox(height: 4),
        _buildRichTextTip(
          title: 'Best For: ',
          body:
              'Garlic, onions, potatoes, sweet potatoes, and winter squashes.',
        ),
        _buildRichTextTip(
          title: 'Why: ',
          body:
              'Refrigeration ruins their flavor and texture. A cold environment makes potatoes become gritty and sweet, and it can cause onions and garlic to sprout or become moldy.',
        ),
        _buildRichTextTip(
          title: 'How: ',
          body:
              'Keep them in a cool, dark, and dry place with good air circulation, like a pantry.',
        ),
      ],
    );
  }

  Widget _buildFruitTips() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Store These in the Refrigerator:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            fontFamily: 'Inter',
          ),
        ),
        const SizedBox(height: 4),
        _buildRichTextTip(
          title: 'Best For: ',
          body:
              'Apples (if storing longer than a week), berries (strawberries, blueberries, raspberries), cherries, and grapes.',
        ),
        _buildRichTextTip(
          title: 'How: ',
          body:
              'Store them in the produce drawer. To prevent mold, wait to wash berries until just before you eat them.',
        ),
        const Divider(height: 32), // Increased spacing
        const Text(
          'Ripen on the Counter, THEN Refrigerate:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            fontFamily: 'Inter',
          ),
        ),
        const SizedBox(height: 4),
        _buildRichTextTip(
          title: 'Best For: ',
          body:
              'Avocados, apricots, kiwi, nectarines, peaches, pears, and plums.',
        ),
        _buildRichTextTip(
          title: 'How: ',
          body:
              'Leave them on the counter until they are ripe. Once ripe, you can move them to the fridge to make them last for several more days.',
        ),
        _buildRichTextTip(
          title: 'Pro-Tip: ',
          body:
              'To speed up ripening, place the fruit in a paper bag with an apple.',
        ),
        const Divider(height: 32), // Increased spacing
        const Text(
          'Store ONLY at Room Temperature:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            fontFamily: 'Inter',
          ),
        ),
        const SizedBox(height: 4),
        _buildRichTextTip(
          title: 'Best For: ',
          body:
              'Bananas, citrus fruits (lemons, limes, oranges), mangoes, melons, pineapples, and tomatoes.',
        ),
        _buildRichTextTip(
          title: 'Why: ',
          body:
              'The cold from the refrigerator can damage them. It makes bananas turn black and stops melons and tomatoes from developing their full flavor.',
        ),
        _buildRichTextTip(
          title: 'How: ',
          body: 'Keep them on the counter, but away from direct sunlight.',
        ),
      ],
    );
  }

  Widget _buildPreservingTips() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "If you have more produce than you can eat before it spoils, preserve it for later!",
          style: TextStyle(height: 1.5, fontSize: 15, fontFamily: 'Roboto'),
        ),
        const SizedBox(height: 16), // Increased spacing
        _buildRichTextTip(
          title: 'Freezing: ',
          body:
              'One of the easiest methods. Most vegetables and many fruits freeze well, locking in their nutrients and flavor for months.',
        ),
        _buildRichTextTip(
          title: 'Canning: ',
          body:
              "This involves sealing food in jars and heating them to kill bacteria. It's great for making jams from fruit or preserving vegetables like tomatoes and beans.",
        ),
        _buildRichTextTip(
          title: 'Drying (Dehydrating): ',
          body:
              'Removing the water from produce stops it from spoiling. You can make things like dried mangoes, apple chips, or sun-dried tomatoes.',
        ),
      ],
    );
  }

  // PROTEIN
  Widget _buildProteinDifferenceContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "While both are the flesh of animals used for food, they have key nutritional differences:",
          style: TextStyle(height: 1.5, fontSize: 15, fontFamily: 'Roboto'),
        ),
        const SizedBox(height: 16), // Increased spacing
        _buildRichTextTip(
          title: "Meat (beef, pork, chicken): ",
          body: "Tends to be higher in saturated fat, Vitamin B12, and iron.",
        ),
        _buildRichTextTip(
          title: "Fish: ",
          body:
              "Is often lower in fat and a great source of healthy omega-3 fatty acids and Vitamin D.",
        ),
        const Divider(height: 32), // Increased spacing
        _buildRichTextTip(
          title: "Recommendation: ",
          body:
              "For heart health, many organizations recommend eating at least two servings of fish per week and limiting your intake of red meat.",
        ),
      ],
    );
  }

  Widget _buildRefrigeratorStorageContent() {
    final List<Map<String, String>> data = [
      {'type': 'Ground Meat (beef, pork, etc.)', 'time': '1 to 2 days'},
      {'type': 'Steaks, Chops, and Roasts', 'time': '3 to 5 days'},
      {'type': 'Fresh Poultry (whole or pieces)', 'time': '1 to 2 days'},
      {'type': 'Fresh Fish & Shellfish', 'time': '1 to 2 days'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Safe storage is critical to prevent the growth of harmful bacteria. Use this chart for how long you can safely keep fresh proteins in the fridge (at or below 40°F / 4°C).",
          style: TextStyle(height: 1.5, fontSize: 15, fontFamily: 'Roboto'),
        ),
        const SizedBox(height: 8),
        Center(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const <DataColumn>[
                DataColumn(
                  label: Expanded(
                    child: Text(
                      'Food Type',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ),
                ),
                DataColumn(
                  label: Expanded(
                    child: Text(
                      'Storage Time',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ),
                ),
              ],
              rows: data
                  .map(
                    (item) => DataRow(
                      cells: <DataCell>[
                        DataCell(
                          Text(
                            item['type']!,
                            style: const TextStyle(fontFamily: 'Roboto'),
                          ),
                        ),
                        DataCell(
                          Text(
                            item['time']!,
                            style: const TextStyle(fontFamily: 'Roboto'),
                          ),
                        ),
                      ],
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildRichTextTip(
          title: "Pro-Tip: ",
          body:
              "Store raw meat and poultry in sealed containers or plastic bags on the bottom shelf of your fridge. This prevents their juices from dripping onto and contaminating other foods.",
        ),
      ],
    );
  }

  Widget _buildFreezerStorageContent() {
    final List<Map<String, String>> data = [
      {'type': 'Ground Meat', 'time': '3 to 4 months'},
      {'type': 'Steaks, Chops, and Roasts', 'time': '4 to 12 months'},
      {'type': 'Whole Poultry', 'time': '1 year'},
      {'type': 'Poultry Pieces', 'time': '9 months'},
      {'type': 'Lean Fish (cod, flounder)', 'time': '6 to 8 months'},
      {'type': 'Fatty Fish (salmon, tuna)', 'time': '2 to 3 months'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "For longer storage, the freezer is your best option (at 0°F / -18°C). While food is safe indefinitely, use this chart for best quality.",
          style: TextStyle(height: 1.5, fontSize: 15, fontFamily: 'Roboto'),
        ),
        const SizedBox(height: 8),
        Center(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const <DataColumn>[
                DataColumn(
                  label: Expanded(
                    child: Text(
                      'Food Type',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ),
                ),
                DataColumn(
                  label: Expanded(
                    child: Text(
                      'Best Quality',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ),
                ),
              ],
              rows: data
                  .map(
                    (item) => DataRow(
                      cells: <DataCell>[
                        DataCell(
                          Text(
                            item['type']!,
                            style: const TextStyle(fontFamily: 'Roboto'),
                          ),
                        ),
                        DataCell(
                          Text(
                            item['time']!,
                            style: const TextStyle(fontFamily: 'Roboto'),
                          ),
                        ),
                      ],
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildRichTextTip(
          title: "Remember the 2-Hour Rule: ",
          body:
              "Never leave perishable foods like meat, poultry, or fish out at room temperature for more than two hours (or one hour if it's above 90°F / 32°C).",
        ),
      ],
    );
  }

  // DAIRY & EGGS
  Widget _buildDairyFridgeContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildRichTextTip(
          title: "Check the Temperature: ",
          body:
              "Your fridge should be set at or below 40°F (4°C) to slow down bacteria growth.",
        ),
        _buildRichTextTip(
          title: "Store in the Main Part of the Fridge: ",
          body:
              "Don't store milk and eggs in the fridge door. The temperature in the door fluctuates the most, which can cause them to spoil faster. Store them on a main shelf where the temperature is more stable.",
        ),
        _buildRichTextTip(
          title: "Keep it Sealed: ",
          body:
              "Keep dairy products like milk, cheese, and yogurt in their original, tightly sealed containers to prevent them from absorbing smells from other foods.",
        ),
        _buildRichTextTip(
          title: "Check \"Use-By\" Dates: ",
          body:
              "This date tells you how long the product will be at its best quality. Always check the date before buying and use older products first.",
        ),
        const Divider(height: 32), // Increased spacing
        _buildRichTextTip(
          title: "Remember: ",
          body:
              "If a dairy product looks, smells, or tastes off, it's always best to throw it out. When in doubt, don't risk it!",
        ),
      ],
    );
  }

  Widget _buildDairyFreezerContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Did you know you can freeze many dairy products? It's a great way to prevent waste.",
          style: TextStyle(height: 1.5, fontSize: 15, fontFamily: 'Roboto'),
        ),
        const SizedBox(height: 16), // Increased spacing
        _buildRichTextTip(
          title: "Milk: ",
          body:
              "You can freeze milk, but it may separate and look grainy when thawed. It's best used for cooking or baking. Leave some extra room in the container before freezing, as the liquid will expand.",
        ),
        _buildRichTextTip(
          title: "Cheese: ",
          body:
              "Hard cheeses like cheddar and parmesan can be frozen. It's best to grate or slice them first. Soft cheeses like cottage cheese and cream cheese don't freeze as well and can become watery.",
        ),
        _buildRichTextTip(
          title: "Yogurt and Cream: ",
          body:
              "Like milk, these can be frozen, but their texture will change. They are best used in cooking or smoothies after thawing.",
        ),
      ],
    );
  }

  Widget _buildEggsContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildRichTextTip(
          title: "In the Fridge: ",
          body:
              "Store eggs in their original carton on a shelf in the main part of the refrigerator, not the door. The carton protects them from cracking and absorbing odors.",
        ),
        const Divider(height: 32), // Increased spacing
        const Text(
          "Can You Freeze Eggs? Yes, but never in their shells! The shells will crack.",
          style: TextStyle(
            height: 1.5,
            fontSize: 15,
            fontWeight: FontWeight.bold,
            fontFamily: 'Inter',
          ),
        ),
        const SizedBox(height: 16), // Increased spacing
        _buildRichTextTip(
          title: "To freeze whole eggs: ",
          body:
              "Crack the eggs into a bowl, whisk them until blended, and then freeze them in an airtight container.",
        ),
        _buildRichTextTip(
          title: "To freeze egg whites: ",
          body: "Simply separate them and freeze them as is.",
        ),
        _buildRichTextTip(
          title: "To freeze egg yolks: ",
          body:
              "Yolks can get gummy when frozen. To prevent this, a mix in a little salt or sugar before freezing, depending on whether you'll use them for savory or sweet dishes later.",
        ),
      ],
    );
  }

  // GRAINS
  Widget _buildDryGrainsContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Dry goods like rice, oats, quinoa, and pasta are pantry staples because they store so well.",
          style: TextStyle(height: 1.5, fontSize: 15, fontFamily: 'Roboto'),
        ),
        const SizedBox(height: 16), // Increased spacing
        _buildRichTextTip(
          title: "Keep Them in a Cool, Dry Place: ",
          body:
              "Your cupboard or pantry is the perfect spot for most dry grains.",
        ),
        _buildRichTextTip(
          title: "Use Airtight Containers: ",
          body:
              "Once opened, it's best to store flours, oats, rice, and other grains in airtight containers. This protects them from pests and moisture. Pasta, however, can be kept in its original packaging.",
        ),
        _buildRichTextTip(
          title: "Freeze for Longer Life: ",
          body:
              "For whole grains (like brown rice or whole wheat flour), the refrigerator or freezer is an even better option. Their higher oil content means they can spoil faster at room temperature. Freezing in airtight containers can extend their shelf life significantly.",
        ),
      ],
    );
  }

  Widget _buildCookedGrainsContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Once cooked, grains need to be refrigerated to stay safe.",
          style: TextStyle(height: 1.5, fontSize: 15, fontFamily: 'Roboto'),
        ),
        const SizedBox(height: 16), // Increased spacing
        _buildRichTextTip(
          title: "Refrigerate Promptly: ",
          body:
              "Store cooked pasta, rice, and other grains in the refrigerator within two hours of cooking.",
        ),
        _buildRichTextTip(
          title: "Use Sealed Containers: ",
          body:
              "Keep them in a sealed or airtight container to maintain quality and prevent them from drying out.",
        ),
        _buildRichTextTip(
          title: "Use Within a Few Days: ",
          body:
              "For best results, use cooked pasta and grains within three to five days.",
        ),
      ],
    );
  }

  Widget _buildBreadContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Storing bread can be tricky—you want to avoid both mold and dryness.",
          style: TextStyle(height: 1.5, fontSize: 15, fontFamily: 'Roboto'),
        ),
        const SizedBox(height: 16), // Increased spacing
        _buildRichTextTip(
          title: "For Short-Term (1-2 days): ",
          body:
              "Keep bread at room temperature in a bread box or paper bag. This helps maintain a crisp crust. The refrigerator will make it go stale faster.",
        ),
        _buildRichTextTip(
          title: "For Longer Storage: ",
          body:
              "To prevent mold, wrap bread tightly and store it in the fridge. You can toast it to bring back some texture. For the longest storage, wrap it tightly and freeze it.",
        ),
        _buildRichTextTip(
          title: "For Other Baked Goods: ",
          body:
              "Items like cookies, brownies, and muffins should be stored in an airtight container at room temperature. They will last for up to five days. Only items heavy in dairy, like cream pies or cakes with buttercream frosting, need to be refrigerated.",
        ),
      ],
    );
  }

  // STAPLES
  Widget _buildCannedGoodsContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildRichTextTip(
          title: "Where to Store: ",
          body:
              "Keep them in a cool, dark, and dry place like a cupboard or pantry, away from the stove or direct sunlight. Heat can cause the food to spoil faster.",
        ),
        _buildRichTextTip(
          title: "Check for Damage: ",
          body:
              "Never use cans that are bulging, leaking, dented at the seams, or badly rusted. This could be a sign of contamination.",
        ),
        _buildRichTextTip(
          title: "\"Best-By\" Dates: ",
          body:
              "Canned goods are safe to eat long past their \"best-by\" date, as long as the can is in good condition. However, they may lose some flavor and nutritional value over time. For best quality, use them within one to two years.",
          source: "United States Department of Agriculture (USDA)",
        ),
      ],
    );
  }

  Widget _buildOilsContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildRichTextTip(
          title: "Cooking Oils: ",
          body:
              "Store cooking oils like vegetable and olive oil in a cool, dark place. Heat and light can make them go rancid (develop an off-flavor). While most can be kept in the pantry, some, like sesame oil, benefit from refrigeration after opening.",
        ),
        _buildRichTextTip(
          title: "Vinegars: ",
          body:
              "Thanks to their high acidity, vinegars are self-preserving. Store them in a cool, dark place with the cap tightly sealed to maintain the best quality.",
        ),
        _buildRichTextTip(
          title: "Sauces: ",
          body:
              "Many sauces, such as soy sauce, can be stored in the pantry before opening. However, after opening, most should be refrigerated to maintain their quality and safety. Always check the label for storage instructions like \"Refrigerate after opening.\"",
          source: "University of Minnesota Extension",
        ),
      ],
    );
  }

  Widget _buildSpicesContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildRichTextTip(
          title: "Keep Them Dry and Airtight: ",
          body:
              "Store dried spices, herbs, and seasonings in airtight containers in a cool, dark place, like a cabinet or drawer. Avoid storing them right above the stove, where heat and steam can ruin their quality.",
        ),
        _buildRichTextTip(
          title: "Whole vs. Ground: ",
          body:
              "Whole spices (like peppercorns or cloves) will stay fresh and flavorful much longer than ground spices.",
        ),
        _buildRichTextTip(
          title: "How to Check for Freshness: ",
          body:
              "To check if a spice is still good, crush a small amount in your hand. If the aroma is weak, it’s time to replace it.",
          source: "PennState Extension",
        ),
      ],
    );
  }

  Widget _buildNutsContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "These items are more delicate than they seem due to their high oil content.",
          style: TextStyle(height: 1.5, fontSize: 15, fontFamily: 'Roboto'),
        ),
        const SizedBox(height: 16), // Increased spacing
        _buildRichTextTip(
          title: "Cool is Best: ",
          body:
              "Because of their oils, nuts and seeds can go rancid quickly at room temperature. For short-term storage (a few months), an airtight container in a cool, dark pantry is fine.",
        ),
        _buildRichTextTip(
          title: "Refrigerate or Freeze for Longevity: ",
          body:
              "To keep nuts, seeds, and dried fruit fresh for up to a year or more, store them in airtight containers or freezer bags in the refrigerator or freezer. This is the best way to protect their flavor and prevent them from spoiling.",
          source: "University of California Agriculture and Natural Resources",
        ),
      ],
    );
  }

  // FROZEN
  Widget _buildFreezingRuleContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildRichTextTip(
          title: "Keep it Cold: ",
          body:
              "Your freezer must be set to 0°F (-18°C) or lower. This temperature keeps food safe indefinitely by making bacteria, yeasts, and molds dormant. While the food will be safe, its quality (taste and texture) can decline over time.",
        ),
        _buildRichTextTip(
          title: "Quality In, Quality Out: ",
          body:
              "Freezing doesn't improve food quality, it just preserves it. Always freeze items when they are at their peak freshness for the best results after thawing.",
        ),
      ],
    );
  }

  Widget _buildFrozenProduceContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildRichTextTip(
          title: "Blanch Your Veggies: ",
          body:
              "Before freezing most vegetables, you should blanch them—boil or steam them for a short time and then immediately cool them in ice water. This simple step stops enzymes from ruining the vegetable's flavor, color, and texture.",
        ),
        _buildRichTextTip(
          title: "Protect Your Fruits: ",
          body:
              "To prevent fruits from browning, you can treat them with ascorbic acid (Vitamin C) before freezing.",
        ),
        _buildRichTextTip(
          title: "Pack it Right: ",
          body:
              "Use moisture-proof, airtight containers or freezer bags. Squeeze out as much air as possible before sealing to prevent freezer burn.",
        ),
      ],
    );
  }

  Widget _buildFrozenMeatsContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildRichTextTip(
          title: "Packaging is Key: ",
          body:
              "While you can freeze meat in its original store packaging for a short time, it's best to overwrap it with heavy-duty foil, plastic wrap, or freezer paper for long-term storage. This provides an extra barrier against freezer burn.",
        ),
        const SizedBox(height: 12), // Increased spacing
        const Text(
          "Safe Thawing is Crucial: Never thaw meat or meals on the kitchen counter. The three safe ways to thaw are:",
          style: TextStyle(
            height: 1.5,
            fontSize: 15,
            fontWeight: FontWeight.bold,
            fontFamily: 'Inter',
          ),
        ),
        const Padding(
          padding: EdgeInsets.only(left: 16.0, top: 8.0),
          child: Text(
            "• In the refrigerator (safest method)\n• In cold water (in a leak-proof bag, changing the water every 30 mins)\n• In the microwave (but you must cook the food immediately after)",
            style: TextStyle(height: 1.6, fontSize: 15, fontFamily: 'Roboto'),
          ),
        ),
      ],
    );
  }

  Widget _buildFrozenDessertsContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildRichTextTip(
          title: "Store in the Main Part of the Freezer: ",
          body:
              "Don't store ice cream in the freezer door. Store it in the main part of the freezer where the temperature is most consistent and coldest.",
        ),
        _buildRichTextTip(
          title: "Maintain Temperature: ",
          body:
              "Your freezer should be set between -5°F and 0°F (-20°C and -18°C). Do not allow ice cream to repeatedly soften and refreeze, as this ruins its texture.",
        ),
        _buildRichTextTip(
          title: "Prevent Freezer Burn: ",
          body:
              "After scooping, place a piece of plastic wrap directly on the surface of the ice cream before putting the lid back on. This helps prevent stubborn ice crystals from forming.",
        ),
        _buildRichTextTip(
          title: "Keep the Lid on Tight: ",
          body:
              "Make sure the lid is secure to keep out other freezer odors and to maintain quality.",
        ),
      ],
    );
  }

  // --- Original Helper Widgets for other categories ---

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
            Row(
              children: [
                Icon(
                  _getIconForItem(itemName),
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
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24, thickness: 1),
            const Text(
              'Tips & Suggestions',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black54,
                fontFamily: 'Inter',
              ),
            ),
            const SizedBox(height: 12),
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
                              fontFamily: 'Roboto',
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
                fontFamily: 'Inter',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add items to your pantry in the "$selectedCategory" category to see relevant tips here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[600],
                fontFamily: 'Roboto',
              ),
            ),
          ],
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
}

/// A StatefulWidget that manages its own expanded/collapsed state, allowing
/// multiple cards to be open simultaneously.
class _ExpandableTipCard extends StatefulWidget {
  final String title;
  final IconData icon;
  final Widget content;
  final bool initiallyExpanded;

  const _ExpandableTipCard({
    super.key,
    required this.title,
    required this.icon,
    required this.content,
    this.initiallyExpanded = false,
  });

  @override
  State<_ExpandableTipCard> createState() => _ExpandableTipCardState();
}

class _ExpandableTipCardState extends State<_ExpandableTipCard> {
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 12.0, // Increased spacing
          horizontal: 16.0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: _toggleExpanded,
              child: Row(
                children: [
                  Icon(widget.icon, color: const Color(0xFF2E7D32), size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ),
                  Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Colors.grey.shade700,
                    size: 28,
                  ),
                ],
              ),
            ),
            if (_isExpanded) const Divider(height: 24), // Increased spacing
            if (_isExpanded)
              Padding(
                padding: const EdgeInsets.only(
                  top: 0,
                  left: 4,
                  right: 4,
                  bottom: 12, // Increased spacing
                ),
                child: widget.content,
              ),
          ],
        ),
      ),
    );
  }
}
