import 'package:flutter/material.dart';
import 'package:shelf_control/models/shopping_list_item_model.dart';
import 'package:shelf_control/models/shopping_list_model.dart';
import 'package:shelf_control/services/shopping_list_service.dart';
import 'listitemspage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart'; // Import provider
import 'package:shelf_control/services/firestore_service.dart'; // Import FirestoreService

// ===== Top-level enum =====
enum GenMode { budget, healthy }

class Viewalllist extends StatefulWidget {
  const Viewalllist({super.key});

  @override
  State<Viewalllist> createState() => _ViewAllListsPageState();
}

class _ViewAllListsPageState extends State<Viewalllist> {
  final Color headerGreen = const Color(0xFF2E7D32);
  final Color softCream = const Color(0xFFFFFBE6);
  final Color sep = const Color.fromARGB(255, 230, 230, 230);

  final ShoppingListService _shoppingListService = ShoppingListService();
  List<ShoppingListModel> _lists = [];
  String? _householdId;
  late FirestoreService _firestoreService; // Declare the service here

  // Listener for FirestoreService changes
  late VoidCallback _firestoreServiceListener;

  @override
  void initState() {
    super.initState();
    _firestoreService = Provider.of<FirestoreService>(context, listen: false); // Initialize here

    // Initialize the listener
    _firestoreServiceListener = () {
      if (_householdId != _firestoreService.selectedHouseholdId) {
        setState(() {
          _householdId = _firestoreService.selectedHouseholdId;
        });
        _fetchLists();
      }
    };

    // Add the listener
    _firestoreService.addListener(_firestoreServiceListener);

    // Initial fetch
    _fetchHouseholdAndLists();
  }

  @override
  void dispose() {
    // Remove the listener using the stored instance
    _firestoreService.removeListener(_firestoreServiceListener);
    super.dispose();
  }

  Future<void> _fetchHouseholdAndLists() async {
    _householdId = _firestoreService.selectedHouseholdId; // Get householdId from service
    _fetchLists();
  }

  Future<void> _fetchLists() async {
    if (_householdId != null) {
      var snapshot = await FirebaseFirestore.instance
          .collection('shoppingLists')
          .where('householdId', isEqualTo: _householdId)
          .get();
      if (!mounted) return;
      setState(() {
        _lists = snapshot.docs.map((doc) => ShoppingListModel.fromFirestore(doc)).toList();
      });
    }
  }

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
        _fetchLists();
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

                          ShoppingListModel? newList;
                          if (_householdId != null) {
                            newList = ShoppingListModel(
                              householdId: _householdId!,
                              name: name,
                              createdAt: DateTime.now(),
                              items: [],
                              type: 'Manual',
                              isActive: false,
                            );
                            DocumentReference docRef = await FirebaseFirestore.instance.collection('shoppingLists').add(newList.toFirestore());
                            newList.id = docRef.id; // Assign the Firestore ID to the model
                            _fetchLists();
                          }

                          Navigator.of(dialogCtx, rootNavigator: true).pop();
                          if (!mounted) return;

                          if (newList != null) {
                            final result = await Navigator.of(parentContext).push(
                              MaterialPageRoute(
                                builder: (_) => ListItemsPage(shoppingList: newList!),
                              ),
                            );
                            if (mounted) _handleListPageResult(result);
                          }
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

    GenMode mode = GenMode.budget;
    const double minBudget = 200;
    const double maxBudget = 1000; // Adjusted to a more realistic maximum for a single product
    double sliderValue = maxBudget; // Initialize sliderValue to maxBudget to avoid assertion error
    int numberOfItems = 10;
    final budgetCtrl = TextEditingController(
      text: sliderValue.toStringAsFixed(0),
    );
    final itemsCtrl = TextEditingController(text: numberOfItems.toString());

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
                    if (mode == GenMode.healthy) ...[
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Number of Items',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Colors.grey.shade800,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: itemsCtrl,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        decoration: InputDecoration(
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
                        ),
                        onChanged: (value) {
                          numberOfItems = int.tryParse(value) ?? 10;
                        },
                      ),
                    ],
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
                    String title = '';
                    IconData icon = Icons.list_alt_outlined; // Default icon

                    switch (mode) {
                      case GenMode.budget:
                        title = 'Budget ${formatPhp(sliderValue)}';
                        icon = Icons.account_balance_wallet_outlined;
                        break;
                      case GenMode.healthy:
                        title = 'Healthy Picks';
                        icon = Icons.eco_outlined;
                        break;
                    }

                    List<ShoppingListItemModel> generatedItems = [];
                    if (_householdId != null) {
                      switch (mode) {
                        case GenMode.budget:
                          generatedItems = await _shoppingListService.generateBudgetFriendlyList(_householdId!, sliderValue, numberOfItems: numberOfItems);
                          break;
                        case GenMode.healthy:
                          generatedItems = await _shoppingListService.generateHealthyOptionList(_householdId!, numberOfItems: numberOfItems);
                          break;
                      }
                    }

                    if (!mounted) return;

                    ShoppingListModel? newList;
                    if (_householdId != null) {
                      newList = ShoppingListModel(
                        householdId: _householdId!,
                        name: 'Auto: $title', // Add "Auto:" prefix for generated lists
                        createdAt: DateTime.now(),
                        items: generatedItems,
                        type: mode.name,
                        isActive: false,
                      );
                      // Save the new list to Firestore and get its ID
                      DocumentReference docRef = await FirebaseFirestore.instance.collection('shoppingLists').add(newList.toFirestore());
                      newList.id = docRef.id; // Assign the Firestore ID to the model
                      _fetchLists(); // Refresh the list view

                      Navigator.of(dialogCtx, rootNavigator: true).pop();
                      if (!mounted) return;

                      if (newList != null) {
                        final result = await Navigator.of(parentContext).push(
                          MaterialPageRoute(
                            builder: (_) => ListItemsPage(shoppingList: newList!),
                            settings: RouteSettings(
                              arguments: {
                                'seedItems': generatedItems,
                                'isGeneratedTemp': true,
                                'genMode': mode.name,
                                'budget': sliderValue,
                              },
                            ),
                          ),
                        );
                        if (mounted) _handleListPageResult(result);
                      }
                    }
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
                ..._lists.map((list) {
                  return _ListCard(
                    list: list,
                    createdText: 'Created ${_formatCreated(list.createdAt)}',
                    sep: sep,
                    headerGreen: headerGreen, // Pass headerGreen
                    onTap: () {
                      _openEditListDialog(list);
                    },
                    onChevronTap: () async {
                      final result = await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ListItemsPage(shoppingList: list),
                        ),
                      );
                      _handleListPageResult(result);
                    },
                    onActivate: () async {
                      if (_householdId != null && list.id != null) {
                        await _shoppingListService.setActiveShoppingList(_householdId!, list.id!);
                        _fetchLists();
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
  Future<void> _openEditListDialog(ShoppingListModel list) async {
    final nameCtrl = TextEditingController(text: list.name);
    IconData tempIcon = Icons.list_alt_outlined; // Default icon

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
                        text: _formatCreated(list.createdAt),
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
                        '${list.items.length} Items',
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
                    final newName = nameCtrl.text.trim();
                    if (newName.isNotEmpty && list.id != null) {
                      await FirebaseFirestore.instance.collection('shoppingLists').doc(list.id).update({'name': newName});
                      _fetchLists();
                    }
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
} // End of _ViewAllListsPageState class

class _ListCard extends StatelessWidget {
  const _ListCard({
    required this.list,
    required this.createdText,
    required this.sep,
    required this.onTap,
    required this.onChevronTap,
    required this.onActivate,
    required this.headerGreen,
  });

  final ShoppingListModel list;
  final String createdText;
  final Color sep;
  final VoidCallback onTap;
  final VoidCallback onChevronTap;
  final VoidCallback onActivate;
  final Color headerGreen;

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
                  child: Icon(Icons.list_alt_outlined, size: 26, color: Colors.grey.shade800),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        list.name,
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
                        '${list.items.length} Items',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    list.isActive ? Icons.shopping_cart : Icons.shopping_cart_checkout,
                    color: list.isActive ? headerGreen : Colors.grey,
                  ),
                  onPressed: onActivate,
                  tooltip: 'Set as Active List',
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
