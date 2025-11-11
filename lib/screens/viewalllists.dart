import 'package:flutter/material.dart';
import 'package:shelf_control/models/shopping_list_item_model.dart';
import 'package:shelf_control/models/shopping_list_model.dart';
import 'package:shelf_control/services/shopping_list_service.dart';
import 'listitemspage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart'; // Import provider
import 'package:shelf_control/services/firestore_service.dart'; // Import FirestoreService
import 'package:logger/logger.dart'; // Import the logger package
import 'package:shelf_control/models/user_prefs_model.dart'; // Import UserPrefsModel

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

  bool _isMultiSelecting = false;
  final Set<String> _selectedListIds = {};

  static const List<IconData> _iconChoices = <IconData>[
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

  static IconData _getIconFromCodePoint(int? codePoint) {
    if (codePoint == null) return Icons.list_alt_outlined;
    final iconMap = {
      Icons.list_alt_outlined.codePoint: Icons.list_alt_outlined,
      Icons.shopping_cart_outlined.codePoint: Icons.shopping_cart_outlined,
      Icons.storefront_outlined.codePoint: Icons.storefront_outlined,
      Icons.local_mall_outlined.codePoint: Icons.local_mall_outlined,
      Icons.fastfood_outlined.codePoint: Icons.fastfood_outlined,
      Icons.lunch_dining_outlined.codePoint: Icons.lunch_dining_outlined,
      Icons.local_grocery_store_outlined.codePoint:
          Icons.local_grocery_store_outlined,
      Icons.kitchen_outlined.codePoint: Icons.kitchen_outlined,
      Icons.inventory_2_outlined.codePoint: Icons.inventory_2_outlined,
      Icons.event_note_outlined.codePoint: Icons.event_note_outlined,
      Icons.receipt_long_outlined.codePoint: Icons.receipt_long_outlined,
      Icons.assignment_outlined.codePoint: Icons.assignment_outlined,
      Icons.food_bank_outlined.codePoint: Icons.food_bank_outlined,
      Icons.set_meal_outlined.codePoint: Icons.set_meal_outlined,
      Icons.ramen_dining_outlined.codePoint: Icons.ramen_dining_outlined,
    };
    return iconMap[codePoint] ?? Icons.list_alt_outlined;
  }

  late final ShoppingListService _shoppingListService;
  String? _householdId;
  late FirestoreService _firestoreService; // Declare the service here
  bool _isLoading = false; // New state variable for loading indicator
  final Logger _logger = Logger(); // Initialize logger
  Stream<List<ShoppingListModel>>? _listsStream;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _firestoreService = Provider.of<FirestoreService>(context); // Initialize _firestoreService
    _shoppingListService = ShoppingListService(firestoreService: _firestoreService);
    if (_firestoreService.selectedHouseholdId != _householdId) {
      setState(() {
        _householdId = _firestoreService.selectedHouseholdId;
        if (_householdId != null) {
          _listsStream = _shoppingListService.streamShoppingLists(_householdId!);
        } else {
          _listsStream = Stream.value([]);
        }
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
    return '${months[d.month - 1]} ${d.day}, ${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  // ===== Common result handler from ListItemsPage =====
  void _handleListPageResult(dynamic result) {
    // No longer needed with StreamBuilder, but kept for compatibility
    // if other pages rely on it.
  }

  void _toggleMultiSelecting() {
    setState(() {
      _isMultiSelecting = !_isMultiSelecting;
      if (!_isMultiSelecting) {
        _selectedListIds.clear();
      }
    });
  }

  Future<void> _confirmDeleteSelectedLists() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _DeleteConfirmDialog(
        headerGreen: headerGreen,
        title: 'Delete selected lists',
        message: 'Are you sure you want to delete ${_selectedListIds.length} selected shopping list(s)?',
      ),
    );

    if (confirmed == true && mounted) {
      if (_householdId != null) {
        for (final listId in _selectedListIds) {
          await _shoppingListService.deleteShoppingList(listId);
          // If this was the active list, clear shared store safely
          final store = MainShoppingListStore.instance;
          if (store.currentListTitle == listId) { // Assuming currentListTitle stores the ID
            store.clearMain();
          }
        }
        setState(() {
          _selectedListIds.clear();
          _isMultiSelecting = false;
        });
      }

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => _SuccessDialog(
          headerGreen: headerGreen,
          title: 'Success!',
          message: '${_selectedListIds.length} shopping list(s) deleted.',
        ),
      );
    }
  }

  // ===== Icon picker =====
  Future<IconData?> _pickIcon(BuildContext context, IconData current) async {
    final choices = _ViewAllListsPageState._iconChoices;

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
                            _logger.d('Creating manual list for householdId: $_householdId');
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

                            // Save items to subcollection
                            for (var item in newList.items) {
                              await _shoppingListService.addShoppingListItem(newList.id!, item);
                            }
                          } else {
                            _logger.e('Household ID is null, cannot create manual list.');
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
    double budgetSliderValue = maxBudget; // Initialize sliderValue to maxBudget to avoid assertion error
    int numberOfItems = 15; // Default to 15 items
    final budgetCtrl = TextEditingController(
      text: budgetSliderValue.toStringAsFixed(0),
    );
    final numberOfItemsCtrl = TextEditingController(
      text: numberOfItems.toString(),
    );
    const int minItems = 1;
    const int maxItems = 15;

    String formatPhp(double v) => '₱${v.toStringAsFixed(0)}';

    await showDialog<void>(
      context: parentContext,
      useRootNavigator: true,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            void syncBudgetFromText() {
              final raw = budgetCtrl.text.replaceAll(',', '').trim();
              final parsed = double.tryParse(raw);
              if (parsed != null) {
                final clamped = parsed.clamp(minBudget, maxBudget).toDouble();
                setLocal(() => budgetSliderValue = clamped);
                budgetCtrl.text = clamped.toStringAsFixed(0);
                budgetCtrl.selection = TextSelection.fromPosition(
                  TextPosition(offset: budgetCtrl.text.length),
                );
              }
            }

            void syncNumberOfItemsFromText() {
              final raw = numberOfItemsCtrl.text.trim();
              final parsed = int.tryParse(raw);
              if (parsed != null) {
                final clamped = parsed.clamp(minItems, maxItems);
                setLocal(() => numberOfItems = clamped);
                numberOfItemsCtrl.text = clamped.toString();
                numberOfItemsCtrl.selection = TextSelection.fromPosition(
                  TextPosition(offset: numberOfItemsCtrl.text.length),
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
                              value: budgetSliderValue,
                              min: minBudget,
                              max: maxBudget,
                              divisions: (maxBudget - minBudget).toInt(),
                              label: formatPhp(budgetSliderValue),
                              activeColor: headerGreen,
                              onChanged: (v) {
                                setLocal(() => budgetSliderValue = v);
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
                              onSubmitted: (_) => syncBudgetFromText(),
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
                    const SizedBox(height: 16),
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
                    Row(
                      children: [
                        Expanded(
                          child: Slider(
                            value: numberOfItems.toDouble(),
                            min: minItems.toDouble(),
                            max: maxItems.toDouble(),
                            divisions: (maxItems - minItems),
                            label: numberOfItems.toString(),
                            activeColor: headerGreen,
                            onChanged: (v) {
                              setLocal(() => numberOfItems = v.toInt());
                              numberOfItemsCtrl.text = v.toInt().toString();
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 80,
                          child: TextField(
                            controller: numberOfItemsCtrl,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            onSubmitted: (_) => syncNumberOfItemsFromText(),
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
                        '$minItems – $maxItems items',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
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
                  onPressed: _isLoading
                      ? null // Disable button when loading
                      : () async {
                          setLocal(() => _isLoading = true); // Start loading
                          // === Titles WITHOUT the "Auto:" prefix ===
                          String title = '';
                          IconData icon = Icons.list_alt_outlined; // Default icon
                          List<ShoppingListItemModel> generatedItems = []; // Declare here

                          if (_householdId != null && _firestoreService.userId != null) {
                            final UserPrefs? userPrefs = await _firestoreService.getUserPrefs(
                              userId: _firestoreService.userId!,
                              householdId: _householdId!,
                            );
                            final bool hasHistory = await _firestoreService.hasShoppingHistory(_householdId!);

                            switch (mode) {
                              case GenMode.budget:
                                title = 'Budget ${formatPhp(budgetSliderValue)}';
                                icon = Icons.account_balance_wallet_outlined;
                                generatedItems = await _shoppingListService.generateBudgetFriendlyList(
                                  _householdId!,
                                  budgetSliderValue,
                                  numberOfItems: numberOfItems,
                                  useHistory: hasHistory,
                                );
                                break;
                              case GenMode.healthy:
                                title = 'Healthy Option'; // Add title for healthy mode
                                icon = Icons.eco_outlined; // Add icon for healthy mode
                                generatedItems = await _shoppingListService.generateHealthyOptionList(
                                  _householdId!,
                                  numberOfItems: numberOfItems,
                                  categories: ['Dairy', 'Bakery'], // Reverted to specific healthy categories
                                  useHistory: hasHistory,
                                  userPrefs: userPrefs,
                                );
                                break;
                            }
                          }

                          if (!ctx.mounted) return;
                          setLocal(() => _isLoading = false); // Stop loading

                          ShoppingListModel? newList;
                          if (_householdId != null) {
                            _logger.d('Generating list for householdId: $_householdId');
                            newList = ShoppingListModel(
                              householdId: _householdId!,
                              name: 'Auto: $title', // Add "Auto:" prefix for generated lists
                              createdAt: DateTime.now(),
                              items: generatedItems,
                              type: mode.name,
                              isActive: true, // Automatically set as active
                              iconCodePoint: icon.codePoint, // Assign icon code point
                              iconFontFamily: icon.fontFamily, // Assign icon font family
                            );
                            // Save the new list to Firestore and get its ID
                            DocumentReference docRef = await FirebaseFirestore.instance.collection('shoppingLists').add(newList.toFirestore());
                            newList.id = docRef.id; // Assign the Firestore ID to the model

                            // Save generated items to subcollection
                            for (var item in generatedItems) {
                              await _shoppingListService.addShoppingListItem(newList.id!, item);
                            }
                          } else {
                            _logger.e('Household ID is null, cannot generate manual list.');
                          }

                          if (newList != null && newList.id != null) {
                            // Set this new list as the active shopping list for the household
                            await _shoppingListService.setActiveShoppingList(_householdId!, newList.id!);

                            if (!dialogCtx.mounted) return;
                            Navigator.of(dialogCtx, rootNavigator: true).pop();
                            
                            // Show success dialog briefly
                            await showDialog<void>(
                              context: parentContext,
                              barrierDismissible: false,
                              builder: (_) => _SuccessDialog(
                                headerGreen: headerGreen,
                                title: 'List Generated!',
                                message: 'Your new shopping list has been created.',
                              ),
                            );

                            // Navigate to the new list's detail page
                            if (newList != null) { // Ensure newList is not null before navigating
                              await Navigator.of(parentContext).push(
                                MaterialPageRoute(
                                  builder: (_) => ListItemsPage(shoppingList: newList!),
                                  settings: RouteSettings(
                                    arguments: {
                                      'seedItems': generatedItems,
                                      'isGeneratedTemp': true,
                                      'genMode': mode.name,
                                      'budget': budgetSliderValue,
                                    },
                                  ),
                                ),
                              );
                            } else {
                              _logger.e('Generated list is null, cannot navigate.');
                            }
                          } else {
                            _logger.e('Generated list is null or has no ID, cannot set as active or navigate.');
                            if (!dialogCtx.mounted) return;
                            Navigator.of(dialogCtx, rootNavigator: true).pop(); // Dismiss dialog even if list creation failed
                          }
                          if (!ctx.mounted) return;
                          setLocal(() => _isLoading = false); // Stop loading
                        },
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Generate'),
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
                if (_isMultiSelecting)
                  IconButton(
                    tooltip: 'Delete selected lists',
                    icon: const Icon(Icons.delete_outline, color: Colors.white),
                    onPressed: _selectedListIds.isEmpty ? null : _confirmDeleteSelectedLists,
                  ),
              ],
            ),
          ),
          Divider(height: 1, thickness: 1, color: sep),
          Expanded(
            child: StreamBuilder<List<ShoppingListModel>>(
              stream: _listsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'No shopping lists found.',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                          const SizedBox(height: 10),
                          _CreateListRow(sep: sep, onTap: _showCreateListDialog),
                        ],
                      ),
                    ),
                  );
                }

                final lists = snapshot.data!;

                return ListView(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
                  children: [
                    ...lists.map((list) {
                      return _ListCard(
                        list: list,
                        createdText: 'Created ${_formatCreated(list.createdAt)}',
                        sep: sep,
                        headerGreen: headerGreen, // Pass headerGreen
                        isMultiSelecting: _isMultiSelecting,
                        isSelected: _selectedListIds.contains(list.id),
                        onToggleMultiSelect: () {
                          setState(() {
                            _isMultiSelecting = true;
                            if (list.id != null) {
                              if (_selectedListIds.contains(list.id)) {
                                _selectedListIds.remove(list.id);
                              } else {
                                _selectedListIds.add(list.id!);
                              }
                            }
                            if (_selectedListIds.isEmpty) {
                              _isMultiSelecting = false;
                            }
                          });
                        },
                        onToggleSelect: () {
                          setState(() {
                            if (list.id != null) {
                              if (_selectedListIds.contains(list.id)) {
                                _selectedListIds.remove(list.id);
                              } else {
                                _selectedListIds.add(list.id!);
                              }
                            }
                            if (_selectedListIds.isEmpty) {
                              _isMultiSelecting = false;
                            }
                          });
                        },
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
                          }
                        },
                      );
                    }),
                    const SizedBox(height: 6),
                    _CreateListRow(sep: sep, onTap: _showCreateListDialog),
                  ],
                );
              },
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
    IconData tempIcon = _getIconFromCodePoint(list.iconCodePoint);

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
                      await FirebaseFirestore.instance.collection('shoppingLists').doc(list.id).update({
                        'name': newName,
                        'iconCodePoint': tempIcon.codePoint,
                        'iconFontFamily': tempIcon.fontFamily,
                      });
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
    required this.isMultiSelecting,
    required this.isSelected,
    required this.onToggleMultiSelect,
    required this.onToggleSelect,
  });

  final ShoppingListModel list;
  final String createdText;
  final Color sep;
  final VoidCallback onTap;
  final VoidCallback onChevronTap;
  final VoidCallback onActivate;
  final Color headerGreen;
  final bool isMultiSelecting;
  final bool isSelected;
  final VoidCallback onToggleMultiSelect;
  final VoidCallback onToggleSelect;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: onToggleMultiSelect,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: sep),
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Color.fromARGB(10, 0, 0, 0),
              blurRadius: 4,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: isMultiSelecting ? onToggleSelect : onTap,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
              child: Row(
                children: [
                  if (isMultiSelecting)
                    Checkbox(
                      value: isSelected,
                      onChanged: (_) => onToggleSelect(),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    )
                  else
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEEEEE),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        _ViewAllListsPageState._getIconFromCodePoint(list.iconCodePoint),
                        size: 26,
                        color: Colors.grey.shade800,
                      ),
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
                  if (!isMultiSelecting)
                    IconButton(
                      icon: Icon(
                        list.isActive ? Icons.shopping_cart : Icons.shopping_cart_checkout,
                        color: list.isActive ? headerGreen : Colors.grey,
                      ),
                      onPressed: onActivate,
                      tooltip: 'Set as Active List',
                    ),
                  if (!isMultiSelecting)
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: onChevronTap,
                    ),
                ],
              ),
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

/// ====== Dialogs styled like your mockups ======
class _DeleteConfirmDialog extends StatelessWidget {
  const _DeleteConfirmDialog({
    required this.headerGreen,
    required this.title,
    required this.message,
  });

  final Color headerGreen;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFEDEDED),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: headerGreen, width: 6),
        ),
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: TextStyle(
                color: headerGreen,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14.5, color: Colors.black87),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _PillButton(
                  label: 'Yes',
                  color: headerGreen,
                  textColor: Colors.white,
                  onTap: () => Navigator.of(context).pop(true),
                ),
                const SizedBox(width: 12),
                _PillButton(
                  label: 'No',
                  color: const Color(0xFF9E9E9E),
                  textColor: Colors.white,
                  onTap: () => Navigator.of(context).pop(false),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SuccessDialog extends StatelessWidget {
  const _SuccessDialog({
    required this.headerGreen,
    required this.title,
    required this.message,
  });

  final Color headerGreen;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    // Auto-close after a short delay
    Future.delayed(const Duration(milliseconds: 900), () {
      if (!context.mounted) return;
      if (Navigator.of(context).canPop()) Navigator.of(context).pop();
    });

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFEDEDED),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: headerGreen, width: 6),
        ),
        padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: TextStyle(
                color: headerGreen,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14.5, color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  const _PillButton({
    required this.label,
    required this.color,
    required this.textColor,
    required this.onTap,
  });

  final String label;
  final Color color;
  final Color textColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Text(
            label,
            style: TextStyle(color: textColor, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }
}
