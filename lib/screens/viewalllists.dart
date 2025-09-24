import 'package:flutter/material.dart';
import 'listitemspage.dart';
import 'package:shelf_control/services/ai_budget_service.dart';
import 'package:shelf_control/services/budget_generator.dart'; // reuse CSV parsing
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

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
  final Map<String, List<Map<String, dynamic>>> _listSeeds = {};

  static const _kListsKey = 'view_all_lists_meta_v1';
  static const _kSeedsKey = 'view_all_lists_seeds_v1';

  @override
  void initState() {
    super.initState();
    _loadState(); // ✅ restores saved lists & seeds
  }

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

  int _parseGramsFromSize(String? sizeText) {
    if (sizeText == null) return 0;
    final m = RegExp(
      r'(\d+(?:\.\d+)?)(g|kg|ml|l|oz)',
      caseSensitive: false,
    ).firstMatch(sizeText);
    if (m == null) return 0;
    final value = double.tryParse(m.group(1)!) ?? 0.0;
    final unit = (m.group(2) ?? '').toLowerCase();
    if (unit == 'kg') return (value * 1000).round();
    if (unit == 'l') return (value * 1000).round(); // treat ml-like for display
    if (unit == 'oz') return (value * 28.3495).round();
    // g or ml
    return value.round();
  }

  Future<void> _saveState() async {
    final prefs = await SharedPreferences.getInstance();

    // encode _lists
    final listsJson = _lists.map((m) => m.toJson()).toList();
    await prefs.setString(_kListsKey, jsonEncode(listsJson));

    // encode _listSeeds
    await prefs.setString(_kSeedsKey, jsonEncode(_listSeeds));
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();

    final listsStr = prefs.getString(_kListsKey);
    if (listsStr != null && listsStr.isNotEmpty) {
      final decoded = jsonDecode(listsStr);
      if (decoded is List) {
        _lists
          ..clear()
          ..addAll(
            decoded.whereType<Map>().map(
              (m) => ListMetaCodec.fromJson(m.cast<String, dynamic>()),
            ),
          );
      }
    }

    final seedsStr = prefs.getString(_kSeedsKey);
    if (seedsStr != null && seedsStr.isNotEmpty) {
      final decoded = jsonDecode(seedsStr);
      if (decoded is Map) {
        _listSeeds
          ..clear()
          ..addAll(
            decoded.map(
              (k, v) => MapEntry(
                k.toString(),
                (v as List)
                    .whereType<Map>()
                    .map((e) => Map<String, dynamic>.from(e))
                    .toList(),
              ),
            ),
          );
      }
    }

    if (mounted) setState(() {});
  }

  // ===== Common result handler from ListItemsPage =====
  Future<void> _handleListPageResult(dynamic result) async {
    if (!mounted) return;

    if (result is Map && result['deleted'] == true) {
      final String? title = result['listTitle'] as String?;
      if (title != null) {
        setState(() {
          // Remove from the list of metas
          _lists.removeWhere((m) => m.title == title);
          // Also remove the saved seed items for this list
          _listSeeds.remove(title);
        });

        // 🔴 Persist the new state so it stays deleted when you come back
        await _saveState();
      }
    } else if (result is bool && result == true) {
      // Backward-compat: older pages may return just `true`.
      // If you ever need to infer which one, do it here.
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
                          await _saveState();

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
    final budgetFormKey = GlobalKey<FormState>();

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

            void _applyBudgetFromInt(int v) {
              final clamped = v.clamp(200, 10000);
              if (clamped != sliderValue.toInt()) {
                sliderValue = clamped.toDouble();
              }
              final txt = clamped.toString();
              if (budgetCtrl.text != txt) {
                budgetCtrl.text = txt;
                budgetCtrl.selection = TextSelection.collapsed(
                  offset: txt.length,
                );
              }
              setLocal(() {});
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
                            child: TextFormField(
                              // ✅ must be TextFormField
                              controller: budgetCtrl,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              onChanged: (txt) {
                                final parsed = int.tryParse(txt);
                                if (parsed != null) {
                                  _applyBudgetFromInt(parsed);
                                }
                              },
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
                              autovalidateMode: AutovalidateMode
                                  .onUserInteraction, // ✅ works now
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Enter budget';
                                }
                                final parsed = int.tryParse(value.trim());
                                if (parsed == null) return 'Numbers only';
                                if (parsed <= 0) return 'Must be > 0';
                                if (parsed < 200 || parsed > 10000) {
                                  return '200 – 10000 only';
                                }
                                return null;
                              },
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
                    final tempItems = await _generateItemsForMode(
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

                    // Save the seed items for this list
                    _listSeeds[title] = tempItems
                        .map(
                          (g) => {
                            'id': g.name.toLowerCase().replaceAll(
                              RegExp(r'[^a-z0-9]+'),
                              '-',
                            ),
                            'name': g.name,
                            'brand': g.brand.isEmpty ? null : g.brand,
                            'category': g.category,
                            'sizeText': g.grams > 0 ? '${g.grams}g' : null,
                            'qty': g.qty,
                            'price': g.price,
                          },
                        )
                        .toList();

                    // 🔴 ADD THIS LINE (persist meta + seeds)
                    await _saveState();

                    Navigator.of(dialogCtx, rootNavigator: true).pop();

                    final result = await Navigator.of(parentContext).push(
                      MaterialPageRoute(
                        builder: (_) => ListItemsPage(listTitle: title),
                        settings: RouteSettings(
                          arguments: {
                            'seedItems': _listSeeds[title],
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
  Future<List<GenItem>> _generateItemsForMode(
    GenMode mode, {
    double budget = 0,
  }) async {
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
        // 🔥 Use CSV-driven budget selection
        final picks = await BudgetGenerator.pickWithinBudget(budget: budget);
        // Map BudgetGenItem -> GenItem your UI expects
        return picks.map((p) {
          return GenItem(
            name: p.name,
            brand: p.brand ?? '',
            grams: _parseGramsFromSize(p.sizeText), // helper below
            qty: p.qty,
            category: p.category,
            price: p.price,
          );
        }).toList();
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
                      final seeds = _listSeeds[m.title];
                      final result = await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ListItemsPage(listTitle: m.title),
                          settings: seeds != null
                              ? RouteSettings(arguments: {'seedItems': seeds})
                              : null,
                        ),
                      );
                      _handleListPageResult(result);
                      if (result is Map &&
                          result['listTitle'] == m.title &&
                          result['seedItems'] is List) {
                        _listSeeds[m.title] = List<Map<String, dynamic>>.from(
                          (result['seedItems'] as List).cast<Map>(),
                        );
                        await _saveState(); // ✅ persist latest edits
                      }
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
                  onPressed: () async {
                    final oldTitle = meta.title;
                    final newName = nameCtrl.text.trim();

                    setState(() {
                      if (newName.isNotEmpty) meta.title = newName;
                      meta.icon = tempIcon;
                    });

                    final newTitle = meta.title;
                    if (oldTitle != newTitle &&
                        _listSeeds.containsKey(oldTitle)) {
                      _listSeeds[newTitle] = _listSeeds.remove(oldTitle)!;
                    }

                    await _saveState(); // persist rename + seeds

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

extension ListMetaCodec on ListMeta {
  Map<String, dynamic> toJson() => {
    'title': title,
    'created': created.toIso8601String(),
    'itemsCount': itemsCount,
    'icon': icon.codePoint, // store icon as int
  };

  static ListMeta fromJson(Map<String, dynamic> m) => ListMeta(
    title: (m['title'] ?? '').toString(),
    created:
        DateTime.tryParse((m['created'] ?? '').toString()) ?? DateTime.now(),
    itemsCount: (m['itemsCount'] is int)
        ? m['itemsCount'] as int
        : int.tryParse('${m['itemsCount']}') ?? 0,
    icon: IconData(
      (m['icon'] as int?) ?? Icons.list_alt_outlined.codePoint,
      fontFamily: 'MaterialIcons',
    ),
  );
}

// ===== TEMP item model for generator =====
class GenItem {
  final String name;
  final String brand;
  final int grams; // use grams or mL depending on item
  final int qty;
  final String category; // MUST match your app categories
  final double? price; // ✅ NEW

  const GenItem({
    required this.name,
    required this.brand,
    required this.grams,
    required this.qty,
    required this.category,
    this.price, // ✅ NEW
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
            color: const Color.fromARGB(10, 0, 0, 0),
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
