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
import 'package:shelf_control/screens/viewalllists.dart' hide Text, Navigator;
import 'package:shelf_control/services/shopping_list_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/rendering.dart' show RenderRepaintBoundary;
import 'package:provider/provider.dart'; // Import provider
import 'package:shelf_control/services/firestore_service.dart'; // Import FirestoreService
import 'package:shelf_control/services/open_food_facts_service.dart'; // Import OpenFoodFactsService
import 'package:uuid/uuid.dart'; // Import Uuid for generating unique IDs

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

  // Header key so we can anchor SnackBars right under it (no layout shift)
  final GlobalKey _headerKey = GlobalKey();

  // For PNG export — wrap the list with a RepaintBoundary
  final GlobalKey _captureKey = GlobalKey();

  String _currentTitle = 'Shopping List';
  ShoppingListModel? _activeList;
  String? _householdId;
  final ShoppingListService _shoppingListService = ShoppingListService();
  final OpenFoodFactsService _openFoodFactsService = OpenFoodFactsService();

  // Guest limit
  static const int _maxGuestItems = 15;

  // Listener for FirestoreService changes
  late VoidCallback? _firestoreServiceListener;
  late FirestoreService _firestoreService; // Declare FirestoreService instance

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

  List<ShoppingListItemModel> items = [];

  // --- Add to Pantry Workflow ---
  Future<void> _addCheckedItemsToPantry() async {
    if (_activeList == null || _householdId == null) {
      _showTopSnack("No active shopping list or household selected.");
      return;
    }

    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    final List<ShoppingListItemModel> checkedItems = items.where((item) => item.isPurchased).toList();

    if (checkedItems.isEmpty) {
      _showTopSnack("No items checked to add to pantry.");
      return;
    }

    // Prepare items for batch write
    final List<ShoppingListItemModel> itemsToRemoveFromShoppingList = [];
    final List<PantryItemModel> itemsToAddOrUpdateInPantry = [];
    final List<ShoppingHistoryItemModel> itemsToAddToHistory = [];

    // 1. Optimize duplicate checks in pantry using a single query
    final List<String> itemNames = checkedItems.map((item) => item.name).toList();
    final List<String> itemNetWeights = checkedItems.map((item) => item.netWeight ?? '').toList();

    // Firestore `whereIn` has a limit of 10, so we might need to batch these queries if `checkedItems` is large.
    // For simplicity, assuming `checkedItems` won't exceed the limit for now.
    // A more robust solution would involve splitting `itemNames` into chunks of 10.
    QuerySnapshot existingPantryItemsSnapshot;
    if (itemNames.isNotEmpty) {
      existingPantryItemsSnapshot = await firestoreService.db
          .collection('pantryItems')
          .where('householdId', isEqualTo: _householdId)
          .where('name', whereIn: itemNames.take(10).toList()) // Limit to 10 for whereIn
          .get();
    } else {
      existingPantryItemsSnapshot = await firestoreService.db.collection('pantryItems').where('householdId', isEqualTo: _householdId).limit(0).get(); // Empty snapshot
    }

    final Map<String, PantryItemModel> existingPantryItemsMap = {};
    for (var doc in existingPantryItemsSnapshot.docs) {
      final pantryItem = PantryItemModel.fromFirestore(doc);
      // Create a unique key for comparison (name, brand, netWeight)
      final key = '${pantryItem.name}_${pantryItem.netWeight ?? ''}';
      existingPantryItemsMap[key] = pantryItem;
    }

    for (final checkedItem in checkedItems) {
      final itemKey = '${checkedItem.name}_${checkedItem.netWeight ?? ''}';
      final existingPantryItem = existingPantryItemsMap[itemKey];

      PantryItemModel pantryItem = PantryItemModel(
        id: _uuid.v4(), // Generate new ID for new pantry item
        householdId: _householdId!,
        name: checkedItem.name,
        category: checkedItem.category ?? 'Other', // Provide a default if null
        qty: checkedItem.quantity,
        quantityUnit: checkedItem.netWeight ?? 'pc', // Default unit, changed 'unit' to 'quantityUnit'
        expirationDate: null, // User can set this later
        barcode: null, // If available, could be added
        netWeight: checkedItem.netWeight,
        status: 'Available',
        nutrition: checkedItem.nutrition, // Pass nutrition from shopping list item
      );

      if (existingPantryItem != null) {
        // Duplicate found, ask user what to do
        final choice = await _showDuplicatePantryItemDialog(existingPantryItem, checkedItem);

        if (choice == 'update') {
          // Update quantity of existing item
          pantryItem = existingPantryItem.copyWith(
            qty: existingPantryItem.qty + checkedItem.quantity,
            // timestamp: DateTime.now(), // Removed as PantryItemModel copyWith does not have this parameter
          );
          itemsToAddOrUpdateInPantry.add(pantryItem); // Will be handled as an update
        } else if (choice == 'add_new') {
          // Add as a new item (pantryItem already has a new ID)
          itemsToAddOrUpdateInPantry.add(pantryItem);
        } else {
          // User cancelled or chose not to add
          continue;
        }
      } else {
        // No duplicate, add as new
        itemsToAddOrUpdateInPantry.add(pantryItem);
      }

      // 2. Add to shopping history
      itemsToAddToHistory.add(ShoppingHistoryItemModel(
        householdId: _householdId!,
        productId: checkedItem.productId, // Use productId if available
        productName: checkedItem.name,
        category: checkedItem.category,
        quantity: checkedItem.quantity,
        purchaseDate: DateTime.now(),
        actionType: 'Purchased', // Mark as purchased
      ));

      // 3. Mark for removal from shopping list
      itemsToRemoveFromShoppingList.add(checkedItem);
    }

    // Perform batch writes/updates
    final batch = firestoreService.db.batch();

    // Add/Update pantry items
    for (final item in itemsToAddOrUpdateInPantry) {
      if (item.id != null && item.id!.isNotEmpty && items.any((e) => e.id == item.id)) { // Check if it's an update to an existing item
        batch.update(firestoreService.db.collection('pantryItems').doc(item.id), item.toFirestore());
      } else {
        batch.set(firestoreService.db.collection('pantryItems').doc(item.id), item.toFirestore());
      }
    }

    // Add to shopping history
    for (final item in itemsToAddToHistory) {
      batch.set(firestoreService.db.collection('shoppingHistory').doc(), item.toFirestore());
    }

    await batch.commit();

    // Update transferred items in the shopping list subcollection to be purchased
    // and remove them from the local list if the user chooses to clear them later.
    for (final item in itemsToRemoveFromShoppingList) {
      final updatedItem = item.copyWith(isPurchased: true);
      await _shoppingListService.updateShoppingListItem(_activeList!.id!, updatedItem);
    }

    // Update the local state to reflect items as purchased
    setState(() {
      for (final itemToUpdate in itemsToRemoveFromShoppingList) {
        final index = items.indexWhere((item) => item.id == itemToUpdate.id);
        if (index != -1) {
          items[index] = items[index].copyWith(isPurchased: true);
        }
      }
    });

    if (widget.isGuest) {
      // For guest mode, update the local guest list
      List<ShoppingListModel> guestLists = await firestoreService.loadGuestShoppingLists();
      int activeListIndex = guestLists.indexWhere((list) => list.id == _activeList!.id);
      if (activeListIndex != -1) {
        guestLists[activeListIndex].items.removeWhere((item) => itemsToRemoveFromShoppingList.contains(item));
        await firestoreService.saveGuestShoppingLists(guestLists);
      }
    }

    _showTopSnack("Checked items added to pantry and history!");
    _fetchHouseholdAndListsAndSuggestions(); // Refresh all data
  }

  Future<String?> _showDuplicatePantryItemDialog(PantryItemModel existingItem, ShoppingListItemModel newItem) async {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Duplicate Item in Pantry'),
          content: Text(
            '"${newItem.name}" (Qty: ${newItem.quantity}) is already in your pantry (Qty: ${existingItem.qty}). '
            'Do you want to update the quantity of the existing item or add it as a new entry?',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(null); // User cancelled
              },
            ),
            TextButton(
              child: const Text('Add as New'),
              onPressed: () {
                Navigator.of(context).pop('add_new');
              },
            ),
            ElevatedButton(
              child: const Text('Update Quantity'),
              onPressed: () {
                Navigator.of(context).pop('update');
              },
            ),
          ],
        );
      },
    );
  }

  // ------- Suggestions dropdown (collapsible) -------
  bool _suggestionsOpen = true;

  /// Suggestions now include optional brand & size
  List<_Suggestion> _suggestions = [];

  @override
  void initState() {
    super.initState();
    _firestoreService = Provider.of<FirestoreService>(context, listen: false); // Initialize here
    _firestoreServiceListener = () {
      if (!mounted) return;
      if (!widget.isGuest && _householdId != _firestoreService.selectedHouseholdId) {
        setState(() {
          _householdId = _firestoreService.selectedHouseholdId;
        });
        _fetchShoppingData();
      }
    };

    // Add the listener
    _firestoreService.addListener(_firestoreServiceListener!);

    // Initial fetch
    _fetchShoppingData();
  }

  @override
  void dispose() {
    if (_firestoreServiceListener != null) {
      // Ensure not to listen when removing the listener in dispose
      _firestoreService.removeListener(_firestoreServiceListener!); // Use the stored instance
    }
    super.dispose();
  }

  Future<void> _fetchShoppingData() async {
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);

    if (widget.isGuest) {
      // Load guest shopping lists from local storage
      List<ShoppingListModel> guestLists = await firestoreService.loadGuestShoppingLists();
      if (!mounted) return;
      setState(() {
        if (guestLists.isNotEmpty) {
          // For guests, we'll just use the first list as the "active" one for simplicity
          _activeList = guestLists.first;
          _currentTitle = _activeList!.name;
          items = _activeList!.items.map((e) => e.copyWith()).toList();
          _reorderByBookmark();
        } else {
          _activeList = null;
          _currentTitle = 'Shopping List';
          items = [];
        }
        _suggestions = []; // Guests don't get suggestions
      });
    } else {
      // Registered user logic
      _householdId = firestoreService.selectedHouseholdId;

      if (_householdId != null) {
        // Fetch the household document to get the activeShoppingListId
        DocumentSnapshot householdDoc = await FirebaseFirestore.instance
            .collection('households')
            .doc(_householdId)
            .get();

        ShoppingListModel? fetchedActiveList;
        if (householdDoc.exists) {
          String? activeListId = (householdDoc.data() as Map<String, dynamic>?)?['activeShoppingListId'];
          if (activeListId != null && activeListId.isNotEmpty) {
            // Directly fetch the active shopping list using its ID
            DocumentSnapshot activeListDoc = await FirebaseFirestore.instance
                .collection('shoppingLists')
                .doc(activeListId)
                .get();
            if (activeListDoc.exists) {
              fetchedActiveList = ShoppingListModel.fromFirestore(activeListDoc);
            }
          }
        }

        ShoppingListModel? resolvedActiveList;
        List<ShoppingListItemModel> fetchedItems = [];

        if (fetchedActiveList != null) {
          resolvedActiveList = fetchedActiveList;
          fetchedItems = resolvedActiveList.items; // Directly use items from the model
        } else {
          // Fallback: if no activeListId or list not found, query for an active list
          var snapshot = await FirebaseFirestore.instance
              .collection('shoppingLists')
              .where('householdId', isEqualTo: _householdId)
              .where('isActive', isEqualTo: true)
              .limit(1)
              .get();

          if (snapshot.docs.isNotEmpty) {
            resolvedActiveList = ShoppingListModel.fromFirestore(snapshot.docs.first);
            fetchedItems = resolvedActiveList.items; // Directly use items from the model
          }
        }

        if (!mounted) return;
        setState(() {
          _activeList = resolvedActiveList;
          _currentTitle = _activeList?.name ?? 'Shopping List';
          items = fetchedItems;
          _reorderByBookmark();
        });

        // Fetch suggestions
        await _fetchSuggestions();
      } else {
        if (!mounted) return;
        setState(() {
          _activeList = null;
          _currentTitle = 'Shopping List';
          items = [];
          _suggestions = [];
        });
      }
    }
  }

  Future<void> _fetchSuggestions() async {
    if (!widget.isGuest && _householdId != null) {
      List<ShoppingListItemModel> generatedSuggestions = await _shoppingListService.generateHassleFreeSuggestions(_householdId!);
      setState(() {
        _suggestions = generatedSuggestions.map((item) => _Suggestion(
          name: item.name,
          sizeText: item.netWeight,
          note: 'Suggested',
          category: item.category ?? 'Other',
          nutrition: item.nutrition
        )).toList();
      });
    } else {
      setState(() {
        _suggestions = [];
      });
    }
  }

  Future<void> _fetchHouseholdAndListsAndSuggestions() async {
    await _fetchShoppingData();
    if (!widget.isGuest) {
      await _fetchSuggestions();
    }
  }

  // ---------- Helpers: compute top margin under header ----------
  double _topSnackMargin() {
    final messengerTop = MediaQuery.of(context).padding.top;
    final render = _headerKey.currentContext?.findRenderObject() as RenderBox?;
    final headerHeight = render?.size.height ?? 0;
    // +8px breathing room under the header
    return messengerTop + headerHeight + 8;
  }

  // ---------- toast-style snack (top, floating, no layout shift) ----------
  void _showTopSnack(String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        dismissDirection: DismissDirection.up,
        margin: EdgeInsets.fromLTRB(16, _topSnackMargin(), 16, 0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }


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

  void _reorderByBookmark() {
    final bookmarked = <ShoppingListItemModel>[];
    final others = <ShoppingListItemModel>[];
    for (final it in items) {
      (it.isBookmarked ? bookmarked : others).add(it);
    }
    items
      ..clear()
      ..addAll(bookmarked)
      ..addAll(others);
  }

  // ---------- Export helpers ----------
  String _asPlainText() {
    final buf = StringBuffer()
      ..writeln(_currentTitle)
      ..writeln('-' * _currentTitle.length)
      ..writeln();

    for (final it in items) {
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

  Future<void> _exportAsTxt() async {
    try {
      final text = _asPlainText();
      final bytes = Uint8List.fromList(utf8.encode(text));
      final file = await _writeTemp(
        bytes,
        '${_currentTitle.replaceAll(' ', '_').toLowerCase()}.txt',
      );
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'text/plain')],
          subject: 'Shopping List',
        ),
      );
    } catch (e) {
      _showTopSnack('Failed to export TXT: $e');
    }
  }

  Future<void> _exportAsPng() async {
    try {
      final png = await _capturePng();
      final file = await _writeTemp(
        png,
        '${_currentTitle.replaceAll(' ', '_').toLowerCase()}.png',
      );
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'image/png')],
          subject: 'Shopping List',
        ),
      );
    } catch (e) {
      _showTopSnack('Failed to export PNG: $e');
    }
  }

  void _openExportSheet() {
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
                    'Export "$_currentTitle"',
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
                    _exportAsTxt();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.image_outlined),
                  title: const Text('Export as PNG'),
                  subtitle: const Text('Share an image of the list'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _exportAsPng();
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
  Future<void> _showAddItemDialog() async {
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);

    if (widget.isGuest) {
      // For guest users, ensure an active list exists in local storage
      List<ShoppingListModel> guestLists = await firestoreService.loadGuestShoppingLists();
      if (guestLists.isEmpty) {
        // Create a default guest shopping list if none exists
        final newGuestList = ShoppingListModel(
          id: 'guest_shopping_list', // A fixed ID for the guest list
          householdId: 'guest_household', // Dummy household ID for guests
          name: 'My Guest Shopping List',
          createdAt: DateTime.now(),
          items: [],
          type: 'Manual',
          isActive: true,
        );
        guestLists.add(newGuestList);
        await firestoreService.saveGuestShoppingLists(guestLists);
        setState(() {
          _activeList = newGuestList;
          _currentTitle = _activeList!.name;
          items = _activeList!.items.map((e) => e.copyWith()).toList();
          _reorderByBookmark();
        });
        _showTopSnack("Created a new guest shopping list.");
      } else {
        // Use the first existing guest list as the active one
        setState(() {
          _activeList = guestLists.first;
          _currentTitle = _activeList!.name;
          items = _activeList!.items.map((e) => e.copyWith()).toList();
          _reorderByBookmark();
        });
      }
    } else {
      // Registered user logic
      if (_householdId == null) {
        _showTopSnack("Household not found. Please log in again.");
        return;
      }

      // If no active list, try to find or create a default "My Shopping List"
      if (_activeList == null) {
        // Check for an existing manual list
        var existingManualListSnapshot = await FirebaseFirestore.instance
            .collection('shoppingLists')
            .where('householdId', isEqualTo: _householdId)
            .where('type', isEqualTo: 'Manual')
            .limit(1)
            .get();

        if (existingManualListSnapshot.docs.isNotEmpty) {
          // Use the existing manual list
          setState(() {
            _activeList = ShoppingListModel.fromFirestore(existingManualListSnapshot.docs.first);
            _currentTitle = _activeList!.name;
            items = _activeList!.items;
            _reorderByBookmark();
          });
          _showTopSnack("Using existing manual list: ${_activeList!.name}");
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

          setState(() {
            _activeList = newDefaultList;
            _currentTitle = _activeList!.name;
            items = _activeList!.items.map((e) => e.copyWith()).toList(); // Deep copy items
            _reorderByBookmark();
          });
          _showTopSnack("Created a new default shopping list.");
        }
      }
    }

    // After ensuring _activeList is not null (either found or created)
    if (_activeList == null) {
      _showTopSnack("Could not create or find a shopping list.");
      return;
    }

    if (widget.isGuest && items.length >= _maxGuestItems) {
      _showLimitDialog();
      return;
    }

    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final sizeCtrl = TextEditingController();
    final unitPriceCtrl = TextEditingController(text: '0.00');
    final nutritionCtrl = TextEditingController();
    String? selectedCategory;

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
                          'Brand (optional)',
                          style: TextStyle(
                            color: headerGreen,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Size / Weight (e.g., 150g, 1L) – optional',
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
                          'Nutrition (optional)',
                          style: TextStyle(
                            color: headerGreen,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: nutritionCtrl,
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
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            InkWell(
                              onTap: () async {
                                if (!formKey.currentState!.validate()) return;
                          if (items.length >= _maxGuestItems) {
                            _showLimitDialog();
                            return;
                          }
                                // Check for duplicate item before adding
                                final existingItemIndex = items.indexWhere(
                                  (item) =>
                                      item.name.toLowerCase() == nameCtrl.text.trim().toLowerCase() &&
                                      (item.netWeight?.toLowerCase() ?? '') == (sizeCtrl.text.trim().toLowerCase()),
                                );

                                if (existingItemIndex != -1) {
                                  // Duplicate found, increment quantity
                                  final existingItem = items[existingItemIndex];
                                  final updatedItem = existingItem.copyWith(quantity: existingItem.quantity + 1);
                                  setState(() {
                                    items[existingItemIndex] = updatedItem;
                                  });
                                  if (_activeList != null) {
                                    if (widget.isGuest) {
                                      List<ShoppingListModel> guestLists = await firestoreService.loadGuestShoppingLists();
                                      int activeListIndex = guestLists.indexWhere((list) => list.id == _activeList!.id);
                                      if (activeListIndex != -1) {
                                        guestLists[activeListIndex].items[existingItemIndex] = updatedItem;
                                        await firestoreService.saveGuestShoppingLists(guestLists);
                                      }
                                    } else {
                                      await _shoppingListService.updateShoppingListItem(_activeList!.id!, updatedItem);
                                    }
                                  }
                                  _showTopSnack("Item already on list. Quantity updated.");
                                } else {
                                  // No duplicate, add new item
                                  final newItem = ShoppingListItemModel(
                                    id: widget.isGuest ? _uuid.v4() : null, // Generate ID for guest items
                                    name: nameCtrl.text.trim(),
                                    netWeight: sizeCtrl.text.trim().isEmpty ? null : sizeCtrl.text.trim(),
                                    category: selectedCategory!,
                                    unitPrice: double.parse(unitPriceCtrl.text.trim()),
                                    quantity: 1,
                                    nutrition: nutritionCtrl.text.trim().isEmpty ? null : nutritionCtrl.text.trim(),
                                  );

                                  if (_activeList != null) {
                                    if (widget.isGuest) {
                                      List<ShoppingListModel> guestLists = await firestoreService.loadGuestShoppingLists();
                                      int activeListIndex = guestLists.indexWhere((list) => list.id == _activeList!.id);
                                      if (activeListIndex != -1) {
                                        guestLists[activeListIndex].items.add(newItem);
                                        await firestoreService.saveGuestShoppingLists(guestLists);
                                      }
                                    } else {
                                      await _shoppingListService.addShoppingListItem(_activeList!.id!, newItem);
                                    }
                                  }
                                }
                                await _fetchHouseholdAndListsAndSuggestions(); // Refresh the list
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
  Future<void> _showEditItemDialog(ShoppingListItemModel item) async {
    final firestoreService = Provider.of<FirestoreService>(context, listen: false); // Get instance here
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: item.name);
    final sizeCtrl = TextEditingController(text: item.netWeight ?? '');
    final nutritionCtrl = TextEditingController(text: item.nutrition ?? '');
    String? selectedCategory = item.category;

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
                          'Brand (optional)',
                          style: TextStyle(
                            color: headerGreen,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Size / Weight (optional)',
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
                          'Nutrition (optional)',
                          style: TextStyle(
                            color: headerGreen,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: nutritionCtrl,
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
                                  nutrition: nutritionCtrl.text.trim().isEmpty ? null : nutritionCtrl.text.trim(),
                                  isPurchased: item.isPurchased, // Preserve existing state
                                  isBookmarked: item.isBookmarked, // Preserve existing state
                                );

                                setState(() {
                                  final index = items.indexWhere((e) => e.id == item.id);
                                  if (index != -1) {
                                    items[index] = updatedItem;
                                  }
                                });

                                if (_activeList != null) {
                                  if (widget.isGuest) {
                                    List<ShoppingListModel> guestLists = await firestoreService.loadGuestShoppingLists();
                                    int activeListIndex = guestLists.indexWhere((list) => list.id == _activeList!.id);
                                    if (activeListIndex != -1) {
                                      int itemIndex = guestLists[activeListIndex].items.indexWhere((e) => e.id == item.id);
                                      if (itemIndex != -1) {
                                        guestLists[activeListIndex].items[itemIndex] = updatedItem;
                                        await firestoreService.saveGuestShoppingLists(guestLists);
                                      }
                                    }
                                  } else {
                                    await _shoppingListService.updateShoppingListItem(_activeList!.id!, updatedItem);
                                  }
                                  await _fetchHouseholdAndListsAndSuggestions(); // Refresh the list
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


  @override
  Widget build(BuildContext context) {
    double totalListPrice = items.fold(0.0, (sum, item) => sum + (item.unitPrice * item.quantity));

    return Column(
      children: [
        // Header
        Divider(height: 1, thickness: 1, color: sep),
        Container(
          key: _headerKey, // <-- anchor for top snackbars
          width: double.infinity,
          color: softCream,
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ===== NEW: show the current main list title if available =====
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                  Text(
                    'Total: ₱${totalListPrice.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: headerGreen,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              if (_activeList != null && _activeList!.name != 'Shopping List') ...[
                Text(
                  _activeList!.name,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  _GreenPillButton(
                    label: 'Add new Item',
                    onTap: _showAddItemDialog,
                    color: headerGreen,
                  ),
                  const SizedBox(width: 10),
                  _GreenPillButton(
                    label: 'View All List',
                    color: darkGreen,
                    onTap: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const Viewalllist()),
                      );
                      _fetchHouseholdAndListsAndSuggestions(); // Refresh active list when returning
                    },
                  ),
                  const SizedBox(width: 10),
                  if (items.any((item) => item.isPurchased)) ...[
                    // Add Checked to Pantry Icon
                    IconButton(
                      tooltip: 'Add Checked to Pantry',
                      icon: Icon(Icons.inventory_2_outlined, color: headerGreen, size: 28),
                      onPressed: () async {
                        await _addCheckedItemsToPantry();
                      },
                    ),
                    const SizedBox(width: 10),
                    _GreenPillButton(
                      label: 'Clear Purchased',
                      color: darkGreen,
                      onTap: () async {
                        if (_activeList == null || _householdId == null) {
                          _showTopSnack("No active shopping list or household selected.");
                          return;
                        }
                        final List<ShoppingListItemModel> purchasedItems = items.where((item) => item.isPurchased).toList();
                        if (purchasedItems.isEmpty) {
                          _showTopSnack("No purchased items to clear.");
                          return;
                        }

                        for (final item in purchasedItems) {
                          await _shoppingListService.removeShoppingListItem(_activeList!.id!, item.id!);
                        }

                        setState(() {
                          items.removeWhere((item) => item.isPurchased);
                        });

                        if (widget.isGuest) {
                          List<ShoppingListModel> guestLists = await Provider.of<FirestoreService>(context, listen: false).loadGuestShoppingLists();
                          int activeListIndex = guestLists.indexWhere((list) => list.id == _activeList!.id);
                          if (activeListIndex != -1) {
                            guestLists[activeListIndex].items.removeWhere((item) => item.isPurchased);
                            await Provider.of<FirestoreService>(context, listen: false).saveGuestShoppingLists(guestLists);
                          }
                        }
                        _showTopSnack("Purchased items cleared from list.");
                        _fetchHouseholdAndListsAndSuggestions(); // Refresh all data
                      },
                    ),
                  ],
                  const Spacer(),
                  // === Export button (changed icon) ===
                  InkWell(
                    onTap: _openExportSheet,
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
        Container(
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
                      'Suggestions (${_suggestions.length})',
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
                    ..._suggestions.map(
                      (s) => _SuggestionCard(
                        suggestion: s,
                        sep: sep,
                        headerGreen: headerGreen,
                        firestoreService: Provider.of<FirestoreService>(context, listen: false), // Pass firestoreService
                        onAdd: (addedSuggestion) async {
                          if (items.length >= _maxGuestItems) {
                            _showLimitDialog();
                            return;
                          }
                          final newItem = ShoppingListItemModel(
                            id: null, // Let the service generate the ID
                            name: addedSuggestion.name,
                            netWeight: addedSuggestion.sizeText,
                            category: addedSuggestion.category,
                            unitPrice: 0, // Default price
                            quantity: 1,
                            nutrition: addedSuggestion.nutrition, // Pass nutrition from suggestion
                          );

                          if (_activeList != null) {
                            // Check for duplicate item before adding from suggestion
                            final existingItemIndex = items.indexWhere(
                              (item) =>
                                  item.name.toLowerCase() == addedSuggestion.name.toLowerCase() &&
                                  (item.netWeight?.toLowerCase() ?? '') == (addedSuggestion.sizeText?.toLowerCase() ?? ''),
                            );

                            if (existingItemIndex != -1) {
                              // Duplicate found, increment quantity
                              final existingItem = items[existingItemIndex];
                              final updatedItem = existingItem.copyWith(quantity: existingItem.quantity + 1);
                              setState(() {
                                items[existingItemIndex] = updatedItem;
                              });
                              if (widget.isGuest) {
                                List<ShoppingListModel> guestLists = await Provider.of<FirestoreService>(context, listen: false).loadGuestShoppingLists();
                                int activeListIndex = guestLists.indexWhere((list) => list.id == _activeList!.id);
                                if (activeListIndex != -1) {
                                  guestLists[activeListIndex].items[existingItemIndex] = updatedItem;
                                  await Provider.of<FirestoreService>(context, listen: false).saveGuestShoppingLists(guestLists);
                                }
                              } else {
                                await _shoppingListService.updateShoppingListItem(_activeList!.id!, updatedItem);
                              }
                              _showTopSnack("Item already on list. Quantity updated.");
                            } else {
                              // No duplicate, add new item
                              await _shoppingListService.addShoppingListItem(_activeList!.id!, newItem);
                            }
                            await _fetchHouseholdAndListsAndSuggestions(); // Refresh the list
                          }
                          // Remove the suggestion after it's added or quantity updated
                          setState(() {
                            _suggestions.remove(addedSuggestion);
                          });
                        },
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
        ),

        Divider(height: 1, thickness: 1, color: sep),

        // ------- Main list (wrapped for PNG capture) -------
        Expanded(
          child: RepaintBoundary(
            key: _captureKey,
            child: ListView.separated(
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
                        onPressed: (_) => _showEditItemDialog(item),
                        icon: Icons.edit,
                        label: 'Edit',
                        backgroundColor: headerGreen,
                        foregroundColor: Colors.white,
                        borderRadius: BorderRadius.circular(0),
                      ),
                      SlidableAction(
                        onPressed: (_) async { // Mark as async
                          final removed = item;
                          if (_activeList != null) {
                            if (widget.isGuest) {
                              List<ShoppingListModel> guestLists = await firestoreService.loadGuestShoppingLists();
                              int activeListIndex = guestLists.indexWhere((list) => list.id == _activeList!.id);
                              if (activeListIndex != -1) {
                                guestLists[activeListIndex].items.removeWhere((e) => e.id == removed.id);
                                await firestoreService.saveGuestShoppingLists(guestLists);
                              }
                            } else {
                              await _shoppingListService.removeShoppingListItem(_activeList!.id!, removed.id!);
                            }
                          }
                          setState(() => items.removeWhere((e) => e.id == removed.id)); // Remove by ID
                        },
                        icon: Icons.delete_outline,
                        label: 'Delete',
                        backgroundColor: Colors.red.shade600,
                        foregroundColor: Colors.white,
                        borderRadius: BorderRadius.circular(0),
                      ),
                    ],
                  ),
                  // === Pantry-style overlay to indicate selection ===
                  child: Material(
                    color: Colors.white,
                    child: Stack(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          child: _ShoppingRow(
                            item: item,
                            headerGreen: headerGreen,
                            onToggleInCart: (v) async {
                              final updatedItem = item.copyWith(isPurchased: v ?? false);
                              setState(() {
                                final index = items.indexWhere((e) => e.id == item.id);
                                if (index != -1) items[index] = updatedItem;
                              });
                              if (_activeList != null) {
                                if (widget.isGuest) {
                                  List<ShoppingListModel> guestLists = await firestoreService.loadGuestShoppingLists();
                                  int activeListIndex = guestLists.indexWhere((list) => list.id == _activeList!.id);
                                  if (activeListIndex != -1) {
                                    int itemIndex = guestLists[activeListIndex].items.indexWhere((e) => e.id == item.id);
                                    if (itemIndex != -1) {
                                      guestLists[activeListIndex].items[itemIndex] = updatedItem;
                                      await firestoreService.saveGuestShoppingLists(guestLists);
                                    }
                                  }
                                } else {
                                  await _shoppingListService.updateShoppingListItem(_activeList!.id!, updatedItem);
                                }
                              }
                            },
                            onToggleBookmark: () async {
                              final updatedItem = item.copyWith(isBookmarked: !item.isBookmarked);
                              setState(() {
                                final index = items.indexWhere((e) => e.id == item.id);
                                if (index != -1) items[index] = updatedItem;
                                _reorderByBookmark();
                              });
                              if (_activeList != null) {
                                if (widget.isGuest) {
                                  List<ShoppingListModel> guestLists = await firestoreService.loadGuestShoppingLists();
                                  int activeListIndex = guestLists.indexWhere((list) => list.id == _activeList!.id);
                                  if (activeListIndex != -1) {
                                    int itemIndex = guestLists[activeListIndex].items.indexWhere((e) => e.id == item.id);
                                    if (itemIndex != -1) {
                                      guestLists[activeListIndex].items[itemIndex] = updatedItem;
                                      await firestoreService.saveGuestShoppingLists(guestLists);
                                    }
                                  }
                                } else {
                                  await _shoppingListService.updateShoppingListItem(_activeList!.id!, updatedItem);
                                }
                              }
                            },
                            onDecrement: () async {
                              if (item.quantity > 0) {
                                final updatedItem = item.copyWith(quantity: item.quantity - 1);
                                setState(() {
                                  final index = items.indexWhere((e) => e.id == item.id);
                                  if (index != -1) items[index] = updatedItem;
                                });
                                if (_activeList != null) {
                                  if (widget.isGuest) {
                                    List<ShoppingListModel> guestLists = await firestoreService.loadGuestShoppingLists();
                                    int activeListIndex = guestLists.indexWhere((list) => list.id == _activeList!.id);
                                    if (activeListIndex != -1) {
                                      int itemIndex = guestLists[activeListIndex].items.indexWhere((e) => e.id == item.id);
                                      if (itemIndex != -1) {
                                        guestLists[activeListIndex].items[itemIndex] = updatedItem;
                                        await firestoreService.saveGuestShoppingLists(guestLists);
                                      }
                                    }
                                  } else {
                                    await _shoppingListService.updateShoppingListItem(_activeList!.id!, updatedItem);
                                  }
                                }
                              }
                            },
                            onIncrement: () async {
                              final updatedItem = item.copyWith(quantity: item.quantity + 1);
                              setState(() {
                                final index = items.indexWhere((e) => e.id == item.id);
                                if (index != -1) items[index] = updatedItem;
                              });
                                if (_activeList != null) {
                                  if (widget.isGuest) {
                                    List<ShoppingListModel> guestLists = await firestoreService.loadGuestShoppingLists();
                                    int activeListIndex = guestLists.indexWhere((list) => list.id == _activeList!.id);
                                    if (activeListIndex != -1) {
                                      int itemIndex = guestLists[activeListIndex].items.indexWhere((e) => e.id == item.id);
                                      if (itemIndex != -1) {
                                        guestLists[activeListIndex].items[itemIndex] = updatedItem;
                                        await firestoreService.saveGuestShoppingLists(guestLists);
                                      }
                                    }
                                  } else {
                                    await _shoppingListService.updateShoppingListItem(_activeList!.id!, updatedItem);
                                  }
                                }
                            },
                            onDelete: () {}, // kept for compatibility
                            onEdit: () {}, // disabled (no tap-to-edit on name)
                            openFoodFactsService: _openFoodFactsService, // Pass the service
                            firestoreService: firestoreService, // Pass the service
                          ),
                        ),
                        if (item.isPurchased)
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
        ),
      ],
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
    case 'Beverages':
      return Icons.local_drink;
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
  final String name;
  final String? sizeText;
  final String note;
  final String category;
  final String? nutrition; // keep this

  _Suggestion({
    required this.name,
    required this.note,
    required this.category,
    this.sizeText,
    this.nutrition, 
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
                    if (suggestion.nutrition != null && suggestion.nutrition!.isNotEmpty)
                      Text(
                        'Nutri-score: ${suggestion.nutrition!.toUpperCase()}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade600,
                        ),
                      ),
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
              if (item.nutrition != null && item.nutrition!.isNotEmpty)
                Text(
                  'Nutri-score: ${item.nutrition!.toUpperCase()}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: selected ? Colors.grey.shade500 : Colors.grey.shade600,
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
