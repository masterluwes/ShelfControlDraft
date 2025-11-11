import 'package:flutter/material.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';
import 'package:shelf_control/models/shopping_list_item_model.dart';
import 'package:shelf_control/models/shopping_list_model.dart';
import 'package:shelf_control/services/firestore_service.dart';
import 'package:shelf_control/services/shopping_list_service.dart';
import 'package:shelf_control/services/open_food_facts_service.dart'; // Import OpenFoodFactsService
import 'package:shelf_control/models/product_model.dart'; // Import Product model
import 'package:intl/intl.dart'; // Import for DateFormat
import 'package:uuid/uuid.dart'; // Import Uuid for generating unique IDs

/// ===== Shared store to broadcast the currently selected shopping list =====
/// (shoppinglist.dart listens to this and refreshes automatically)
class MainShoppingListStore extends ChangeNotifier {
  MainShoppingListStore._();
  static final MainShoppingListStore instance = MainShoppingListStore._();

  String? currentListTitle;
  List<ShoppingListItemModel> currentItems = const [];

  void setMainList({required String title, required List<ShoppingListItemModel> items}) {
    currentListTitle = title;
    // deep copy so edits on this page won’t mutate the active list
    currentItems = items.map((e) => e.copyWith()).toList(growable: false);
    notifyListeners();
  }

  /// Public way to clear without touching protected notifyListeners externally.
  void clearMain() {
    currentListTitle = null;
    currentItems = const [];
    notifyListeners();
  }

  bool get hasMain => currentListTitle != null && currentItems.isNotEmpty;
}

/// ===== Page =====
class ListItemsPage extends StatefulWidget {
  const ListItemsPage({super.key, required this.shoppingList});
  final ShoppingListModel shoppingList;

  @override
  State<ListItemsPage> createState() => _ListItemsPageState();
}

class _ListItemsPageState extends State<ListItemsPage> {
  // Palette
  final Color headerGreen = const Color(0xFF2E7D32);
  final Color softCream = const Color(0xFFFFFBE6);
  final Color sep = const Color.fromARGB(255, 230, 230, 230);
  final Uuid _uuid = const Uuid(); // Instantiate Uuid for generating unique IDs

  late final ShoppingListService _shoppingListService;
  final OpenFoodFactsService _openFoodFactsService = OpenFoodFactsService(); // Initialize OpenFoodFactsService
  late ShoppingListModel _currentShoppingList;
  List<ShoppingListItemModel> _items = [];

  // Categories (same set as Shoppinglist)
  final List<String> _categories = const [
    'Bakery',
    'Beverages',
    'Canned Goods',
    'Condiments',
    'Dairy',
    'Dry Goods',
    'Snacks',
    'Other',
  ];

  // Define default shelf lives for categories in days based on research
  final Map<String, int> _categoryShelfLives = {
    'Bakery': 7, // 1 week
    'Beverages': 270, // 9 months (general, UHT milk/juice longer, fresh juice shorter)
    'Canned Goods': 730, // 2 years
    'Condiments': 365, // 12 months (unopened)
    'Dairy': 14, // 2 weeks (for refrigerated items like milk, yogurt)
    'Dry Goods': 547, // 18 months (rice, pasta, flour)
    'Snacks': 180, // 6 months
    'Other': 180, // 6 months
  };

  // More granular shelf lives for specific subcategories/keywords
  final Map<String, Map<String, int>> _subcategoryShelfLives = {
    'Bakery': {
      'bread': 7,
      'cake': 7,
      'pastries': 7,
      'buns': 7,
      'muffin': 7,
      'donut': 3,
      'pandesal': 7,
      'ensaymada': 7,
      'mamon': 7,
    },
    'Dairy': {
      'fresh milk': 7,
      'powdered milk': 270, // 9 months
      'cheese': 60, // 2 months (hard cheese, softer cheese shorter)
      'yogurt': 21, // 3 weeks
      'butter': 90, // 3 months
      'eggs': 30, // 1 month
    },
    'Beverages': {
      'fresh juice': 7,
      'uht milk': 270, // 9 months
      'coffee': 365, // 12 months (unopened)
      'tea': 730, // 2 years
      'soda': 180, // 6 months
      'water': 730, // 2 years
    },
    'Condiments': {
      'vinegar': 730, // 2 years
      'soy sauce': 365, // 1 year
      'ketchup': 365, // 1 year
      'mustard': 365, // 1 year
      'dressing': 180, // 6 months
      'spices': 730, // 2 years
      'powder': 730, // 2 years
      'salt': 1825, // 5 years
    },
    'Dry Goods': {
      'rice': 730, // 2 years
      'pasta': 730, // 2 years
      'flour': 180, // 6 months
      'cereal': 180, // 6 months
      'oil': 365, // 1 year
      'beans': 730, // 2 years (dried)
      'sugar': 1825, // 5 years
    },
    'Snacks': {
      'chips': 90, // 3 months
      'crackers': 180, // 6 months
      'cookies': 180, // 6 months
      'chocolates': 270, // 9 months
      'biscuits': 180, // 6 months
      'packed fudge bars': 180, // 6 months
    }
  };

  @override
  void initState() {
    super.initState();
    _shoppingListService = ShoppingListService(
      firestoreService: Provider.of<FirestoreService>(context, listen: false),
    );
    _currentShoppingList = widget.shoppingList;
    _items = _currentShoppingList.items.map((e) => e.copyWith()).toList(); // Deep copy items
    _resort();
  }

  // ===== Helpers =====
  void _resort() {
    // Bookmarked items first, then the rest. Keep original relative order.
    setState(() {
      final bookmarked = _items.where((e) => e.isBookmarked).toList();
      final others = _items.where((e) => !e.isBookmarked).toList();
      _items
        ..clear()
        ..addAll(bookmarked)
        ..addAll(others);
    });
  }

  String? _suggestCategoryFromName(String itemName) {
    itemName = itemName.toLowerCase();

    final Map<String, List<String>> categoryKeywords = {
      'Bakery': ['bread', 'cake', 'pastries', 'baking needs', 'buns', 'muffin', 'donut', 'pandesal', 'ensaymada', 'mamon'],
      'Dairy': ['milk', 'yogurt', 'cheese', 'butter', 'margarine', 'spread', 'cream', 'eggs', 'evaporada', 'condensada'],
      'Beverages': ['coffee', 'tea', 'juice', 'soda', 'water', 'chocolate drink', 'malt', 'drink', 'softdrink', 'powdered drink'],
      'Canned Goods': ['canned', 'beans', 'soup', 'tuna', 'sardines', 'corned beef', 'meat loaf', 'luncheon meat', 'fruit cocktail'],
      'Dry Goods': ['rice', 'pasta', 'flour', 'cereal', 'grains', 'seeds', 'oil', 'legumes', 'beans', 'soup mix', 'broth', 'noodles', 'sago', 'oats', 'oatmeal', 'sugar'],
      'Snacks': [
        'chips', 'crackers', 'cookies', 'nuts', 'candies', 'chocolates', 'biscuits', 'dips', 'wafer', 'bar', 'pastillas', 'polvoron',
        'packed fudge bars'
      ],
      'Condiments': ['vinegar', 'soy sauce', 'ketchup', 'mustard', 'dressing', 'sauce', 'spices', 'powder', 'salt', 'bbq', 'seasoning', 'garlic bits', 'bagoong', 'chili', 'patis', 'fish sauce'],
      'Other': [],
    };

    for (final categoryEntry in categoryKeywords.entries) {
      final category = categoryEntry.key;
      final keywords = categoryEntry.value;
      for (final keyword in keywords) {
        if (itemName.contains(keyword)) {
          return category;
        }
      }
    }
    return 'Other';
  }

  DateTime? _getExpirationDateForCategory(String category, String itemName, DateTime manufacturedDate) {
    int? shelfLife = _categoryShelfLives[category];
    itemName = itemName.toLowerCase();

    if (_subcategoryShelfLives.containsKey(category)) {
      final subcategoryMap = _subcategoryShelfLives[category]!;
      for (final subcategoryEntry in subcategoryMap.entries) {
        final subcategoryKeyword = subcategoryEntry.key;
        final subcategorySpecificShelfLife = subcategoryEntry.value;
        if (itemName.contains(subcategoryKeyword)) {
          shelfLife = subcategorySpecificShelfLife;
          break;
        }
      }
    }

    if (shelfLife != null) {
      return manufacturedDate.add(Duration(days: shelfLife));
    }
    return null;
  }

  Future<void> _pulseButton(ShoppingListItemModel item, {required bool isInc}) async {
    // No direct pulse fields on ShoppingListItemModel, so we'll manage this locally if needed for UI
    // For now, just update quantity and save
    if (mounted) setState(() {});
    await Future.delayed(const Duration(milliseconds: 160));
    if (mounted) setState(() {});
  }

  Future<void> _inc(int i) async {
    setState(() {
      _items[i].quantity++;
    });
    await _shoppingListService.updateShoppingListItem(
      _currentShoppingList.id!,
      _items[i],
    );
    // Refresh the local list from Firestore to get the item with its ID
    final updatedList = await _shoppingListService.getShoppingListById(_currentShoppingList.id!);
    if (updatedList != null) {
      setState(() {
        _currentShoppingList = updatedList;
        _items = _currentShoppingList.items.map((e) => e.copyWith()).toList(); // Deep copy items
        _resort();
      });
    }
    _pulseButton(_items[i], isInc: true);
  }

  Future<void> _dec(int i) async {
    if (_items[i].quantity > 0) {
      setState(() {
        _items[i].quantity--;
      });
      await _shoppingListService.updateShoppingListItem(
        _currentShoppingList.id!,
        _items[i],
      );
      // Refresh the local list from Firestore to get the item with its ID
      final updatedList = await _shoppingListService.getShoppingListById(_currentShoppingList.id!);
      if (updatedList != null) {
        setState(() {
          _currentShoppingList = updatedList;
          _items = _currentShoppingList.items.map((e) => e.copyWith()).toList(); // Deep copy items
          _resort();
        });
      }
      _pulseButton(_items[i], isInc: false);
    }
  }

  // ---------- Add Item Dialog (same form/feel as Shoppinglist) ----------
  Future<void> _showAddItemDialog() async {
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);

    final formKey = GlobalKey<FormState>();
    final nameFocusNode = FocusNode();
    final nameCtrl = TextEditingController();
    final brandCtrl = TextEditingController();
    final sizeCtrl = TextEditingController();
    final unitPriceCtrl = TextEditingController(text: '0.00');
    final expirationDateCtrl = TextEditingController();
    String? selectedCategory;
    int itemQuantity = 1; // Initialize quantity to 1
    DateTime? _selectedExpDate; // To store the actual expiration date

    InputDecoration deco() => InputDecoration(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.black.withAlpha((255 * 0.15).round())),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: headerGreen, width: 1.5),
      ),
    );

    // Helper to update expiration date based on category and item name
    void _updateExpirationDateFromCategory({bool forceUpdate = false}) {
      if ((expirationDateCtrl.text.isEmpty || forceUpdate) && selectedCategory != null) {
        final DateTime manufacturedDate = DateTime.now(); // Assume manufactured date is now for shopping list
        final DateTime? calculatedExpDate = _getExpirationDateForCategory(
          selectedCategory!,
          nameCtrl.text,
          manufacturedDate,
        );

        if (calculatedExpDate != null) {
          _selectedExpDate = calculatedExpDate;
          expirationDateCtrl.text = DateFormat('MMMM d, yyyy').format(_selectedExpDate!);
        }
      }
    }

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 40),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Container(
              decoration: BoxDecoration(
                color: softCream,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: headerGreen.withAlpha((255 * 0.75).round()),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: headerGreen.withAlpha((255 * 0.30).round()),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
              child: StatefulBuilder(
                builder: (context, setLocal) {
                  return Form(
                    key: formKey,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Product Name',
                            style: TextStyle(
                              color: headerGreen,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 6),
                          RawAutocomplete<Product>(
                            textEditingController: nameCtrl,
                            focusNode: nameFocusNode,
                            optionsBuilder: (TextEditingValue textEditingValue) {
                              if (textEditingValue.text.isEmpty) {
                                return const Iterable<Product>.empty();
                              }
                              return firestoreService.searchProducts(textEditingValue.text).first; // Limit 5 is in FirestoreService
                            },
                            onSelected: (Product selection) {
                              setLocal(() {
                                nameCtrl.text = selection.productName;
                                if (selection.category != null && _categories.contains(selection.category)) {
                                  selectedCategory = selection.category;
                                } else {
                                  selectedCategory = _suggestCategoryFromName(selection.productName);
                                }
                                unitPriceCtrl.text = selection.price?.toStringAsFixed(2) ?? '0.00';
                                sizeCtrl.text = selection.netWeight ?? '';
                                _updateExpirationDateFromCategory(forceUpdate: true);
                              });
                            },
                            fieldViewBuilder: (context, fieldTextEditingController, fieldFocusNode, onFieldSubmitted) {
                              return TextFormField(
                                controller: fieldTextEditingController,
                                focusNode: fieldFocusNode,
                                decoration: deco(),
                                validator: (v) => (v == null || v.trim().isEmpty)
                                    ? 'Please enter a product name'
                                    : null,
                                textInputAction: TextInputAction.next,
                                onChanged: (value) {
                                  setLocal(() {
                                    // Trigger category suggestion and expiration date update on name change
                                    selectedCategory = _suggestCategoryFromName(value);
                                    _updateExpirationDateFromCategory();
                                  });
                                },
                              );
                            },
                            optionsViewBuilder: (context, onSelected, options) {
                              return Align(
                                alignment: Alignment.topLeft,
                                child: Material(
                                  elevation: 4.0, color: Colors.white,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      side: BorderSide(color: Colors.black.withAlpha((255 * 0.15).round()))),
                                  child: ConstrainedBox(
                                    constraints: const BoxConstraints(maxHeight: 250),
                                    child: ListView.builder(
                                      padding: const EdgeInsets.all(4.0), shrinkWrap: true,
                                      itemCount: options.length,
                                      itemBuilder: (BuildContext context, int index) {
                                        final Product option = options.elementAt(index);
                                        return InkWell(
                                          onTap: () => onSelected(option),
                                          child: ListTile(
                                            title: Text(option.productName, style: const TextStyle(color: Colors.black87)),
                                            subtitle: option.brand != null && option.brand!.isNotEmpty
                                                ? Text(option.brand!, style: TextStyle(color: Colors.grey.shade600))
                                                : null,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Size / Weight (e.g., 150g, 1L)',
                            style: TextStyle(
                              color: headerGreen,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: sizeCtrl,
                            decoration: deco(),
                            textInputAction: TextInputAction.next,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Unit Price (₱)',
                            style: TextStyle(
                              color: headerGreen,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: unitPriceCtrl,
                            decoration: deco(),
                            keyboardType: TextInputType.number,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Please enter a unit price';
                              }
                              if (double.tryParse(v.trim()) == null) {
                                return 'Please enter a valid number';
                              }
                              return null;
                            },
                            textInputAction: TextInputAction.next,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Category',
                            style: TextStyle(
                              color: headerGreen,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 6),
                          DropdownButtonFormField2<String>(
                            value: selectedCategory,
                            isExpanded: true,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.black.withAlpha((255 * 0.15).round()),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: headerGreen,
                                  width: 1.5,
                                ),
                              ),
                            ),
                            hint: const Text('Select a category'),
                            items: _categories
                                .map(
                                  (c) => DropdownMenuItem<String>(
                                    value: c,
                                    child: Text(
                                      c,
                                      style: const TextStyle(fontSize: 14.5),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) =>
                                setLocal(() {
                                  selectedCategory = v;
                                  _updateExpirationDateFromCategory(); // Update expiration date on category change
                                }),
                            validator: (v) => (v == null || v.isEmpty)
                                ? 'Please select a category'
                                : null,
                            buttonStyleData: const ButtonStyleData(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                            ),
                            iconStyleData: IconStyleData(
                              icon: Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: headerGreen,
                              ),
                              iconSize: 22,
                            ),
                            dropdownStyleData: DropdownStyleData(
                              maxHeight: 260,
                              elevation: 2,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withAlpha((255 * 0.06).round()),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              offset: const Offset(0, 12),
                              padding: const EdgeInsets.symmetric(vertical: 6),
                            ),
                            menuItemStyleData: const MenuItemStyleData(
                              height: 44,
                              padding: EdgeInsets.symmetric(horizontal: 12),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Expiration Date',
                            style: TextStyle(
                              color: headerGreen,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: expirationDateCtrl,
                            decoration: deco().copyWith(
                              suffixIcon: IconButton(
                                icon: Icon(Icons.calendar_today, color: headerGreen),
                                onPressed: () async {
                                  final pickedDate = await showDatePicker(
                                    context: context,
                                    initialDate: _selectedExpDate ?? DateTime.now(),
                                    firstDate: DateTime(2000),
                                    lastDate: DateTime(2100),
                                    builder: (context, child) => Theme(
                                      data: Theme.of(context).copyWith(
                                        colorScheme: ColorScheme.light(primary: headerGreen, onPrimary: Colors.white),
                                        textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: headerGreen)),
                                      ),
                                      child: child!,
                                    ),
                                  );
                                  if (pickedDate != null) {
                                    setLocal(() {
                                      _selectedExpDate = pickedDate;
                                      expirationDateCtrl.text = DateFormat('MMMM d, yyyy').format(pickedDate);
                                    });
                                  }
                                },
                              ),
                            ),
                            readOnly: true,
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Please enter an expiration date'
                                : null,
                            textInputAction: TextInputAction.next,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Quantity',
                            style: TextStyle(
                              color: headerGreen,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline_rounded),
                                onPressed: () {
                                  if (itemQuantity > 1) {
                                    setLocal(() => itemQuantity--);
                                  }
                                },
                              ),
                              Text('$itemQuantity'),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline_rounded),
                                onPressed: () {
                                  setLocal(() => itemQuantity++);
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              InkWell(
                                onTap: () async {
                                  if (!formKey.currentState!.validate()) return;

                                  // Check for duplicate item before adding
                                  final existingItemIndex = _items.indexWhere(
                                    (item) =>
                                        item.name.toLowerCase() == nameCtrl.text.trim().toLowerCase() &&
                                        (item.netWeight?.toLowerCase() ?? '') == (sizeCtrl.text.trim().toLowerCase()),
                                  );

                                  if (existingItemIndex != -1) {
                                    // Duplicate found, increment quantity
                                    final existingItem = _items[existingItemIndex];
                                    final updatedItem = existingItem.copyWith(quantity: existingItem.quantity + itemQuantity);
                                    if (_currentShoppingList.id != null) {
                                      await _shoppingListService.updateShoppingListItem(_currentShoppingList.id!, updatedItem);
                                    }
                                  } else {
                                    // No duplicate, add new item
                                    final newItem = ShoppingListItemModel(
                                      id: _uuid.v4(), // Generate ID for new items
                                      name: nameCtrl.text.trim(),
                                      brand: brandCtrl.text.trim().isEmpty ? null : brandCtrl.text.trim(),
                                      netWeight: sizeCtrl.text.trim().isEmpty ? null : sizeCtrl.text.trim(),
                                      category: selectedCategory!,
                                      unitPrice: double.parse(unitPriceCtrl.text.trim()),
                                      quantity: itemQuantity,
                                      expirationDate: _selectedExpDate, // Use the selected/generated expiration date
                                    );

                                    if (_currentShoppingList.id != null) {
                                      await _shoppingListService.addShoppingListItem(_currentShoppingList.id!, newItem);
                                    }
                                  }

                                  // Refresh the local list from Firestore to get the item with its ID
                                  final updatedList = await _shoppingListService.getShoppingListById(_currentShoppingList.id!);
                                  if (updatedList != null) {
                                    setState(() {
                                      _currentShoppingList = updatedList;
                                      _items = _currentShoppingList.items.map((e) => e.copyWith()).toList(); // Deep copy items
                                      _resort();
                                    });
                                  }

                                  if (!mounted) return;
                                  Navigator.of(ctx).pop();
                                },
                                borderRadius: BorderRadius.circular(24),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 28,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: headerGreen,
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  child: const Text(
                                    'Add',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                              InkWell(
                                onTap: () => Navigator.of(ctx).pop(),
                                borderRadius: BorderRadius.circular(24),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 22,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(
                                      color: headerGreen,
                                      width: 2,
                                    ),
                                  ),
                                  child: Text(
                                    'Cancel',
                                    style: TextStyle(
                                      color: headerGreen,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _editItem(int index) async {
    final it = _items[index];
    final nameCtrl = TextEditingController(text: it.name);
    final brandCtrl = TextEditingController(text: it.brand ?? '');
    final sizeCtrl = TextEditingController(text: it.netWeight ?? '');
    final expirationDateCtrl = TextEditingController(text: it.expirationDate != null ? DateFormat('MMMM d, yyyy').format(it.expirationDate!) : '');
    String category = it.category ?? _categories.first; // Ensure category is not null
    int qty = it.quantity;
    double unitPrice = it.unitPrice;
    final unitPriceCtrl = TextEditingController(text: it.unitPrice.toStringAsFixed(2));
    DateTime? _selectedExpDate = it.expirationDate; // To store the actual expiration date

    InputDecoration deco() => InputDecoration(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.black.withAlpha((255 * 0.15).round())),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: headerGreen, width: 1.5),
      ),
    );

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 40),
          child: ConstrainedBox( // Wrap with ConstrainedBox to limit dialog size
            constraints: const BoxConstraints(maxWidth: 400), // Set a max width
            child: Container(
              decoration: BoxDecoration(
                color: softCream,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: headerGreen.withAlpha((255 * 0.75).round()),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: headerGreen.withAlpha((255 * 0.30).round()),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
              child: StatefulBuilder(
                builder: (context, setLocal) {
                  return Form(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Edit Item',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: headerGreen,
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Product Name',
                            style: TextStyle(
                              color: headerGreen,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: nameCtrl,
                            decoration: deco(),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Please enter a product name'
                                : null,
                            textInputAction: TextInputAction.next,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Size / Weight (e.g., 150g, 1L)',
                            style: TextStyle(
                              color: headerGreen,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: sizeCtrl,
                            decoration: deco(),
                            textInputAction: TextInputAction.next,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Unit Price (₱)',
                            style: TextStyle(
                              color: headerGreen,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: unitPriceCtrl,
                            decoration: deco(),
                            keyboardType: TextInputType.number,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Please enter a unit price';
                              }
                              if (double.tryParse(v.trim()) == null) {
                                return 'Please enter a valid number';
                              }
                              return null;
                            },
                            onChanged: (v) => unitPrice = double.tryParse(v) ?? 0.0,
                            textInputAction: TextInputAction.next,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Category',
                            style: TextStyle(
                              color: headerGreen,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 6),
                          DropdownButtonFormField2<String>(
                            value: category,
                            isExpanded: true,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.black.withAlpha((255 * 0.15).round()),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: headerGreen,
                                  width: 1.5,
                                ),
                              ),
                            ),
                            hint: const Text('Select a category'),
                            items: _categories
                                .map(
                                  (c) => DropdownMenuItem<String>(
                                    value: c,
                                    child: Text(
                                      c,
                                      style: const TextStyle(fontSize: 14.5),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) =>
                                setLocal(() => category = v!), // Assert v is not null
                            validator: (v) => (v == null || v.isEmpty)
                                ? 'Please select a category'
                                : null,
                            buttonStyleData: const ButtonStyleData(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                            ),
                            iconStyleData: IconStyleData(
                              icon: Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: headerGreen,
                              ),
                              iconSize: 22,
                            ),
                            dropdownStyleData: DropdownStyleData(
                              maxHeight: 260,
                              elevation: 2,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withAlpha((255 * 0.06).round()),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              offset: const Offset(0, 12),
                              padding: const EdgeInsets.symmetric(vertical: 6),
                            ),
                            menuItemStyleData: const MenuItemStyleData(
                              height: 44,
                              padding: EdgeInsets.symmetric(horizontal: 12),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Expiration Date',
                            style: TextStyle(
                              color: headerGreen,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: expirationDateCtrl,
                            decoration: deco().copyWith(
                              suffixIcon: IconButton(
                                icon: Icon(Icons.calendar_today, color: headerGreen),
                                onPressed: () async {
                                  final pickedDate = await showDatePicker(
                                    context: context,
                                    initialDate: _selectedExpDate ?? DateTime.now(),
                                    firstDate: DateTime(2000),
                                    lastDate: DateTime(2100),
                                    builder: (context, child) => Theme(
                                      data: Theme.of(context).copyWith(
                                        colorScheme: ColorScheme.light(primary: headerGreen, onPrimary: Colors.white),
                                        textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: headerGreen)),
                                      ),
                                      child: child!,
                                    ),
                                  );
                                  if (pickedDate != null) {
                                    setLocal(() {
                                      _selectedExpDate = pickedDate;
                                      expirationDateCtrl.text = DateFormat('MMMM d, yyyy').format(pickedDate);
                                    });
                                  }
                                },
                              ),
                            ),
                            readOnly: true,
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Please enter an expiration date'
                                : null,
                            textInputAction: TextInputAction.next,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Quantity',
                            style: TextStyle(
                              color: headerGreen,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline_rounded),
                                onPressed: () {
                                  if (qty > 1) {
                                    setLocal(() => qty--);
                                  }
                                },
                              ),
                              Text('$qty'),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline_rounded),
                                onPressed: () {
                                  setLocal(() => qty++);
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              InkWell(
                                onTap: () async {
                                  final updatedItem = it.copyWith(
                                    id: it.id, // Explicitly pass the ID
                                    name: nameCtrl.text.trim().isEmpty
                                        ? it.name
                                        : nameCtrl.text.trim(),
                                    brand: brandCtrl.text.trim().isEmpty
                                        ? null
                                        : brandCtrl.text.trim(),
                                    netWeight: sizeCtrl.text.trim().isEmpty
                                        ? null
                                        : sizeCtrl.text.trim(),
                                    category: category,
                                    quantity: qty,
                                    unitPrice: unitPrice,
                                    expirationDate: _selectedExpDate, // Update expiration date
                                    isPurchased: it.isPurchased, // Preserve existing state
                                    isBookmarked: it.isBookmarked, // Preserve existing state
                                  );

                                  setState(() {
                                    _items[index] = updatedItem;
                                  });

                                  if (_currentShoppingList.id != null) {
                                    await _shoppingListService.updateShoppingListItem(
                                      _currentShoppingList.id!,
                                      updatedItem,
                                    );
                                    // Refresh the local list from Firestore to ensure consistency
                                    final updatedList = await _shoppingListService.getShoppingListById(_currentShoppingList.id!);
                                    if (updatedList != null) {
                                      setState(() {
                                        _currentShoppingList = updatedList;
                                        _items = _currentShoppingList.items.map((e) => e.copyWith()).toList(); // Deep copy items
                                        _resort();
                                      });
                                    }
                                  }
                                  if (!mounted) return;
                                  Navigator.of(ctx).pop();
                                },
                                borderRadius: BorderRadius.circular(24),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 28,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: headerGreen,
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  child: const Text(
                                    'Save',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                              InkWell(
                                onTap: () => Navigator.of(ctx).pop(),
                                borderRadius: BorderRadius.circular(24),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 22,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(
                                      color: headerGreen,
                                      width: 2,
                                    ),
                                  ),
                                  child: Text(
                                    'Cancel',
                                    style: TextStyle(
                                      color: headerGreen,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmDeleteItem(int index) async {
    final it = _items[index];
    final bool? confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _DeleteConfirmDialog(
        headerGreen: headerGreen,
        title: 'Delete item',
        message: 'Delete “${it.name}” from this list?',
      ),
    );
    if (confirmed == true && mounted) {
      if (_currentShoppingList.id != null && it.id != null) {
        await _shoppingListService.removeShoppingListItem(
          _currentShoppingList.id!,
          it,
        );
        // Refresh the local list from Firestore
        final updatedList = await _shoppingListService.getShoppingListById(_currentShoppingList.id!);
        if (updatedList != null) {
          setState(() {
            _currentShoppingList = updatedList;
            _items = _currentShoppingList.items.map((e) => e.copyWith()).toList(); // Deep copy items
            _resort();
          });
        }
      }
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => _SuccessDialog(
          headerGreen: headerGreen,
          title: 'Deleted',
          message: 'Item removed from the list.',
        ),
      );
    }
  }

  // Switches this list to be the active one used by shoppinglist.dart
  void _useAsCurrent() {
    MainShoppingListStore.instance.setMainList(
      title: _currentShoppingList.name,
      items: _items.map((e) => e.copyWith()).toList(), // Ensure deep copy when setting to store
    );
  }

  // ===== Delete current list flow =====
  Future<void> _confirmDeleteCurrentList() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _DeleteConfirmDialog(
        headerGreen: headerGreen,
        title: 'Delete shopping list',
        message: 'Are you sure you want to delete “${_currentShoppingList.name}”?',
      ),
    );

    if (confirmed == true && mounted) {
      if (_currentShoppingList.id != null) {
        await _shoppingListService.deleteShoppingList(_currentShoppingList.id!);
      }

      // If this was the active list, clear shared store safely
      final store = MainShoppingListStore.instance;
      if (store.currentListTitle == _currentShoppingList.name) {
        store.clearMain();
      }

      // Success card
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => _SuccessDialog(
          headerGreen: headerGreen,
          title: 'Success!',
          message: 'Shopping list deleted.',
        ),
      );

      if (!mounted) return;
      Navigator.of(
        context,
      ).pop({'deleted': true, 'listTitle': _currentShoppingList.name});
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color grey = Colors.grey.shade700;

    return Scaffold(
      backgroundColor: softCream,
      body: Column(
        children: [
          // === HEADER ===
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
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _currentShoppingList.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Delete list',
                  icon: const Icon(Icons.delete_outline, color: Colors.white),
                  onPressed: _confirmDeleteCurrentList,
                ),
              ],
            ),
          ),

          Divider(height: 1, thickness: 1, color: sep),

          // === CONTENT ===
          Expanded(
            child: ListView.separated(
              itemCount: _items.length,
              separatorBuilder: (_, __) => Divider(color: sep, height: 1),
              itemBuilder: (context, index) {
                final it = _items[index];

                return Slidable(
                  key: ValueKey(it.id),
                  endActionPane: ActionPane(
                    motion: const ScrollMotion(),
                    children: [
                      SlidableAction(
                        onPressed: (_) => _editItem(index),
                        icon: Icons.edit_outlined,
                        label: 'Edit',
                        backgroundColor: headerGreen,
                        foregroundColor: Colors.white,
                      ),
                      SlidableAction(
                        onPressed: (_) => _confirmDeleteItem(index),
                        icon: Icons.delete_outline,
                        label: 'Delete',
                        backgroundColor: Colors.red.shade600,
                        foregroundColor: Colors.white,
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.white,
                    child: Stack(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          child: _ShoppingRowSL(
                            item: it,
                            headerGreen: headerGreen,
                            grey: grey,
                            onToggleInCart: (v) async {
                              if (_currentShoppingList.id != null) {
                                final updatedItem = it.copyWith(isPurchased: v ?? false);
                                await _shoppingListService.updateShoppingListItem(
                                  _currentShoppingList.id!,
                                  updatedItem,
                                );
                                // Refresh the local list from Firestore
                                final updatedList = await _shoppingListService.getShoppingListById(_currentShoppingList.id!);
                                if (updatedList != null) {
                                  setState(() {
                                    _currentShoppingList = updatedList;
                                    _items = _currentShoppingList.items.map((e) => e.copyWith()).toList(); // Deep copy items
                                    _resort();
                                  });
                                }
                              }
                            },
                            onToggleBookmark: () async {
                              if (_currentShoppingList.id != null) {
                                final updatedItem = it.copyWith(isBookmarked: !it.isBookmarked);
                                await _shoppingListService.updateShoppingListItem(
                                  _currentShoppingList.id!,
                                  updatedItem,
                                );
                                // Refresh the local list from Firestore
                                final updatedList = await _shoppingListService.getShoppingListById(_currentShoppingList.id!);
                                if (updatedList != null) {
                                  setState(() {
                                    _currentShoppingList = updatedList;
                                    _items = _currentShoppingList.items.map((e) => e.copyWith()).toList(); // Deep copy items
                                    _resort();
                                  });
                                }
                              }
                            },
                            onDecrement: () => _dec(index),
                            onIncrement: () => _inc(index),
                            openFoodFactsService: _openFoodFactsService, // Pass the service
                          ),
                        ),
                        if (it.isPurchased)
                          Positioned.fill(
                            child: IgnorePointer(
                              ignoring: true,
                              child: Container(
                                color: Colors.white.withAlpha((255 * 0.45).round()),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),

      // Add new item
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(right: 12, bottom: 12),
        child: ElevatedButton.icon(
          onPressed: _showAddItemDialog,
          icon: const Icon(Icons.add),
          label: const Text('Add new item'),
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
}

/// ===== Icon helpers (name-aware → category fallback) =====
IconData _iconForCategory(String category) {
  switch (category) {
    case 'Bakery':
      return Icons.cake;
    case 'Beverages':
      return Icons.local_drink;
    case 'Canned Goods':
      return Icons.inventory_2;
    case 'Condiments':
      return Icons.kitchen;
    case 'Dairy':
      return Icons.icecream;
    case 'Dry Goods':
      return Icons.grain;
    case 'Snacks':
      return Icons.fastfood;
    case 'Other':
      return Icons.category;
    default:
      return Icons.category;
  }
}

IconData _iconForName(String name, String category) {
  final n = name.toLowerCase();
  if (n.contains('bread') || n.contains('cake') || n.contains('pastry') || n.contains('muffin') || n.contains('donut')) return Icons.cake;
  if (n.contains('milk') || n.contains('yogurt') || n.contains('cheese') || n.contains('butter') || n.contains('egg')) return Icons.icecream;
  if (n.contains('juice') || n.contains('soda') || n.contains('water') || n.contains('coffee') || n.contains('tea')) return Icons.local_drink;
  if (n.contains('canned') || n.contains('soup') || n.contains('tuna') || n.contains('sardines')) return Icons.inventory_2;
  if (n.contains('ketchup') || n.contains('mustard') || n.contains('sauce') || n.contains('spices') || n.contains('salt')) return Icons.kitchen;
  if (n.contains('rice') || n.contains('pasta') || n.contains('flour') || n.contains('cereal') || n.contains('oil')) return Icons.grain;
  if (n.contains('chips') || n.contains('crackers') || n.contains('cookies') || n.contains('chocolate')) return Icons.fastfood;
  return _iconForCategory(category);
}

/// ===== Row UI (now with Shoppinglist-style circular icon chip) =====
class _ShoppingRowSL extends StatelessWidget {
  const _ShoppingRowSL({
    required this.item,
    required this.headerGreen,
    required this.grey,
    required this.onToggleInCart,
    required this.onToggleBookmark,
    required this.onDecrement,
    required this.onIncrement,
    required this.openFoodFactsService, // Add this parameter
  });

  final ShoppingListItemModel item;
  final Color headerGreen;
  final Color grey;
  final ValueChanged<bool?> onToggleInCart;
  final VoidCallback onToggleBookmark;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;
  final OpenFoodFactsService openFoodFactsService; // Declare the parameter

  @override
  Widget build(BuildContext context) {
    final bool selected = item.isPurchased;

    Widget pulseIcon({
      required bool active,
      required IconData outlineIcon,
      required IconData filledIcon,
      required VoidCallback onPressed,
    }) {
      final bg = active ? headerGreen.withAlpha((255 * 0.12).round()) : Colors.transparent;
      final iconData = active ? filledIcon : outlineIcon;
      final iconColor = active ? headerGreen : grey;

      return AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
        child: IconButton(
          icon: Icon(iconData, color: iconColor),
          onPressed: onPressed,
          splashRadius: 20,
        ),
      );
    }

    // Compose the "brand · size" subline
    String? subline;
    if ((item.brand != null && item.brand!.trim().isNotEmpty) ||
        (item.netWeight != null && item.netWeight!.trim().isNotEmpty)) {
      final b = (item.brand ?? '').trim();
      final s = (item.netWeight ?? '').trim();
      subline = (b.isNotEmpty && s.isNotEmpty)
          ? '$b · $s'
          : (b.isNotEmpty ? b : s);
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Checkbox
        Checkbox(
          value: selected,
          onChanged: onToggleInCart,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),

        // === Shoppinglist-style circular green icon chip ===
        Container(
          width: 32,
          height: 32,
          margin: const EdgeInsets.only(right: 10),
          decoration: BoxDecoration(
            color: headerGreen.withAlpha((255 * 0.10).round()),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Icon(
            _iconForName(item.name, item.category ?? 'Other'),
            size: 18,
            color: headerGreen,
          ),
        ),

        // Texts
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(
                  item.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    decoration: selected
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                    color: selected ? Colors.grey.shade600 : Colors.black87,
                  ),
                ),
              ),
              if (subline != null) ...[
                const SizedBox(height: 1),
                Text(
                  subline,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.5,
                    color: (selected
                        ? Colors.black54
                        : Colors.black87.withAlpha((255 * 0.75).round())),
                    height: 1.1,
                  ),
                ),
              ],
              const SizedBox(height: 2),
              Text(
                item.category ?? 'Other',
                style: TextStyle(
                  fontSize: 12.5,
                  color: selected ? Colors.black45 : Colors.black54,
                ),
              ),
            ],
          ),
        ),

        IconButton(
          icon: Icon(
            item.isBookmarked ? Icons.bookmark : Icons.bookmark_border,
            color: item.isBookmarked ? headerGreen : grey,
          ),
          onPressed: onToggleBookmark,
          splashRadius: 20,
          tooltip: item.isBookmarked ? 'Unpin' : 'Pin (priority)',
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Compact quantity controls
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 28,
                  height: 28,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: Icon(Icons.remove_circle_outline_rounded, color: grey, size: 20),
                    onPressed: onDecrement,
                    splashRadius: 18,
                  ),
                ),
                Container(
                  width: 30,
                  alignment: Alignment.center,
                  child: Text(
                    '${item.quantity}',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
                SizedBox(
                  width: 28,
                  height: 28,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: Icon(Icons.add_circle_outline_rounded, color: grey, size: 20),
                    onPressed: onIncrement,
                    splashRadius: 18,
                  ),
                ),
              ],
            ),
            // Unit price (smaller)
            Text(
              '₱${item.unitPrice.toStringAsFixed(2)}/item',
              style: TextStyle(
                fontSize: 11,
                color: selected ? Colors.grey.shade500 : Colors.grey.shade600,
              ),
            ),
            // Total price for quantity
            Text(
              '₱${(item.unitPrice * item.quantity).toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: selected ? Colors.grey.shade600 : headerGreen,
              ),
            ),
          ],
        ),
      ],
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

class _EditQtyButton extends StatelessWidget {
  const _EditQtyButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color border = enabled
        ? const Color(0xFF9E9E9E)
        : Colors.grey.shade300;
    final Color fg = enabled ? const Color(0xFF9E9E9E) : Colors.grey.shade300;
    return InkResponse(
      radius: 20,
      onTap: enabled ? onTap : null,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: border, width: 1.6),
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: 18, color: fg),
      ),
    );
  }
}
