import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:shelf_control/models/shopping_list_item_model.dart';
import 'package:shelf_control/models/pantry_item_model.dart'; // Import PantryItemModel
import 'package:shelf_control/models/shopping_history_item_model.dart'; // Import ShoppingHistoryItemModel
import 'package:shelf_control/models/shopping_list_model.dart';
import 'package:shelf_control/screens/viewalllists.dart' hide Text, Navigator, SizedBox;
import 'package:shelf_control/services/shopping_list_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/rendering.dart' show RenderRepaintBoundary;
import 'package:provider/provider.dart'; // Import provider
import 'package:shelf_control/services/firestore_service.dart'; // Import FirestoreService
import 'package:shelf_control/services/open_food_facts_service.dart'; // Import OpenFoodFactsService
import 'package:uuid/uuid.dart'; // Import Uuid for generating unique IDs
import 'package:shared_preferences/shared_preferences.dart'; // Import SharedPreferences
import 'package:shelf_control/models/product_model.dart'; // Import Product model
import 'package:intl/intl.dart'; // Import for DateFormat

class Shoppinglist extends StatefulWidget {
  final bool isGuest; // New parameter to indicate guest mode
  const Shoppinglist({super.key, this.isGuest = false});
  @override
  State<Shoppinglist> createState() => _ShoppinglistState();
}

class _ShoppinglistState extends State<Shoppinglist> {
  // Palette
  final Color headerGreen = const Color(0xFF2E7D32); // Minor change to trigger linter refresh
  final Color softCream = const Color(0xFFFFFBE6);
  final Color sep = const Color.fromARGB(255, 230, 230, 230);
  final Uuid _uuid = const Uuid(); // Instantiate Uuid for generating unique IDs
  // Deeper green for "View All List"
  final Color darkGreen = const Color(0xFF2F4F3A);


  // For PNG export — wrap the list with a RepaintBoundary
  final GlobalKey _captureKey = GlobalKey();

  String? _householdId;
  late final ShoppingListService _shoppingListService;
  final OpenFoodFactsService _openFoodFactsService = OpenFoodFactsService();

  // Guest limit
  static const int _maxGuestItems = 15;
  bool _suggestionsOpen = false; // State for suggestions collapsible

  late FirestoreService _firestoreService; // Declare FirestoreService instance
  Stream<ShoppingListModel?>? _activeShoppingListStream; // Stream for the active shopping list
  Stream<List<_Suggestion>>? _suggestionsStream; // Stream for suggestions

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

  @override
  void initState() {
    super.initState();
    _firestoreService = Provider.of<FirestoreService>(context, listen: false);
    _shoppingListService = ShoppingListService(firestoreService: _firestoreService);
    _householdId = _firestoreService.selectedHouseholdId;
    debugPrint('DEBUG: Shoppinglist initState - Initial householdId: $_householdId');
    _setupStreams();
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Re-setup streams if householdId changes (e.g., user switches household)
    // Listen to FirestoreService to react to changes in selectedHouseholdId
    final newHouseholdId = Provider.of<FirestoreService>(context).selectedHouseholdId;
    if (newHouseholdId != _householdId) {
      debugPrint('DEBUG: Shoppinglist didChangeDependencies - HouseholdId changed from $_householdId to $newHouseholdId');
      setState(() {
        _householdId = newHouseholdId;
        _setupStreams();
      });
    } else {
      debugPrint('DEBUG: Shoppinglist didChangeDependencies - HouseholdId is still $_householdId');
    }
  }

  void _setupStreams() {
    debugPrint('DEBUG: Shoppinglist _setupStreams called for householdId: $_householdId');
    if (widget.isGuest) {
      // For guest users, we'll simulate a stream from local storage
      _activeShoppingListStream = _firestoreService.guestShoppingListsStream().map((guestLists) {
        debugPrint('DEBUG: Shoppinglist _setupStreams - Guest mode, active list count: ${guestLists.length}');
        return guestLists.isNotEmpty ? guestLists.first : null;
      });
      _suggestionsStream = Stream.value([]); // Guests don't get suggestions
    } else if (_householdId != null) {
      _activeShoppingListStream = _firestoreService.streamActiveShoppingList(_householdId!);
      _suggestionsStream = _firestoreService.streamSuggestions(_householdId!).map((generatedSuggestions) {
        debugPrint('DEBUG: Shoppinglist _setupStreams - Suggestions generated count: ${generatedSuggestions.length}');
        return generatedSuggestions
            .where((item) =>
                item.name != null &&
                item.name!.toLowerCase() != 'cup noodles' && // Exclude "Cup Noodles"
                (item.nutrition == null || item.nutrition!.toLowerCase() != 'healthy option')) // Exclude "Healthy option" as nutrition
            .map((item) => _Suggestion(
                  id: item.id!, // Pass pantry item ID
                  name: item.name!,
                  sizeText: item.netWeight,
                  note: item.suggestionStatus ?? 'Suggested',
                  category: item.category ?? 'Other',
                  nutrition: item.nutrition,
                  unitPrice: item.unitPrice, // Pass unit price
                  originalPantryItemId: item.originalPantryItemId, // Pass original pantry item ID
                  expirationDate: item.expirationDate, // Pass expiration date
                ))
            .toList();
      });
    } else {
      _activeShoppingListStream = Stream.value(null);
      _suggestionsStream = Stream.value([]);
      debugPrint('DEBUG: Shoppinglist _setupStreams - No householdId, streams set to null/empty.');
    }
    // No setState here, as StreamBuilder will handle rebuilds
  }


  @override
  void dispose() {
    // Streams are managed by FirestoreService, no need to dispose here
    super.dispose();
  }

  // Helper to reorder items by bookmark status
  List<ShoppingListItemModel> _reorderByBookmark(List<ShoppingListItemModel> items) {
    final bookmarked = <ShoppingListItemModel>[];
    final others = <ShoppingListItemModel>[];
    for (final it in items) {
      (it.isBookmarked ? bookmarked : others).add(it);
    }
    return [...bookmarked, ...others];
  }

  // --- Add to Pantry Workflow ---
  Future<void> _addPurchasedItemToPantry(ShoppingListItemModel item) async {
    if (_householdId == null) {
      // No household selected.
      return;
    }

    final firestoreService = Provider.of<FirestoreService>(context, listen: false);

    // Check if the item already exists in pantry with the same name and netWeight
    QuerySnapshot existingPantryItemsSnapshot = await firestoreService.db
        .collection('pantryItems')
        .where('householdId', isEqualTo: _householdId)
        .where('name', isEqualTo: item.name)
        .where('netWeight', isEqualTo: item.netWeight)
        .where('category', isEqualTo: item.category) // Add category to duplicate check
        .get();

    final DateTime manufacturedDate = DateTime.now();
    final DateTime? expirationDate = _shoppingListService.getExpirationDateForCategory(
      item.category ?? 'Other',
      item.name,
      manufacturedDate,
    );

    PantryItemModel newPantryItem = PantryItemModel(
      id: _uuid.v4(), // Generate new ID for new pantry item
      householdId: _householdId!,
      name: item.name,
      category: item.category ?? 'Other',
      qty: item.quantity,
      quantityUnit: item.netWeight, // Keep this for consistency
      netWeight: item.netWeight, // Ensure netWeight is saved
      price: item.unitPrice, // Ensure price is saved
      expirationDate: expirationDate,
      manufacturedDate: manufacturedDate,
      barcode: null,
      status: 'Available',
      nutrition: item.nutrition,
    );

    if (existingPantryItemsSnapshot.docs.isNotEmpty) {
      final existingPantryItem = PantryItemModel.fromFirestore(existingPantryItemsSnapshot.docs.first);

      // If a duplicate is found, check if it should be combined or added as a new item.
      // Items are combined only if all relevant details (name, netWeight, category, and expiration date) are the same.
      // If the existing item has an expiration date and it's different from the new item's,
      // or if the existing item has a manufactured date and it's different, treat as a new item.
      bool shouldCombine = true;
      if (existingPantryItem.expirationDate != null && expirationDate != null &&
          existingPantryItem.expirationDate!.difference(expirationDate).inDays != 0) {
        shouldCombine = false;
      }
      if (existingPantryItem.manufacturedDate != null && manufacturedDate != null &&
          existingPantryItem.manufacturedDate!.difference(manufacturedDate).inDays != 0) {
        shouldCombine = false;
      }

      if (shouldCombine) {
        final updatedPantryItem = existingPantryItem.copyWith(
          qty: existingPantryItem.qty + item.quantity,
          // Update expiration/manufactured dates only if the existing item doesn't have them
          expirationDate: existingPantryItem.expirationDate ?? expirationDate,
          manufacturedDate: existingPantryItem.manufacturedDate ?? manufacturedDate,
        );
        await firestoreService.db.collection('pantryItems').doc(existingPantryItem.id).update(updatedPantryItem.toFirestore());
        debugPrint('DEBUG: _addPurchasedItemToPantry - Combined item: ${item.name}, new quantity: ${updatedPantryItem.qty}');
      } else {
        // Treat as a new item if not combinable (e.g., different expiration date)
        await firestoreService.db.collection('pantryItems').doc(newPantryItem.id).set(newPantryItem.toFirestore());
        debugPrint('DEBUG: _addPurchasedItemToPantry - Added new item (not combined): ${item.name}');
      }
    } else {
      // No duplicate found, add new item
      await firestoreService.db.collection('pantryItems').doc(newPantryItem.id).set(newPantryItem.toFirestore());
      debugPrint('DEBUG: _addPurchasedItemToPantry - Added new item: ${item.name}');
    }

    // Add to shopping history
    await firestoreService.db.collection('shoppingHistory').doc().set(ShoppingHistoryItemModel(
      householdId: _householdId!,
      productId: item.productId,
      productName: item.name,
      category: item.category,
      netWeight: item.netWeight, // Add netWeight
      nutrition: item.nutrition, // Add nutrition
      ecoscore: item.ecoscore, // Add ecoscore
      quantity: item.quantity,
      purchaseDate: DateTime.now(),
      actionType: 'Purchased',
      priceAtAction: item.unitPrice, // Add priceAtAction
    ).toFirestore());
  }

  Future<void> _clearPurchasedItems(ShoppingListModel activeList) async {
    if (_householdId == null) {
      // No household selected.
      return;
    }

    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    List<ShoppingListItemModel> purchasedItems = activeList.items.where((item) => item.isPurchased).toList();

    if (purchasedItems.isEmpty) {
      // No items marked as purchased to clear.
      return;
    }

    // Confirm with the user before clearing
    final bool? confirmClear = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 40),
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Clear Purchased Items?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: headerGreen,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Are you sure you want to clear ${purchasedItems.length} purchased item(s) from this list?',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    InkWell(
                      onTap: () => Navigator.of(ctx).pop(true),
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
                          'Clear',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () => Navigator.of(ctx).pop(false),
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
    );

    if (confirmClear != true) {
      return; // User cancelled
    }

    for (var item in purchasedItems) {
      // Remove from shopping list
      if (widget.isGuest) {
        List<ShoppingListModel> guestLists = await firestoreService.loadGuestShoppingLists();
        int activeListIndex = guestLists.indexWhere((list) => list.id == activeList.id);
        if (activeListIndex != -1) {
          guestLists[activeListIndex].items.removeWhere((e) => e.id == item.id);
          await firestoreService.saveGuestShoppingLists(guestLists);
        }
      } else {
        await _shoppingListService.removeShoppingListItem(activeList.id!, item);
      }
    }

    // ${purchasedItems.length} item(s) cleared and moved to history!
  }

  // ---------- Helpers: compute top margin under header ----------


  // ---------- limit banner ----------
  Future<void> _showLimitDialog() async {
    await showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withAlpha((255 * 0.15).round()),
      builder: (_) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 320,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              decoration: BoxDecoration(
                color: const Color(0xFFE6E6E6),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: headerGreen, width: 5),
                boxShadow: [
                  BoxShadow(
                    color: headerGreen.withAlpha((255 * 0.25).round()),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 6),
                  Text(
                    'Shopping list limit exceeded!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: headerGreen,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text.rich(
                    TextSpan(
                      text: 'Register',
                      style: TextStyle(
                        fontSize: 14.5,
                        color: Colors.black87,
                        fontWeight: FontWeight.w700,
                      ),
                      children: [
                        TextSpan(
                          text: ' or ',
                          style: TextStyle(fontWeight: FontWeight.normal),
                        ),
                        TextSpan(
                          text: 'Login',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        TextSpan(
                          text: ' to add more items.',
                          style: TextStyle(fontWeight: FontWeight.normal),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 26),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'OK',
                      style: TextStyle(
                        color: headerGreen,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ---------- Export helpers ----------
  String _asPlainText(ShoppingListModel activeList) {
    final buf = StringBuffer()
      ..writeln(activeList.name)
      ..writeln('-' * activeList.name.length)
      ..writeln();

    for (final it in activeList.items) {
      final checked = it.isPurchased ? 'x' : ' ';
      final sub = [
        if ((it.netWeight ?? '').trim().isNotEmpty) it.netWeight!.trim(),
      ].join(' · ');
      final name = sub.isEmpty ? it.name : '${it.name} ($sub)';
      buf.writeln('[$checked] $name  —  Qty: ${it.quantity}  ·  ${it.category}  ·  ₱${(it.unitPrice * it.quantity).toStringAsFixed(2)}');
    }
    return buf.toString();
  }

  Future<Uint8List> _capturePng() async {
    final boundary =
        _captureKey.currentContext?.findRenderObject()
            as RenderRepaintBoundary?;
    if (boundary == null) throw Exception('Nothing to capture');
    final ui.Image image = await boundary.toImage(pixelRatio: 3);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) throw Exception('Failed to encode PNG');
    return byteData.buffer.asUint8List();
  }

  Future<File> _writeTemp(Uint8List bytes, String filename) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsBytes(bytes);
    return file;
  }

  Future<void> _exportAsTxt(ShoppingListModel activeList) async {
    try {
      final text = _asPlainText(activeList);
      final bytes = Uint8List.fromList(utf8.encode(text));
      final file = await _writeTemp(
        bytes,
        '${activeList.name.replaceAll(' ', '_').toLowerCase()}.txt',
      );
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'text/plain')],
          subject: 'Shopping List',
        ),
      );
    } catch (e) {
      // Failed to export TXT: $e
    }
  }

  Future<void> _exportAsPng(ShoppingListModel activeList) async {
    try {
      final png = await _capturePng();
      final file = await _writeTemp(
        png,
        '${activeList.name.replaceAll(' ', '_').toLowerCase()}.png',
      );
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'image/png')],
          subject: 'Shopping List',
        ),
      );
    } catch (e) {
      // Failed to export PNG: $e
    }
  }

  void _openExportSheet(ShoppingListModel activeList) {
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
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
                    'Export "${activeList.name}"',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: Colors.grey.shade900,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: const Icon(Icons.description_outlined),
                  title: const Text('Export as TXT'),
                  subtitle: const Text('Share a plain text list'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _exportAsTxt(activeList);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.image_outlined),
                  title: const Text('Export as PNG'),
                  subtitle: const Text('Share an image of the list'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _exportAsPng(activeList);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ---------- Add Item Dialog ----------
  Future<void> _showAddItemDialog(ShoppingListModel? activeList, List<ShoppingListItemModel> currentItems) async {
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);

    if (widget.isGuest) {
      // For guest users, ensure an active list exists in local storage
      List<ShoppingListModel> guestLists = await firestoreService.loadGuestShoppingLists();
      if (guestLists.isEmpty) {
        // Create a default guest shopping list if none exists
        final newGuestList = ShoppingListModel(
          id: firestoreService.userId!, // Use the actual anonymous user ID as list ID
          householdId: firestoreService.userId!, // Use the actual anonymous user ID
          name: 'My Guest Shopping List',
          createdAt: DateTime.now(),
          items: [],
          type: 'Manual',
          isActive: true,
        );
        guestLists.add(newGuestList);
        await firestoreService.saveGuestShoppingLists(guestLists);
        // No setState here, StreamBuilder will handle the update
        // Created a new guest shopping list.
      }
    } else {
      // Registered user logic
      if (_householdId == null) {
        // Household not found. Please log in again.
        return;
      }

      // If no active list, try to find or create a default "My Shopping List"
      if (activeList == null) {
        // Check for an existing manual list
        var existingManualListSnapshot = await FirebaseFirestore.instance
            .collection('shoppingLists')
            .where('householdId', isEqualTo: _householdId)
            .where('type', isEqualTo: 'Manual')
            .limit(1)
            .get();

        if (existingManualListSnapshot.docs.isNotEmpty) {
          // Use the existing manual list
          // No setState here, StreamBuilder will handle the update
          // Using existing manual list: ${ShoppingListModel.fromFirestore(existingManualListSnapshot.docs.first).name}
        } else {
          // Create a new default manual list
          final newDefaultList = ShoppingListModel(
            householdId: _householdId!,
            name: 'My Shopping List',
            createdAt: DateTime.now(),
            items: [],
            type: 'Manual',
            isActive: false, // Manual lists are not "active" in the generated sense
          );
          DocumentReference docRef = await FirebaseFirestore.instance.collection('shoppingLists').add(newDefaultList.toFirestore());
          newDefaultList.id = docRef.id;
          // No setState here, StreamBuilder will handle the update
          // Created a new default shopping list.
        }
      }
    }

    // After ensuring activeList is not null (either found or created)
    if (activeList == null) {
      // Could not create or find a shopping list.
      return;
    }

    if (widget.isGuest && currentItems.length >= _maxGuestItems) {
      _showLimitDialog();
      return;
    }

    final formKey = GlobalKey<FormState>();
    final nameFocusNode = FocusNode();
    final nameTextController = TextEditingController();
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
        final DateTime? calculatedExpDate = _shoppingListService.getExpirationDateForCategory(
          selectedCategory!,
          nameTextController.text,
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
                          textEditingController: nameTextController,
                          focusNode: nameFocusNode,
                          optionsBuilder: (TextEditingValue textEditingValue) {
                            if (textEditingValue.text.isEmpty) {
                              return const Iterable<Product>.empty();
                            }
                            return firestoreService.searchProducts(textEditingValue.text).first; // Limit 5 is in FirestoreService
                          },
                          onSelected: (Product selection) {
                            setLocal(() {
                              nameTextController.text = selection.productName;
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
                                if (currentItems.length >= _maxGuestItems) {
                                  _showLimitDialog();
                                  return;
                                }
                                // Check for duplicate item before adding
                                final existingItemIndex = currentItems.indexWhere(
                                  (item) =>
                                      item.name.toLowerCase() == nameTextController.text.trim().toLowerCase() &&
                                      (item.netWeight?.toLowerCase() ?? '') == (sizeCtrl.text.trim().toLowerCase()),
                                );

                                if (existingItemIndex != -1) {
                                  // Duplicate found, increment quantity
                                  final existingItem = currentItems[existingItemIndex];
                                  final updatedItem = existingItem.copyWith(quantity: existingItem.quantity + itemQuantity);
                                  if (activeList != null) {
                                    if (widget.isGuest) {
                                      List<ShoppingListModel> guestLists = await firestoreService.loadGuestShoppingLists();
                                      int activeListIndex = guestLists.indexWhere((list) => list.id == activeList.id);
                                      if (activeListIndex != -1) {
                                        guestLists[activeListIndex].items[existingItemIndex] = updatedItem;
                                        await firestoreService.saveGuestShoppingLists(guestLists);
                                      }
                                    } else {
                                      await _shoppingListService.updateShoppingListItem(activeList.id!, updatedItem);
                                    }
                                  }
                                  // Item already on list. Quantity updated.
                                } else {
                                  // No duplicate, add new item
                                  final newItem = ShoppingListItemModel(
                                    id: widget.isGuest ? _uuid.v4() : null, // Generate ID for guest items
                                    name: nameTextController.text.trim(),
                                    netWeight: sizeCtrl.text.trim().isEmpty ? null : sizeCtrl.text.trim(),
                                    category: selectedCategory!,
                                    unitPrice: double.parse(unitPriceCtrl.text.trim()),
                                    quantity: itemQuantity,
                                    expirationDate: _selectedExpDate, // Use the selected/generated expiration date
                                  );

                                  if (activeList != null) {
                                    if (widget.isGuest) {
                                      List<ShoppingListModel> guestLists = await firestoreService.loadGuestShoppingLists();
                                      int activeListIndex = guestLists.indexWhere((list) => list.id == activeList.id);
                                      if (activeListIndex != -1) {
                                        guestLists[activeListIndex].items.add(newItem);
                                        await firestoreService.saveGuestShoppingLists(guestLists);
                                      }
                                    } else {
                                      await _shoppingListService.addShoppingListItem(activeList.id!, newItem);
                                    }
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
        );
      },
    );
  }

  // ---------- Edit Item Dialog ----------
  Future<void> _showEditItemDialog(ShoppingListItemModel item, ShoppingListModel activeList) async {
    final firestoreService = Provider.of<FirestoreService>(context, listen: false); // Get instance here
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: item.name);
    final sizeCtrl = TextEditingController(text: item.netWeight ?? '');
    final unitPriceCtrl = TextEditingController(text: item.unitPrice.toStringAsFixed(2)); // Add controller for unit price
    final nutritionCtrl = TextEditingController(text: item.nutrition ?? '');
    final expirationDateCtrl = TextEditingController(text: item.expirationDate != null ? DateFormat('MMMM d, yyyy').format(item.expirationDate!) : '');
    String? selectedCategory = item.category;
    int itemQuantity = item.quantity; // Initialize quantity with existing item's quantity
    DateTime? _selectedExpDate = item.expirationDate; // To store the actual expiration date

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

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 40),
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
                          'Price (₱)',
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
                              setLocal(() => selectedCategory = v),
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

                                final updatedItem = item.copyWith(
                                  name: nameCtrl.text.trim(),
                                  netWeight: sizeCtrl.text.trim().isEmpty ? null : sizeCtrl.text.trim(),
                                  category: selectedCategory!,
                                  unitPrice: double.parse(unitPriceCtrl.text.trim()), // Update unit price
                                  quantity: itemQuantity, // Update quantity
                                  expirationDate: _selectedExpDate, // Update expiration date
                                  isPurchased: item.isPurchased, // Preserve existing state
                                  isBookmarked: item.isBookmarked, // Preserve existing state
                                );

                                if (activeList != null) {
                                  if (widget.isGuest) {
                                    List<ShoppingListModel> guestLists = await firestoreService.loadGuestShoppingLists();
                                    int activeListIndex = guestLists.indexWhere((list) => list.id == activeList.id);
                                    if (activeListIndex != -1) {
                                      int itemIndex = guestLists[activeListIndex].items.indexWhere((e) => e.id == item.id);
                                      if (itemIndex != -1) {
                                        guestLists[activeListIndex].items[itemIndex] = updatedItem;
                                        await firestoreService.saveGuestShoppingLists(guestLists);
                                      }
                                    }
                                  } else {
                                    await _shoppingListService.updateShoppingListItem(activeList.id!, updatedItem);
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
        );
      },
    );
  }

  // ---------- Add Item From Suggestion Workflow ----------
  Future<void> _addItemFromSuggestion(_Suggestion suggestion, ShoppingListModel activeList, List<ShoppingListItemModel> currentItems) async {
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);

    if (widget.isGuest && currentItems.length >= _maxGuestItems) {
      _showLimitDialog();
      return;
    }

    // Check for duplicate item before adding
    final existingItemIndex = currentItems.indexWhere(
      (item) =>
          item.name.toLowerCase() == suggestion.name.trim().toLowerCase() &&
          (item.netWeight?.toLowerCase() ?? '') == (suggestion.sizeText?.trim().toLowerCase() ?? ''),
    );

    if (existingItemIndex != -1) {
      // Duplicate found, increment quantity
      final existingItem = currentItems[existingItemIndex];
      final updatedItem = existingItem.copyWith(quantity: existingItem.quantity + 1); // Increment by 1 for suggestion
      if (widget.isGuest) {
        List<ShoppingListModel> guestLists = await firestoreService.loadGuestShoppingLists();
        int activeListIndex = guestLists.indexWhere((list) => list.id == activeList.id);
        if (activeListIndex != -1) {
          guestLists[activeListIndex].items[existingItemIndex] = updatedItem;
          await firestoreService.saveGuestShoppingLists(guestLists);
        }
      } else {
        await _shoppingListService.updateShoppingListItem(activeList.id!, updatedItem);
      }
      // Item already on list. Quantity updated.
    } else {
      // No duplicate, add new item
      final newItem = ShoppingListItemModel(
        id: widget.isGuest ? _uuid.v4() : null, // Generate ID for guest items
        name: suggestion.name.trim(),
        netWeight: suggestion.sizeText?.trim().isEmpty == true ? null : suggestion.sizeText?.trim(),
        category: suggestion.category,
        unitPrice: suggestion.unitPrice, // Use unit price from suggestion
        quantity: 1, // Add 1 item from suggestion
        nutrition: suggestion.nutrition?.trim().isEmpty == true ? null : suggestion.nutrition?.trim(),
        originalPantryItemId: suggestion.originalPantryItemId, // Pass original pantry item ID
        expirationDate: suggestion.expirationDate, // Pass expiration date
      );

      if (widget.isGuest) {
        List<ShoppingListModel> guestLists = await firestoreService.loadGuestShoppingLists();
        int activeListIndex = guestLists.indexWhere((list) => list.id == activeList.id);
        if (activeListIndex != -1) {
          guestLists[activeListIndex].items.add(newItem);
          await firestoreService.saveGuestShoppingLists(guestLists);
        }
      } else {
        await _shoppingListService.addShoppingListItem(activeList.id!, newItem);
      }
    }

    // After adding, update the suggestion status so it's removed from the list
    if (!widget.isGuest && suggestion.originalPantryItemId != null) {
      debugPrint('DEBUG: _addItemFromSuggestion - originalPantryItemId: ${suggestion.originalPantryItemId}');
      debugPrint('DEBUG: _addItemFromSuggestion - Current householdId: $_householdId');

      try {
        // Fetch the pantry item to check its householdId
        final pantryItemDoc = await _firestoreService.db.collection('pantryItems').doc(suggestion.originalPantryItemId).get();
        if (pantryItemDoc.exists) {
          final pantryItemData = pantryItemDoc.data();
          final pantryItemHouseholdId = pantryItemData?['householdId'];
          debugPrint('DEBUG: _addItemFromSuggestion - Pantry item householdId: $pantryItemHouseholdId');
        } else {
          debugPrint('DEBUG: _addItemFromSuggestion - Pantry item with ID ${suggestion.originalPantryItemId} does not exist.');
        }

        await _firestoreService.db.collection('pantryItems').doc(suggestion.originalPantryItemId).update({
          'suggestionStatus': 'Added to List',
        });
        debugPrint('DEBUG: Successfully updated suggestion status for pantry item ${suggestion.originalPantryItemId}.');
      } catch (e) {
        // Handle potential errors, e.g., permission denied
        debugPrint("Error updating suggestion status for pantry item ${suggestion.originalPantryItemId}: $e");
      }
    }
    // No explicit refresh needed, StreamBuilder will handle it
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ShoppingListModel?>(
      stream: _activeShoppingListStream,
      builder: (context, activeListSnapshot) {
        if (activeListSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (activeListSnapshot.hasError) {
          return Center(child: Text('Error: ${activeListSnapshot.error}'));
        }

        final activeList = activeListSnapshot.data;
        final List<ShoppingListItemModel> items = activeList?.items != null
            ? _reorderByBookmark(activeList!.items)
            : [];
        double totalListPrice = items.fold(0.0, (sum, item) => sum + (item.unitPrice * item.quantity));
        debugPrint('DEBUG: Shoppinglist StreamBuilder - Active householdId: $_householdId, Active list name: ${activeList?.name ?? 'N/A'}, Items count: ${items.length}');

        return Column(
          children: [
            // Header
            Divider(height: 1, thickness: 1, color: sep),
            Container(
              width: double.infinity,
              color: softCream,
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Shopping List',
                    style: TextStyle(
                      color: Color(0xFF347928),
                      fontFamily: 'Inter',
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          activeList?.name ?? '',
                          style: TextStyle(
                            color: headerGreen,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          'Total: ₱${totalListPrice.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: headerGreen,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                          textAlign: TextAlign.right,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _GreenPillButton(
                        label: 'Add new Item',
                        onTap: () => _showAddItemDialog(activeList, items),
                        color: headerGreen,
                      ),
                      const SizedBox(width: 10),
                      if (!widget.isGuest)
                        _GreenPillButton(
                          label: 'View All List',
                          color: darkGreen,
                          onTap: () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const Viewalllist()),
                            );
                            // No explicit refresh needed, StreamBuilder will handle it
                          },
                        ),
                      const SizedBox(width: 10),
                      const Spacer(),
                      // === Clear Purchase button ===
                      InkWell(
                        onTap: activeList != null ? () => _clearPurchasedItems(activeList) : null,
                        borderRadius: BorderRadius.circular(10),
                        child: const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Icon(Icons.playlist_add_check, size: 22), // Icon for clear purchase
                        ),
                      ),
                      const SizedBox(width: 10),
                      // === Export button ===
                      InkWell(
                        onTap: activeList != null ? () => _openExportSheet(activeList) : null,
                        borderRadius: BorderRadius.circular(10),
                        child: const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Icon(Icons.file_download_outlined, size: 22),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Divider(height: 1, thickness: 1, color: sep),

            // ------- Suggestions (collapsible) -------
            if (!widget.isGuest) // Hide suggestions for guest users
              StreamBuilder<List<_Suggestion>>(
                stream: _suggestionsStream,
                builder: (context, suggestionsSnapshot) {
                  if (suggestionsSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (suggestionsSnapshot.hasError) {
                    return Center(child: Text('Error: ${suggestionsSnapshot.error}'));
                  }

                  final List<_Suggestion> suggestions = (suggestionsSnapshot.data ?? [])
                      ..sort((a, b) {
                        // "Out of stock" should come before "Low stock"
                        if (a.note == 'Out of stock' && b.note != 'Out of stock') {
                          return -1;
                        } else if (a.note != 'Out of stock' && b.note == 'Out of stock') {
                          return 1;
                        }
                        // For other cases or if both are "Out of stock" or "Low stock", maintain original order
                        return 0;
                      });

                  return Container(
                    color: Colors.white,
                    padding: const EdgeInsets.fromLTRB(16, 10, 8, 8),
                    child: Column(
                      children: [
                        InkWell(
                          onTap: () =>
                              setState(() => _suggestionsOpen = !_suggestionsOpen),
                          borderRadius: BorderRadius.circular(8),
                          child: Row(
                            children: [
                              Text(
                                'Suggestions (${suggestions.length})',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: Colors.grey.shade800,
                                  fontSize: 15.5,
                                ),
                              ),
                              const Spacer(),
                              Icon(
                                _suggestionsOpen
                                    ? Icons.keyboard_arrow_up_rounded
                                    : Icons.keyboard_arrow_down_rounded,
                                color: Colors.grey.shade800,
                              ),
                            ],
                          ),
                        ),
                        AnimatedCrossFade(
                          firstChild: const SizedBox.shrink(),
                          secondChild: Column(
                            children: [
                              const SizedBox(height: 8),
                              Container(
                                constraints: const BoxConstraints(
                                  maxHeight: 220, // Limit height for scrollability
                                ),
                                child: SingleChildScrollView(
                                  child: Column(
                                    children: suggestions.map( // Display all suggestions
                                      (s) => _SuggestionCard(
                                        suggestion: s,
                                        sep: sep,
                                        headerGreen: headerGreen,
                                        firestoreService: Provider.of<FirestoreService>(context, listen: false),
                                        onAdd: (addedSuggestion) async {
                                          if (widget.isGuest && items.length >= _maxGuestItems) {
                                            _showLimitDialog();
                                            return;
                                          }
                                          if (activeList != null) {
                                            await _addItemFromSuggestion(addedSuggestion, activeList, items);
                                          }
                                        },
                                      ),
                                    ).toList(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          crossFadeState: _suggestionsOpen
                              ? CrossFadeState.showSecond
                              : CrossFadeState.showFirst,
                          duration: const Duration(milliseconds: 180),
                          sizeCurve: Curves.easeInOut,
                        ),
                      ],
                    ),
                  );
                },
              ),

            Divider(height: 1, thickness: 1, color: sep),

            // ------- Main list (wrapped for PNG capture) -------
            Expanded(
              child: RepaintBoundary(
                key: _captureKey,
                child: items.isEmpty
                    ? const Center(
                        child: Text(
                          'Your shopping list is empty.',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      )
                    : ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (context, index ) =>
                      Divider(height: 1, thickness: 1, color: sep),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final firestoreService = Provider.of<FirestoreService>(context, listen: false); // Get instance here

                    return Slidable(
                      key: ValueKey(item.id),
                      closeOnScroll: true,
                      endActionPane: ActionPane(
                        motion: const DrawerMotion(), // stops and reveals actions
                        extentRatio: 0.40, // ~40% of tile width for two actions
                        children: [
                          SlidableAction(
                            onPressed: (_) => _showEditItemDialog(item, activeList!),
                            icon: Icons.edit,
                            label: 'Edit',
                            backgroundColor: headerGreen,
                            foregroundColor: Colors.white,
                            borderRadius: BorderRadius.circular(0),
                          ),
                          SlidableAction(
                            onPressed: (_) async { // Mark as async
                              final removed = item;
                              if (activeList != null) {
                                if (widget.isGuest) {
                                  List<ShoppingListModel> guestLists = await firestoreService.loadGuestShoppingLists();
                                  int activeListIndex = guestLists.indexWhere((list) => list.id == activeList.id);
                                  if (activeListIndex != -1) {
                                    guestLists[activeListIndex].items.removeWhere((e) => e.id == removed.id);
                                    await firestoreService.saveGuestShoppingLists(guestLists);
                                  }
                                } else {
                                  await _shoppingListService.removeShoppingListItem(activeList.id!, removed);
                                }
                              }
                            },
                            icon: Icons.delete_outline,
                            label: 'Delete',
                            backgroundColor: Colors.red.shade600,
                            foregroundColor: Colors.white,
                            borderRadius: BorderRadius.circular(0),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.white,
                        child: _ShoppingRow(
                          item: item,
                          headerGreen: headerGreen,
                          onToggleInCart: (v) async {
                            final updatedItem = item.copyWith(isPurchased: v ?? false);
                            if (activeList != null) {
                              if (widget.isGuest) {
                                List<ShoppingListModel> guestLists = await firestoreService.loadGuestShoppingLists();
                                int activeListIndex = guestLists.indexWhere((list) => list.id == activeList.id);
                                if (activeListIndex != -1) {
                                  int itemIndex = guestLists[activeListIndex].items.indexWhere((e) => e.id == item.id);
                                  if (itemIndex != -1) {
                                    guestLists[activeListIndex].items[itemIndex] = updatedItem;
                                    await firestoreService.saveGuestShoppingLists(guestLists);
                                  }
                                }
                              } else {
                                await _shoppingListService.updateShoppingListItem(activeList.id!, updatedItem);
                              }
                            }
                            if (v == true) { // If item is checked, add to pantry
                              await _addPurchasedItemToPantry(updatedItem);
                            }
                          },
                          onToggleBookmark: () async {
                            final updatedItem = item.copyWith(isBookmarked: !item.isBookmarked);
                            if (activeList != null) {
                              if (widget.isGuest) {
                                List<ShoppingListModel> guestLists = await firestoreService.loadGuestShoppingLists();
                                int activeListIndex = guestLists.indexWhere((list) => list.id == activeList.id);
                                if (activeListIndex != -1) {
                                  int itemIndex = guestLists[activeListIndex].items.indexWhere((e) => e.id == item.id);
                                  if (itemIndex != -1) {
                                    guestLists[activeListIndex].items[itemIndex] = updatedItem;
                                    await firestoreService.saveGuestShoppingLists(guestLists);
                                  }
                                }
                              } else {
                                await _shoppingListService.updateShoppingListItem(activeList.id!, updatedItem);
                              }
                            }
                          },
                          onDecrement: () async {
                            if (item.quantity > 0) {
                              final updatedItem = item.copyWith(quantity: item.quantity - 1);
                              if (activeList != null) {
                                if (widget.isGuest) {
                                  List<ShoppingListModel> guestLists = await firestoreService.loadGuestShoppingLists();
                                  int activeListIndex = guestLists.indexWhere((list) => list.id == activeList.id);
                                  if (activeListIndex != -1) {
                                    int itemIndex = guestLists[activeListIndex].items.indexWhere((e) => e.id == item.id);
                                    if (itemIndex != -1) {
                                      guestLists[activeListIndex].items[itemIndex] = updatedItem;
                                      await firestoreService.saveGuestShoppingLists(guestLists);
                                    }
                                  }
                                } else {
                                  await _shoppingListService.updateShoppingListItem(activeList.id!, updatedItem);
                                }
                              }
                            }
                          },
                          onIncrement: () async {
                            final updatedItem = item.copyWith(quantity: item.quantity + 1);
                              if (activeList != null) {
                                if (widget.isGuest) {
                                  List<ShoppingListModel> guestLists = await firestoreService.loadGuestShoppingLists();
                                  int activeListIndex = guestLists.indexWhere((list) => list.id == activeList.id);
                                  if (activeListIndex != -1) {
                                    int itemIndex = guestLists[activeListIndex].items.indexWhere((e) => e.id == item.id);
                                    if (itemIndex != -1) {
                                      guestLists[activeListIndex].items[itemIndex] = updatedItem;
                                      await firestoreService.saveGuestShoppingLists(guestLists);
                                    }
                                  }
                                } else {
                                  await _shoppingListService.updateShoppingListItem(activeList.id!, updatedItem);
                                }
                              }
                          },
                          onDelete: () {}, // kept for compatibility
                          onEdit: () {}, // disabled (no tap-to-edit on name)
                          openFoodFactsService: _openFoodFactsService, // Pass the service
                          firestoreService: firestoreService, // Pass the service
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ======================= Category → Icon helper =======================
IconData iconForCategory(String category) {
  switch (category) {
    case 'Beverages':
      return Icons.local_drink;
    case 'Bakery':
      return Icons.cake; // Changed from bakery_dining
    case 'Canned Goods':
      return Icons.inventory_2;
    case 'Condiments':
      return Icons.kitchen;
    case 'Dairy':
      return Icons.icecream;
    case 'Dry Goods': // New category
      return Icons.grain;
    case 'Snacks':
      return Icons.fastfood;
    case 'Other':
      return Icons.category;
    default:
      return Icons.category;
  }
}

// ======================= Suggestion types/UI =======================
class _Suggestion {
  final String id;
  final String name;
  final String? sizeText;
  final String note;
  final String category;
  final String? nutrition;
  final String? ecoscore; // New: Add ecoscore to _Suggestion model
  final double unitPrice; // Add unitPrice to _Suggestion model
  final String? originalPantryItemId; // New: To link back to the original pantry item
  final DateTime? expirationDate; // New: Expiration date for the item

  _Suggestion({
    required this.id,
    required this.name,
    required this.note,
    required this.category,
    this.sizeText,
    this.nutrition,
    this.ecoscore, // Initialize ecoscore
    this.unitPrice = 0.0, // Default to 0.0 if not provided
    this.originalPantryItemId,
    this.expirationDate,
  });
}

class _SuggestionCard extends StatelessWidget {
  const _SuggestionCard({
    required this.suggestion,
    required this.sep,
    required this.headerGreen,
    required this.onAdd,
    required this.firestoreService, // Add firestoreService parameter
  });

  final _Suggestion suggestion;
  final Color sep;
  final Color headerGreen;
  final Future<void> Function(_Suggestion) onAdd; // Modified to pass suggestion
  final FirestoreService firestoreService; // Declare firestoreService
  
  @override
  Widget build(BuildContext context) {
    String? subline;
    final s = (suggestion.sizeText ?? '').trim();
    if (s.isNotEmpty) {
      subline = s;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: sep),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
          child: Row(
            children: [
              // Category icon for suggestion
              Icon(
                iconForCategory(suggestion.category),
                size: 22,
                color: headerGreen,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      suggestion.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14.5,
                      ),
                    ),
                    if (subline != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subline,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Colors.black87.withAlpha((255 * 0.75).round()),
                          height: 1.1,
                        ),
                      ),
                    ],
                    const SizedBox(height: 2),
                    Text(
                      suggestion.note,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        height: 1.1,
                      ),
                    ),
                    if (suggestion.nutrition != null && suggestion.nutrition!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Nutrition Score: ${suggestion.nutrition!}',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Colors.grey.shade600,
                          fontStyle: FontStyle.italic,
                          height: 1.1,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                onPressed: () async {
                  await onAdd(suggestion); // Pass the suggestion to onAdd
                },
                icon: const Icon(Icons.add_circle_outline_rounded),
                color: headerGreen,
                splashRadius: 20,
                tooltip: 'Add',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ======================= Row =======================
class _ShoppingRow extends StatelessWidget {
  const _ShoppingRow({
    required this.item,
    required this.headerGreen,
    required this.onToggleInCart,
    required this.onToggleBookmark,
    required this.onDecrement,
    required this.onIncrement,
    required this.onDelete,
    required this.onEdit,
    required this.openFoodFactsService, // Add this parameter
    required this.firestoreService, // Add this parameter
  });

  final ShoppingListItemModel item;
  final Color headerGreen;
  final ValueChanged<bool?> onToggleInCart;
  final VoidCallback onToggleBookmark;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;
  final VoidCallback onDelete; // (unused now; kept for compatibility)
  final VoidCallback onEdit;
  final OpenFoodFactsService openFoodFactsService; // Declare the parameter
  final FirestoreService firestoreService; // Declare the parameter

  @override
  Widget build(BuildContext context) {
    final grey = Colors.grey[700];
    final bool selected = item.isPurchased;

    // Compose the "size" subline
    String? subline;
    if (item.netWeight != null && item.netWeight!.trim().isNotEmpty) {
      subline = item.netWeight!.trim();
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // === Pantry-like checkbox behavior (no status change) ===
        Checkbox(
          value: selected,
          onChanged: onToggleInCart,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),

        // === Category icon chip ===
        Container(
          width: 32,
          height: 32,
          margin: const EdgeInsets.only(right: 10),
          decoration: BoxDecoration(
            color: headerGreen.withAlpha((255 * 0.10).round()),
            shape: BoxShape.circle,
          ),
          child: Icon(
            iconForCategory(item.category ?? 'Other'),
            size: 18,
            color: headerGreen,
          ),
        ),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Name with visual indicator when selected
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(
                  item.name,
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
              if (item.nutrition != null && item.nutrition!.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  'Nutrition Score: ${item.nutrition!}',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: selected ? Colors.black45 : Colors.black54,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
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
        Flexible(
          child: Column(
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
        ),
      ],
    );
  }
}

// ======================= Pills =======================
class _GreenPillButton extends StatelessWidget {
  const _GreenPillButton({
    required this.label,
    required this.onTap,
    required this.color,
  });

  final String label;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'Roboto',
              fontSize: 13,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
    );
  }
}
