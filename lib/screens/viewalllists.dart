import 'package:flutter/material.dart';
import 'listitemspage.dart';

// ===== Top-level enum =====
enum GenMode { recommended, budget, healthy }

class Viewalllist extends StatefulWidget {
  const Viewalllist({super.key});

  @override
  State<Viewalllist> createState() => _ViewAllListsPageState();
}

class _ViewAllListsPageState extends State<Viewalllist> {
  final Color headerGreen = const Color(0xFF2E7D32);
  final Color softCream = const Color(0xFFFFFBE6);
  final Color sep = const Color.fromARGB(255, 230, 230, 230);

  final _lists = <ListMeta>[
    ListMeta(
      title: 'Weekly Grocery',
      created: DateTime(2025, 8, 28),
      itemsCount: 10,
      icon: Icons.shopping_cart_outlined,
    ),
    ListMeta(
      title: "Sunday's Best",
      created: DateTime(2025, 7, 5),
      itemsCount: 69,
      icon: Icons.storefront_outlined,
    ),
  ];

  String _formatCreated(DateTime d) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  // ===== Common result handler from ListItemsPage =====
  void _handleListPageResult(dynamic result) {
    if (!mounted) return;
    if (result is Map && result['deleted'] == true) {
      final String? title = result['listTitle'] as String?;
      if (title != null) {
        setState(() {
          _lists.removeWhere((m) => m.title == title);
        });
      }
    } else if (result is bool && result == true) {
      // Backward-compat: if any older page returns just `true`,
      // we don't know which one—so we won't remove anything here.
    }
  }

  // ===== Icon picker =====
  Future<IconData?> _pickIcon(BuildContext context, IconData current) async {
    final choices = <IconData>[
      Icons.list_alt_outlined,
      Icons.shopping_cart_outlined,
      Icons.storefront_outlined,
      Icons.local_mall_outlined,
      Icons.fastfood_outlined,
      Icons.lunch_dining_outlined,
      Icons.local_grocery_store_outlined,
      Icons.kitchen_outlined,
      Icons.inventory_2_outlined,
      Icons.event_note_outlined,
      Icons.receipt_long_outlined,
      Icons.assignment_outlined,
      Icons.food_bank_outlined,
      Icons.set_meal_outlined,
      Icons.ramen_dining_outlined,
    ];

    return showModalBottomSheet<IconData>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: false,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetCtx) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Choose an icon',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 320,
                  child: GridView.builder(
                    itemCount: choices.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 5,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                        ),
                    itemBuilder: (context, i) {
                      final ic = choices[i];
                      final selected =
                          ic.codePoint == current.codePoint &&
                          ic.fontFamily == current.fontFamily;
                      return InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => Navigator.of(sheetCtx).pop(ic),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: selected
                                  ? headerGreen
                                  : Colors.grey.shade300,
                              width: selected ? 2 : 1,
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              ic,
                              size: 26,
                              color: selected
                                  ? headerGreen
                                  : Colors.grey.shade800,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ===== CREATE LIST pop-up =====
  Future<void> _showCreateListDialog() async {
    final parentContext = context;
    final nameCtrl = TextEditingController();
    IconData chosenIcon = Icons.list_alt_outlined;

    await showDialog<void>(
      context: parentContext,
      useRootNavigator: true,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            final enabled = nameCtrl.text.trim().isNotEmpty;

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              title: Text(
                'Create List',
                style: TextStyle(
                  color: headerGreen,
                  fontWeight: FontWeight.w800,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEEEEEE),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            chosenIcon,
                            size: 30,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: () async {
                            final pick = await _pickIcon(dialogCtx, chosenIcon);
                            if (pick != null) setLocal(() => chosenIcon = pick);
                          },
                          icon: const Icon(Icons.edit_outlined),
                          label: const Text('Change Icon'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: headerGreen,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameCtrl,
                      autofocus: true,
                      onChanged: (_) => setLocal(() {}),
                      decoration: InputDecoration(
                        hintText: 'Enter list name',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: sep),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () =>
                      Navigator.of(dialogCtx, rootNavigator: true).pop(),
                  child: Text('Cancel', style: TextStyle(color: headerGreen)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: enabled
                        ? headerGreen
                        : Colors.grey.shade400,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: enabled
                      ? () async {
                          final name = nameCtrl.text.trim();
                          if (!mounted) return;

                          final newMeta = ListMeta(
                            title: name,
                            created: DateTime.now(),
                            itemsCount: 0,
                            icon: chosenIcon,
                          );
                          setState(() => _lists.insert(0, newMeta));

                          Navigator.of(dialogCtx, rootNavigator: true).pop();

                          final result = await Navigator.of(parentContext).push(
                            MaterialPageRoute(
                              builder: (_) => ListItemsPage(listTitle: name),
                            ),
                          );

                          // If the list was deleted from inside ListItemsPage, remove it here.
                          if (mounted) _handleListPageResult(result);
                        }
                      : null,
                  child: const Text('Continue'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ===== GENERATE LIST pop-up =====
  Future<void> _showGenerateListDialog() async {
    final parentContext = context;

    GenMode mode = GenMode.recommended;
    double sliderValue = 1500;
    const double minBudget = 200;
    const double maxBudget = 10000;
    final budgetCtrl = TextEditingController(
      text: sliderValue.toStringAsFixed(0),
    );

    String formatPhp(double v) => '₱${v.toStringAsFixed(0)}';

    await showDialog<void>(
      context: parentContext,
      useRootNavigator: true,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            void syncFromText() {
              final raw = budgetCtrl.text.replaceAll(',', '').trim();
              final parsed = double.tryParse(raw);
              if (parsed != null) {
                final clamped = parsed.clamp(minBudget, maxBudget).toDouble();
                setLocal(() => sliderValue = clamped);
                budgetCtrl.text = clamped.toStringAsFixed(0);
                budgetCtrl.selection = TextSelection.fromPosition(
                  TextPosition(offset: budgetCtrl.text.length),
                );
              }
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              title: Text(
                'Generate Shopping List',
                style: TextStyle(
                  color: headerGreen,
                  fontWeight: FontWeight.w800,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _RadioTile<GenMode>(
                      value: GenMode.recommended,
                      groupValue: mode,
                      onChanged: (v) => setLocal(() => mode = v!),
                      title: 'Most Recommended',
                      subtitle: 'Curated picks based on popularity.',
                      icon: Icons.recommend_outlined,
                      headerGreen: headerGreen,
                      sep: sep,
                    ),
                    const SizedBox(height: 8),
                    _RadioTile<GenMode>(
                      value: GenMode.budget,
                      groupValue: mode,
                      onChanged: (v) => setLocal(() => mode = v!),
                      title: 'Budget Friendly',
                      subtitle: 'Generate a list that fits your budget.',
                      icon: Icons.account_balance_wallet_outlined,
                      headerGreen: headerGreen,
                      sep: sep,
                    ),
                    if (mode == GenMode.budget) ...[
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Budget',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Colors.grey.shade800,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Slider(
                              value: sliderValue,
                              min: minBudget,
                              max: maxBudget,
                              divisions: (maxBudget - minBudget).toInt(),
                              label: formatPhp(sliderValue),
                              activeColor: headerGreen,
                              onChanged: (v) {
                                setLocal(() => sliderValue = v);
                                budgetCtrl.text = v.toStringAsFixed(0);
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 110,
                            child: TextField(
                              controller: budgetCtrl,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              onSubmitted: (_) => syncFromText(),
                              decoration: InputDecoration(
                                prefixText: '₱',
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 10,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(color: sep),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(color: sep),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(
                                    color: headerGreen,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          '${formatPhp(minBudget)} – ${formatPhp(maxBudget)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    _RadioTile<GenMode>(
                      value: GenMode.healthy,
                      groupValue: mode,
                      onChanged: (v) => setLocal(() => mode = v!),
                      title: 'Healthy Option',
                      subtitle: 'Focus on nutrient-dense picks.',
                      icon: Icons.eco_outlined,
                      headerGreen: headerGreen,
                      sep: sep,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () =>
                      Navigator.of(dialogCtx, rootNavigator: true).pop(),
                  child: Text('Cancel', style: TextStyle(color: headerGreen)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: headerGreen,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    // === Titles WITHOUT the "Auto:" prefix ===
                    String title = 'Most Recommended';
                    IconData icon = Icons.recommend_outlined;

                    switch (mode) {
                      case GenMode.recommended:
                        title = 'Most Recommended';
                        icon = Icons.recommend_outlined;
                        break;
                      case GenMode.budget:
                        title = 'Budget ${formatPhp(sliderValue)}';
                        icon = Icons.account_balance_wallet_outlined;
                        break;
                      case GenMode.healthy:
                        title = 'Healthy Picks';
                        icon = Icons.eco_outlined;
                        break;
                    }

                    // === Generate TEMP items grouped by their categories ===
                    final tempItems = _generateItemsForMode(
                      mode,
                      budget: sliderValue,
                    );

                    if (!mounted) return;

                    final newMeta = ListMeta(
                      title: title,
                      created: DateTime.now(),
                      itemsCount: tempItems.length,
                      icon: icon,
                    );

                    setState(() => _lists.insert(0, newMeta));
                    Navigator.of(dialogCtx, rootNavigator: true).pop();

                    // Pass seed items to ListItemsPage using RouteSettings.arguments
                    final result = await Navigator.of(parentContext).push(
                      MaterialPageRoute(
                        builder: (_) => ListItemsPage(listTitle: title),
                        settings: RouteSettings(
                          arguments: {
                            'seedItems': tempItems,
                            'isGeneratedTemp': true,
                            'genMode': mode.name,
                            'budget': sliderValue,
                          },
                        ),
                      ),
                    );

                    if (mounted) _handleListPageResult(result);
                  },
                  child: const Text('Generate'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ===== TEMP item generator (keeps items under proper categories) =====
  List<GenItem> _generateItemsForMode(GenMode mode, {double budget = 0}) {
    final base = <GenItem>[
      GenItem(
        name: 'Orange Juice',
        brand: 'Minute Maid',
        grams: 1000,
        qty: 1,
        category: 'Beverages',
      ),
      GenItem(
        name: 'Wheat Bread',
        brand: 'Gardenia',
        grams: 600,
        qty: 1,
        category: 'Baked Goods',
      ),
      GenItem(
        name: 'Mayonnaise',
        brand: 'Lady’s Choice',
        grams: 470,
        qty: 1,
        category: 'Condiments',
      ),
      GenItem(
        name: 'Tuna Flakes',
        brand: 'Century',
        grams: 180,
        qty: 2,
        category: 'Canned Goods',
      ),
      GenItem(
        name: 'Fresh Milk',
        brand: 'Cowhead',
        grams: 1000,
        qty: 1,
        category: 'Dairy',
      ),
      GenItem(
        name: 'Bananas',
        brand: 'Local',
        grams: 1000,
        qty: 1,
        category: 'Produce',
      ),
      GenItem(
        name: 'Crackers',
        brand: 'SkyFlakes',
        grams: 250,
        qty: 1,
        category: 'Snacks',
      ),
    ];

    switch (mode) {
      case GenMode.recommended:
        return base;
      case GenMode.budget:
        if (budget <= 800) {
          return [
            GenItem(
              name: 'Instant Coffee',
              brand: 'Great Taste',
              grams: 50,
              qty: 1,
              category: 'Beverages',
            ),
            GenItem(
              name: 'Pandesal Pack',
              brand: 'Local Bakery',
              grams: 300,
              qty: 1,
              category: 'Baked Goods',
            ),
            GenItem(
              name: 'Sardines',
              brand: '555',
              grams: 155,
              qty: 2,
              category: 'Canned Goods',
            ),
            GenItem(
              name: 'Bananas',
              brand: 'Local',
              grams: 800,
              qty: 1,
              category: 'Produce',
            ),
            GenItem(
              name: 'Soy Sauce',
              brand: 'Datu Puti',
              grams: 350,
              qty: 1,
              category: 'Condiments',
            ),
          ];
        } else if (budget <= 2000) {
          return [
            ...base.where((x) => x.category != 'Snacks'),
            GenItem(
              name: 'Rice',
              brand: 'Sinandomeng',
              grams: 2000,
              qty: 1,
              category: 'Other',
            ),
          ];
        } else {
          return [
            ...base,
            GenItem(
              name: 'Greek Yogurt',
              brand: 'Almarai',
              grams: 500,
              qty: 1,
              category: 'Dairy',
            ),
            GenItem(
              name: 'Mixed Veggies',
              brand: 'Del Monte',
              grams: 400,
              qty: 1,
              category: 'Canned Goods',
            ),
            GenItem(
              name: 'Granola',
              brand: 'Quaker',
              grams: 380,
              qty: 1,
              category: 'Snacks',
            ),
          ];
        }
      case GenMode.healthy:
        return [
          GenItem(
            name: 'Rolled Oats',
            brand: 'Quaker',
            grams: 800,
            qty: 1,
            category: 'Baked Goods',
          ),
          GenItem(
            name: 'Low-Fat Milk',
            brand: 'Bear Brand',
            grams: 1000,
            qty: 1,
            category: 'Dairy',
          ),
          GenItem(
            name: 'Chicken Breast',
            brand: 'Fresh Cut',
            grams: 1000,
            qty: 1,
            category: 'Other',
          ),
          GenItem(
            name: 'Spinach',
            brand: 'Local',
            grams: 300,
            qty: 1,
            category: 'Produce',
          ),
          GenItem(
            name: 'Olive Oil',
            brand: 'Bertolli',
            grams: 500,
            qty: 1,
            category: 'Condiments',
          ),
          GenItem(
            name: 'Tuna in Water',
            brand: 'Century',
            grams: 180,
            qty: 2,
            category: 'Canned Goods',
          ),
        ];
    }
  }

  // ===== UI =====
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: softCream,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: headerGreen,
            padding: const EdgeInsets.fromLTRB(8, 48, 8, 14),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 6),
                const Text(
                  'Your List',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, thickness: 1, color: sep),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
              children: [
                ..._lists.asMap().entries.map((entry) {
                  final m = entry.value;
                  return _ListCard(
                    meta: m,
                    createdText: 'Created ${_formatCreated(m.created)}',
                    sep: sep,
                    onTap: () {
                      _openEditListDialog(m);
                    },
                    onChevronTap: () async {
                      final result = await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ListItemsPage(listTitle: m.title),
                        ),
                      );
                      _handleListPageResult(result);
                    },
                  );
                }),
                const SizedBox(height: 6),
                _CreateListRow(sep: sep, onTap: _showCreateListDialog),
              ],
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(right: 12, bottom: 12),
        child: ElevatedButton.icon(
          onPressed: _showGenerateListDialog,
          icon: const Icon(Icons.add),
          label: const Text('Generate Shopping List'),
          style: ElevatedButton.styleFrom(
            backgroundColor: headerGreen,
            foregroundColor: Colors.white,
            elevation: 3,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
          ),
        ),
      ),
    );
  }

  // ===== Edit dialog used when tapping a card =====
  Future<void> _openEditListDialog(ListMeta meta) async {
    final nameCtrl = TextEditingController(text: meta.title);
    IconData tempIcon = meta.icon;

    await showDialog<void>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              title: Text(
                'Edit List',
                style: TextStyle(
                  color: headerGreen,
                  fontWeight: FontWeight.w800,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEEEEEE),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            tempIcon,
                            size: 30,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: () async {
                            final pick = await _pickIcon(dialogCtx, tempIcon);
                            if (pick != null) setLocal(() => tempIcon = pick);
                          },
                          icon: const Icon(Icons.edit_outlined),
                          label: const Text('Change Icon'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: headerGreen,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameCtrl,
                      decoration: InputDecoration(
                        hintText: 'Enter list name',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: sep),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Date created',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: TextEditingController(
                        text: _formatCreated(meta.created),
                      ),
                      readOnly: true,
                      enabled: false,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: sep),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Total items in pantry list',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: sep),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${meta.itemsCount} Items',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () =>
                      Navigator.of(dialogCtx, rootNavigator: true).pop(),
                  child: Text('Cancel', style: TextStyle(color: headerGreen)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: headerGreen,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    final newName = nameCtrl.text.trim();
                    setState(() {
                      if (newName.isNotEmpty) meta.title = newName;
                      meta.icon = tempIcon;
                    });
                    Navigator.of(dialogCtx, rootNavigator: true).pop();
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

// ===== Model =====
class ListMeta {
  String title;
  final DateTime created;
  int itemsCount;
  IconData icon;
  ListMeta({
    required this.title,
    required this.created,
    required this.itemsCount,
    required this.icon,
  });
}

// ===== TEMP item model for generator =====
class GenItem {
  final String name;
  final String brand;
  final int grams; // use grams or mL depending on item
  final int qty;
  final String category; // MUST match your app categories

  const GenItem({
    required this.name,
    required this.brand,
    required this.grams,
    required this.qty,
    required this.category,
  });
}

// ===== Card widgets =====
class _ListCard extends StatelessWidget {
  const _ListCard({
    required this.meta,
    required this.createdText,
    required this.sep,
    required this.onTap,
    required this.onChevronTap,
  });

  final ListMeta meta;
  final String createdText;
  final Color sep;
  final VoidCallback onTap;
  final VoidCallback onChevronTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: sep),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEEEEE),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(meta.icon, size: 26, color: Colors.grey.shade800),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        meta.title,
                        style: const TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        createdText,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Colors.grey.shade700,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${meta.itemsCount} Items',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: onChevronTap,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CreateListRow extends StatelessWidget {
  const _CreateListRow({required this.sep, required this.onTap});

  final Color sep;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: sep, style: BorderStyle.solid),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Icon(Icons.add_circle_outline_rounded),
                SizedBox(width: 10),
                Text(
                  'Create List',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RadioTile<T> extends StatelessWidget {
  const _RadioTile({
    required this.value,
    required this.groupValue,
    required this.onChanged,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.headerGreen,
    required this.sep,
  });

  final T value;
  final T groupValue;
  final ValueChanged<T?> onChanged;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color headerGreen;
  final Color sep;

  @override
  Widget build(BuildContext context) {
    final bool selected = value == groupValue;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => onChanged(value),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? headerGreen : sep, width: 1.5),
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFEEEEEE),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: selected ? headerGreen : Colors.grey.shade800,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: Colors.grey.shade900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
            Radio<T>(
              value: value,
              groupValue: groupValue,
              activeColor: headerGreen,
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }
}
