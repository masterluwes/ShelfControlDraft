import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import FirebaseAuth
import 'package:shelf_control/models/pantry_item_model.dart';
import 'package:shelf_control/models/shopping_history_item_model.dart';
import 'package:shelf_control/models/shopping_list_item_model.dart';
import 'package:shelf_control/models/shopping_list_model.dart';
import 'package:shelf_control/services/open_food_facts_service.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Import SharedPreferences
import 'dart:convert'; // For JSON encoding/decoding
import 'package:uuid/uuid.dart'; // For generating unique IDs
import 'package:shelf_control/services/firestore_service.dart'; // Import FirestoreService
import 'package:shelf_control/models/user_prefs_model.dart'; // Import UserPrefsModel
import 'package:flutter/foundation.dart'; // Import for debugPrint
import 'package:intl/intl.dart'; // Import for DateFormat

class ShoppingListService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final OpenFoodFactsService _openFoodFactsService;
  final Uuid _uuid;
  final FirestoreService _firestoreService; // Changed to final

  ShoppingListService({required FirestoreService firestoreService})
      : _firestore = FirebaseFirestore.instance,
        _auth = FirebaseAuth.instance,
        _openFoodFactsService = OpenFoodFactsService(),
        _uuid = const Uuid(),
        _firestoreService = firestoreService; // Initialize _firestoreService in constructor

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

  // Helper to suggest category from item name
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

  // Helper to get expiration date based on category and item name
  DateTime? getExpirationDateForCategory(String category, String itemName, DateTime manufacturedDate) {
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

  // Setter for FirestoreService is no longer needed as it's injected via constructor
  // void setFirestoreService(FirestoreService service) {
  //   _firestoreService = service;
  // }

  // Helper to get a reference to the collections
  CollectionReference get _shoppingLists => _firestore.collection('shoppingLists');
  CollectionReference get _shoppingHistory => _firestore.collection('shoppingHistory');
  CollectionReference get _localProducts => _firestore.collection('local_products_ph');

  static const String _guestShoppingListKey = 'guestShoppingLists';

  // Save guest shopping lists to local storage
  Future<void> saveGuestShoppingLists(List<ShoppingListModel> lists) async {
    final prefs = await SharedPreferences.getInstance();
    final String encodedData = json.encode(lists.map((list) => list.toFirestore()).toList());
    await prefs.setString(_guestShoppingListKey, encodedData);
  }

  // Load guest shopping lists from local storage
  Future<List<ShoppingListModel>> loadGuestShoppingLists() async {
    final prefs = await SharedPreferences.getInstance();
    final String? encodedData = prefs.getString(_guestShoppingListKey);
    if (encodedData == null) {
      return [];
    }
    final List<dynamic> decodedData = json.decode(encodedData);
    return decodedData.map((data) => ShoppingListModel.fromFirestore(data)).toList();
  }

  // Get a single shopping list by ID, including its items from the array
  Future<ShoppingListModel?> getShoppingListById(String listId) async {
    if (_auth.currentUser?.isAnonymous ?? false) {
      // For guest users, retrieve from local storage
      List<ShoppingListModel> guestLists = await loadGuestShoppingLists();
      return guestLists.firstWhere(
        (list) => list.id == listId,
        orElse: () => ShoppingListModel(
          id: listId,
          name: '',
          householdId: '',
          createdAt: DateTime.now(),
          items: [],
          type: 'Manual',
        ),
      );
    }

    DocumentSnapshot listDoc = await _shoppingLists.doc(listId).get();

    if (listDoc.exists) {
      return ShoppingListModel.fromFirestore(listDoc);
    }
    return null;
  }

  // Add an item to a shopping list (now uses array within the document)
  Future<void> addShoppingListItem(String listId, ShoppingListItemModel item) async {
    if (_auth.currentUser?.isAnonymous ?? false) {
      List<ShoppingListModel> guestLists = await loadGuestShoppingLists();
      int listIndex = guestLists.indexWhere((list) => list.id == listId);
      if (listIndex != -1) {
        ShoppingListModel targetList = guestLists[listIndex];
        ShoppingListItemModel itemWithId = item.copyWith(id: item.id?.isEmpty ?? true ? _uuid.v4() : item.id!);
        targetList.items.add(itemWithId);
        await saveGuestShoppingLists(guestLists);
      }
    } else {
      DocumentReference listRef = _shoppingLists.doc(listId);
      ShoppingListItemModel itemWithId = item.copyWith(id: item.id?.isEmpty ?? true ? _uuid.v4() : item.id!);
      await listRef.update({
        'items': FieldValue.arrayUnion([itemWithId.toMap()])
      });
    }
  }

  // Add or Update an item in a shopping list
  Future<void> addOrUpdateItem({
    required String householdId,
    required String itemName,
    required int quantity,
    String? category,
    String? netWeight,
    double? unitPrice,
  }) async {
    final String? activeListId = await _firestoreService.getActiveShoppingListId(householdId);
    if (activeListId == null) {
      // Handle case where no active shopping list is found, maybe create a default one
      // For now, we'll throw an error or return
      throw Exception('No active shopping list found for household $householdId');
    }

    ShoppingListModel? activeList = await getShoppingListById(activeListId);
    if (activeList == null) {
      throw Exception('Active shopping list with ID $activeListId not found.');
    }

    // Check if item already exists in the list
    final existingItemIndex = activeList.items.indexWhere(
      (item) => item.name.toLowerCase() == itemName.toLowerCase(),
    );

    if (existingItemIndex != -1) {
      // Update existing item
      final existingItem = activeList.items[existingItemIndex];
      final updatedItem = existingItem.copyWith(
        quantity: existingItem.quantity + quantity,
      );
      await updateShoppingListItem(activeListId, updatedItem);
    } else {
      // Add new item
      final newItem = ShoppingListItemModel(
        id: _uuid.v4(),
        name: itemName,
        quantity: quantity,
        category: category,
        netWeight: netWeight,
        unitPrice: unitPrice ?? 0.0,
        isPurchased: false,
      );
      await addShoppingListItem(activeListId, newItem);
    }
  }

  // Update an item in a shopping list (now uses array within the document)
  Future<void> updateShoppingListItem(String listId, ShoppingListItemModel updatedItem) async {
    if (updatedItem.id == null) {
      throw ArgumentError('Updated item must have an ID.');
    }

    if (_auth.currentUser?.isAnonymous ?? false) {
      List<ShoppingListModel> guestLists = await loadGuestShoppingLists();
      int listIndex = guestLists.indexWhere((list) => list.id == listId);
      if (listIndex != -1) {
        ShoppingListModel targetList = guestLists[listIndex];
        int itemIndex = targetList.items.indexWhere((item) => item.id == updatedItem.id);
        if (itemIndex != -1) {
          targetList.items[itemIndex] = updatedItem;
          await saveGuestShoppingLists(guestLists);
        }
      }
    } else {
      DocumentReference listRef = _shoppingLists.doc(listId);
      DocumentSnapshot listDoc = await listRef.get();
      if (listDoc.exists) {
        ShoppingListModel shoppingList = ShoppingListModel.fromFirestore(listDoc);
        int itemIndex = shoppingList.items.indexWhere((item) => item.id == updatedItem.id);
        if (itemIndex != -1) {
          shoppingList.items[itemIndex] = updatedItem;
          await listRef.update({'items': shoppingList.items.map((e) => e.toMap()).toList()});
        }
      }
    }
  }

  // Remove an item from a shopping list (now uses array within the document)
  Future<void> removeShoppingListItem(String listId, ShoppingListItemModel itemToRemove) async {
    if (_auth.currentUser?.isAnonymous ?? false) {
      List<ShoppingListModel> guestLists = await loadGuestShoppingLists();
      int listIndex = guestLists.indexWhere((list) => list.id == listId);
      if (listIndex != -1) {
        ShoppingListModel targetList = guestLists[listIndex];
        targetList.items.removeWhere((item) => item.id == itemToRemove.id);
        await saveGuestShoppingLists(guestLists);
      }
    } else {
      DocumentReference listRef = _shoppingLists.doc(listId);
      await listRef.update({
        'items': FieldValue.arrayRemove([itemToRemove.toMap()])
      });
    }
  }

  // Delete a shopping list
  Future<void> deleteShoppingList(String listId) async {
    if (_auth.currentUser?.isAnonymous ?? false) {
      // For guest users, delete from local storage
      List<ShoppingListModel> guestLists = await loadGuestShoppingLists();
      guestLists.removeWhere((list) => list.id == listId);
      await saveGuestShoppingLists(guestLists);
    } else {
      await _shoppingLists.doc(listId).delete();
    }
  }

  // Activate a shopping list (optimized using Household's activeShoppingListId)
  Future<void> setActiveShoppingList(String householdId, String listId) async {
    debugPrint('DEBUG: ShoppingListService.setActiveShoppingList called for householdId: $householdId, listId: $listId');
    WriteBatch batch = _firestore.batch();
    DocumentReference householdRef = _firestore.collection('households').doc(householdId);

    // Get the current household document to find the previously active list
    DocumentSnapshot householdDoc = await householdRef.get();
    String? previouslyActiveListId = (householdDoc.data() as Map<String, dynamic>?)?['activeShoppingListId'];
    debugPrint('DEBUG: Previously active list ID for household $householdId: $previouslyActiveListId');

    // If there was a previously active list, set it to inactive
    if (previouslyActiveListId != null && previouslyActiveListId.isNotEmpty && previouslyActiveListId != listId) {
      DocumentReference prevListRef = _shoppingLists.doc(previouslyActiveListId);
      batch.update(prevListRef, {'isActive': false});
      debugPrint('DEBUG: Added batch update to deactivate previous list: $previouslyActiveListId');
    }

    // Set the new list to active
    DocumentReference newListRef = _shoppingLists.doc(listId);
    batch.update(newListRef, {'isActive': true});
    debugPrint('DEBUG: Added batch update to activate new list: $listId');

    // Update the household's activeShoppingListId
    batch.update(householdRef, {'activeShoppingListId': listId});
    debugPrint('DEBUG: Added batch update to set household $householdId activeShoppingListId to: $listId');

    try {
      await batch.commit();
      debugPrint('DEBUG: Batch commit for setActiveShoppingList successful.');
    } catch (e) {
      debugPrint('ERROR: Batch commit for setActiveShoppingList failed: $e');
      rethrow; // Re-throw to propagate the error
    }
  }

  // Stream all shopping lists for a given household
  Stream<List<ShoppingListModel>> streamShoppingLists(String householdId) {
    return _shoppingLists
        .where('householdId', isEqualTo: householdId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ShoppingListModel.fromFirestore(doc))
            .toList());
  }

  // Helper method to get waste ratios for products based on shopping history
  Future<Map<String, double>> _getWasteRatios(String householdId, {int historyDays = 90}) async {
    final DateTime historyCutoff = DateTime.now().subtract(Duration(days: historyDays));

    QuerySnapshot historySnapshot = await _shoppingHistory
        .where('householdId', isEqualTo: householdId)
        .where('timestamp', isGreaterThanOrEqualTo: historyCutoff)
        .get();

    Map<String, int> productPurchaseCounts = {};
    Map<String, int> productWasteCounts = {};

    for (var doc in historySnapshot.docs) {
      final item = ShoppingHistoryItemModel.fromFirestore(doc);
      final productName = item.productName;

      if (item.actionType == 'Consumed' || item.actionType == 'Purchased') {
        productPurchaseCounts[productName] = (productPurchaseCounts[productName] ?? 0) + item.quantity;
      } else if (item.actionType == 'Wasted' || item.actionType == 'Expired Waste') {
        productWasteCounts[productName] = (productWasteCounts[productName] ?? 0) + item.quantity;
      }
    }

    Map<String, double> wasteRatios = {};
    productPurchaseCounts.forEach((productName, purchaseCount) {
      final wasteCount = productWasteCounts[productName] ?? 0;
      if (purchaseCount > 0) {
        wasteRatios[productName] = wasteCount / purchaseCount;
      } else {
        wasteRatios[productName] = 0.0; // No purchases, so no waste ratio
      }
    });
    return wasteRatios;
  }

  // Helper method to get history-based product pool
  Future<List<ShoppingListItemModel>> _getHistoryBasedProductPool(
      String householdId, {
        bool excludeWasted = true,
        int historyDays = 90,
      }) async {
    debugPrint('[_getHistoryBasedProductPool] Starting history-based product pool generation for household: $householdId');
    final DateTime ninetyDaysAgo = DateTime.now().subtract(Duration(days: historyDays));

    // Fetch shopping history items
    QuerySnapshot historySnapshot = await _shoppingHistory
        .where('householdId', isEqualTo: householdId)
        .where('timestamp', isGreaterThanOrEqualTo: ninetyDaysAgo)
        .get();

    Map<String, int> productPurchaseCounts = {};
    Map<String, int> productWasteCounts = {};
    Map<String, double> productPrices = {};
    Map<String, String?> productCategories = {};
    Map<String, String?> productNetWeights = {};
    Map<String, String?> productNutriScores = {};
    Map<String, String?> productEcoscores = {};

    for (var doc in historySnapshot.docs) {
      final item = ShoppingHistoryItemModel.fromFirestore(doc);
      final productName = item.productName;

      // Aggregate purchase/consumption counts
      if (item.actionType == 'Consumed' || item.actionType == 'Purchased') {
        productPurchaseCounts[productName] = (productPurchaseCounts[productName] ?? 0) + item.quantity;
        debugPrint('[_getHistoryBasedProductPool] Product: $productName, Action: ${item.actionType}, Quantity: ${item.quantity}');
      } else if (excludeWasted && (item.actionType == 'Wasted' || item.actionType == 'Expired Waste')) {
        productWasteCounts[productName] = (productWasteCounts[productName] ?? 0) + item.quantity;
        debugPrint('[_getHistoryBasedProductPool] Product: $productName, Action: ${item.actionType}, Quantity: ${item.quantity} (Wasted)');
      }

      // Store price, category, netWeight, nutriScore, ecoscore
      if (item.priceAtAction != null && item.priceAtAction! > 0) {
        productPrices[productName] = item.priceAtAction!;
      } else {
        // Mark for later batch fetching if price is not available from history
        productPrices[productName] = 0.0; // Initialize to 0.0
      }
      productCategories[productName] = item.category;
      productNetWeights[productName] = item.netWeight;
      productNutriScores[productName] = item.nutrition;
      productEcoscores[productName] = item.ecoscore;
    }

    // Collect product names that still need price lookup from local_products_ph
    final List<String> productNamesWithoutPrice = productPrices.entries
        .where((entry) => entry.value == 0.0)
        .map((entry) => entry.key)
        .toList();

    if (productNamesWithoutPrice.isNotEmpty) {
      // Split productNamesWithoutPrice into chunks of 30 or fewer for whereIn queries
      const int chunkSize = 30;
      for (int i = 0; i < productNamesWithoutPrice.length; i += chunkSize) {
        final List<String> chunk = productNamesWithoutPrice.sublist(
          i,
          (i + chunkSize > productNamesWithoutPrice.length)
              ? productNamesWithoutPrice.length
              : i + chunkSize,
        );
        final QuerySnapshot productsSnapshot = await _localProducts
            .where('productName', whereIn: chunk)
            .get();

        for (var doc in productsSnapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final productName = data['productName'] as String;
          final price = (data['price'] as num?)?.toDouble() ?? 0.0;
          if (price > 0) {
            productPrices[productName] = price;
            debugPrint('[_getHistoryBasedProductPool] Batched fetched price for $productName from local_products_ph: $price');
          }
        }
      }
    }

    List<ShoppingListItemModel> historyBasedPool = [];
    productPurchaseCounts.forEach((productName, purchaseCount) {
      final wasteCount = productWasteCounts[productName] ?? 0;
      if (purchaseCount > wasteCount) {
        final effectiveQuantity = purchaseCount - wasteCount;
        final price = productPrices[productName] ?? 0.0;
        if (price > 0) {
          historyBasedPool.add(
            ShoppingListItemModel(
              id: _uuid.v4(),
              name: productName,
              quantity: 1, // Fixed quantity to 1 as per user request
              unitPrice: price,
              category: productCategories[productName] ?? 'Other', // Default to 'Other' if null
              netWeight: productNetWeights[productName],
              nutrition: productNutriScores[productName],
              ecoscore: productEcoscores[productName],
              expirationDate: getExpirationDateForCategory(
                productCategories[productName] ?? 'Other',
                productName,
                DateTime.now(), // Assume manufactured date is now for generated items
              ),
            ),
          );
          debugPrint('[_getHistoryBasedProductPool] Added $productName to pool (Fixed Qty: 1, Price: $price)');
        } else {
          debugPrint('[_getHistoryBasedProductPool] Skipped $productName due to zero or null price after all lookups.');
        }
      } else {
        debugPrint('[_getHistoryBasedProductPool] Skipped $productName due to waste count being greater than or equal to purchase count.');
      }
    });

    // Sort by purchase count (descending) to prioritize frequently bought items
    historyBasedPool.sort((a, b) => (productPurchaseCounts[b.name] ?? 0).compareTo(productPurchaseCounts[a.name] ?? 0));
    debugPrint('[_getHistoryBasedProductPool] History-based pool size: ${historyBasedPool.length}');
    return historyBasedPool;
  }

  // Generate Hassle-Free Suggestions with Pagination and Limit
  Future<List<ShoppingListItemModel>> generateHassleFreeSuggestions(
      String householdId, {
        DocumentSnapshot? lastPantryDocument, // For pagination of pantry items
        DocumentSnapshot? lastHistoryDocument, // For pagination of shopping history
        int limit = 50, // Default limit for pagination
        int maxSuggestions = 15, // New parameter to limit total suggestions
        double wasteThreshold = 0.5, // New parameter for waste ratio threshold
      }) async {
    List<ShoppingListItemModel> suggestions = [];

    // Get pantry items
    Query pantryQuery = _firestore.collection('pantryItems').where('householdId', isEqualTo: householdId);
    if (lastPantryDocument != null) {
      pantryQuery = pantryQuery.startAfterDocument(lastPantryDocument);
    }
    var pantrySnapshot = await pantryQuery.limit(limit).get();
    List<PantryItemModel> pantryItems = pantrySnapshot.docs.map((doc) => PantryItemModel.fromFirestore(doc)).toList();

    // Get waste ratios for filtering history-based suggestions
    final Map<String, double> wasteRatios = await _getWasteRatios(householdId);

    // Logic for suggestions
    // 1. Out of Stock, Expired, Low Stock from pantry
    for (var item in pantryItems) {
      String? status;
      if (item.qty == 1) { // Refined threshold for "low stock"
        status = 'Low on stock';
      } else if (item.qty <= 0 || item.status == 'Consumed' || (item.expirationDate != null && item.expirationDate!.isBefore(DateTime.now()))) {
        status = 'Out of stock';
      }

      if (status != null) {
        final scores = await _openFoodFactsService.getNutriAndEcoScore(item.name);
        suggestions.add(ShoppingListItemModel(
          id: _firestore.collection('temp').doc().id,
          name: item.name,
          netWeight: item.netWeight,
          category: item.category,
          unitPrice: 0,
          quantity: 1,
          nutrition: scores?['nutriScore'],
          ecoscore: scores?['ecoscore'],
          expirationDate: getExpirationDateForCategory(
            item.category ?? 'Other',
            item.name,
            DateTime.now(), // Assume manufactured date is now for generated items
          ),
          suggestionStatus: status, // Set the status here
        ));
      }
    }

    // 2. History-Based (filtered by waste ratio)
    Query historyQuery = _shoppingHistory.where('householdId', isEqualTo: householdId);
    if (lastHistoryDocument != null) {
      historyQuery = historyQuery.startAfterDocument(lastHistoryDocument);
    }
    var historySnapshot = await historyQuery.limit(limit).get();
    List<ShoppingHistoryItemModel> historyItems = historySnapshot.docs.map((doc) => ShoppingHistoryItemModel.fromFirestore(doc)).toList();

    for (var item in historyItems) {
      bool inPantry = pantryItems.any((pantryItem) => pantryItem.name == item.productName);
      final double productWasteRatio = wasteRatios[item.productName] ?? 0.0;

      if (!inPantry && productWasteRatio < wasteThreshold) { // Filter out frequently wasted items
        final scores = await _openFoodFactsService.getNutriAndEcoScore(item.productName);
        suggestions.add(ShoppingListItemModel(
          id: _firestore.collection('temp').doc().id,
          name: item.productName,
          category: item.category,
          unitPrice: 0,
          quantity: 1,
          nutrition: scores?['nutriScore'],
          ecoscore: scores?['ecoscore'],
          expirationDate: getExpirationDateForCategory(
            item.category ?? 'Other',
            item.productName,
            DateTime.now(), // Assume manufactured date is now for generated items
          ),
          suggestionStatus: 'History-based', // Differentiate history items
        ));
      }
    }

    // Deduplicate suggestions
    final uniqueSuggestions = <String, ShoppingListItemModel>{};
    for (var item in suggestions) {
      uniqueSuggestions[item.name] = item;
    }
    List<ShoppingListItemModel> finalSuggestions = uniqueSuggestions.values.toList();

    // Prioritize and Sort Suggestions
    finalSuggestions.sort((a, b) {
      // Out of stock comes first
      if (a.suggestionStatus == 'Out of stock' && b.suggestionStatus != 'Out of stock') {
        return -1;
      }
      if (a.suggestionStatus != 'Out of stock' && b.suggestionStatus == 'Out of stock') {
        return 1;
      }
      // Low on stock comes second
      if (a.suggestionStatus == 'Low on stock' && b.suggestionStatus != 'Low on stock') {
        return -1;
      }
      if (a.suggestionStatus != 'Low on stock' && b.suggestionStatus == 'Low on stock') {
        return 1;
      }
      // For items with the same status or other statuses, sort alphabetically
      return a.name.compareTo(b.name);
    });

    // Limit the total number of suggestions
    if (finalSuggestions.length > maxSuggestions) {
      finalSuggestions = finalSuggestions.sublist(0, maxSuggestions);
    }

    return finalSuggestions;
  }

  // Generate Budget Friendly List with Randomization and Category Balancing
  Future<List<ShoppingListItemModel>> generateBudgetFriendlyList(
      String householdId,
      double budgetAmount, {
        int? numberOfItems,
        int fetchLimit = 100, // Fetch a larger pool of items
        bool useHistory = true, // New parameter
      }) async {
    debugPrint('[generateBudgetFriendlyList] Starting budget-friendly list generation for household: $householdId, budget: $budgetAmount');
    List<ShoppingListItemModel> budgetList = [];
    double currentCost = 0;
    int itemsAdded = 0;

    List<ShoppingListItemModel> historyProductPool = [];
    List<ShoppingListItemModel> localProductPool = [];
    final List<PantryItemModel> pantryItems = await _firestoreService.getPantryForHousehold(householdId);
    final Map<String, int> pantryStock = {
      for (var item in pantryItems) item.name.toLowerCase(): item.qty
    };

    // 1. Get history-based products if useHistory is true
    if (useHistory) {
      historyProductPool = await _getHistoryBasedProductPool(householdId);
      debugPrint('[generateBudgetFriendlyList] Using history-based pool. Size: ${historyProductPool.length}');
    }

    // 2. Get local products
    QuerySnapshot productsSnapshot = await _localProducts.limit(fetchLimit).get();
    localProductPool = productsSnapshot.docs.map((doc) {
      var data = doc.data() as Map<String, dynamic>;
      return ShoppingListItemModel(
        id: _uuid.v4(), // Assign unique ID
        productId: doc.id,
        name: data['productName'],
        brand: data['brand'],
        netWeight: data['netWeight'],
        category: data['category'],
        unitPrice: (data['price'] as num?)?.toDouble() ?? 0.0,
        quantity: 1, // Fixed quantity to 1 as per user request
        nutrition: data['nutriScore'],
        expirationDate: getExpirationDateForCategory(
          data['category'] ?? 'Other',
          data['productName'],
          DateTime.now(), // Assume manufactured date is now for generated items
        ),
      );
    }).where((item) => item.unitPrice > 0).toList();
    debugPrint('[generateBudgetFriendlyList] Local product pool size: ${localProductPool.length}');

    // Combine and filter product pools
    List<ShoppingListItemModel> combinedProductPool = [];
    Set<String> addedProductNames = {}; // To prevent duplicates

    // Add history products first
    for (var item in historyProductPool) {
      final inPantryQty = pantryStock[item.name.toLowerCase()] ?? 0;
      if (inPantryQty == 0 && !addedProductNames.contains(item.name)) {
        combinedProductPool.add(item);
        addedProductNames.add(item.name);
      }
    }
    debugPrint('[generateBudgetFriendlyList] Combined pool after history: ${combinedProductPool.length}');

    // Add local products, avoiding duplicates and pantry items
    for (var item in localProductPool) {
      final inPantryQty = pantryStock[item.name.toLowerCase()] ?? 0;
      if (inPantryQty == 0 && !addedProductNames.contains(item.name)) {
        combinedProductPool.add(item);
        addedProductNames.add(item.name);
      }
    }
    debugPrint('[generateBudgetFriendlyList] Combined pool after local products: ${combinedProductPool.length}');

    // Group products by category
    Map<String, List<ShoppingListItemModel>> productsByCategory = {};
    for (var product in combinedProductPool) {
      if (product.category != null) {
        if (!productsByCategory.containsKey(product.category)) {
          productsByCategory[product.category!] = [];
        }
        productsByCategory[product.category]!.add(product);
      }
    }

    // Shuffle each category list and the list of categories
    productsByCategory.values.forEach((list) => list.shuffle());
    List<String> categories = productsByCategory.keys.toList()..shuffle();

    // Iterate through categories to ensure diversity and fill up to numberOfItems
    while ((numberOfItems == null || itemsAdded < numberOfItems) && categories.isNotEmpty) {
      for (int i = 0; i < categories.length; i++) {
        String category = categories[i];
        List<ShoppingListItemModel> categoryProducts = productsByCategory[category]!;

        if (categoryProducts.isNotEmpty) {
          ShoppingListItemModel item = categoryProducts.removeAt(0);
          final int itemQuantity = 1;
          final double itemTotalPrice = item.unitPrice * itemQuantity;

          if ((currentCost + itemTotalPrice) <= budgetAmount) {
            budgetList.add(item.copyWith(quantity: itemQuantity));
            currentCost += itemTotalPrice;
            itemsAdded++;
            debugPrint('[generateBudgetFriendlyList] Added ${item.name} (Fixed Qty: $itemQuantity). Current cost: $currentCost, Items added: $itemsAdded');
            if (numberOfItems != null && itemsAdded >= numberOfItems) {
              break;
            }
          } else {
            debugPrint('[generateBudgetFriendlyList] Skipped ${item.name}. Price: ${item.unitPrice}, Current cost: $currentCost, Budget: $budgetAmount');
          }
        }

        // If a category is exhausted, remove it
        if (categoryProducts.isEmpty) {
          categories.removeAt(i);
          i--; // Adjust index after removal
        }
      }
      // If we've iterated through all categories and still need more items,
      // but no more items can be added within budget, break the loop.
      if (itemsAdded < (numberOfItems ?? 0) && categories.isEmpty) {
        debugPrint('[generateBudgetFriendlyList] No more items can be added within budget or categories exhausted.');
        break;
      }
    }
    debugPrint('[generateBudgetFriendlyList] Final budget list size: ${budgetList.length}, Total cost: $currentCost');
    return budgetList;
  }


  // Generate Healthy Option List with Randomization and Category Balancing
  Future<List<ShoppingListItemModel>> generateHealthyOptionList(
      String householdId, {
        int numberOfItems = 15, // Default to 15 items, can be overridden
        int fetchLimit = 200, // Fetch a larger pool of items to ensure enough healthy options
        List<String>? categories, // New optional parameter
        bool useHistory = true, // New parameter
        UserPrefs? userPrefs, // New parameter for user preferences
      }) async {
    debugPrint('[generateHealthyOptionList] Starting healthy list generation for household: $householdId');
    List<ShoppingListItemModel> healthyList = [];
    final List<String> defaultHealthyCategories = ['Dairy', 'Bakery', 'Dry Goods', 'Beverages', 'Canned Goods', 'Condiments', 'Snacks', 'Other']; // Default categories

    // Use provided categories or default ones
    final List<String> categoriesToUse = categories ?? defaultHealthyCategories;

    List<ShoppingListItemModel> productPool = [];
    final List<PantryItemModel> pantryItems = await _firestoreService.getPantryForHousehold(householdId);
    final Map<String, int> pantryStock = {
      for (var item in pantryItems) item.name.toLowerCase(): item.qty
    };

    if (useHistory) {
      List<ShoppingListItemModel> historyProducts = await _getHistoryBasedProductPool(householdId);
      historyProducts = historyProducts.where((item) {
        final inPantryQty = pantryStock[item.name.toLowerCase()] ?? 0;
        bool isHealthyCategory = categoriesToUse.contains(item.category);
        return inPantryQty == 0 && isHealthyCategory;
      }).toList();
      productPool.addAll(historyProducts);
      debugPrint('[generateHealthyOptionList] Using history-based pool (filtered). Size: ${productPool.length}');
    }

    // If not enough items from history, or not using history, fill up from local products
    if (productPool.length < numberOfItems || !useHistory) {
      debugPrint('[generateHealthyOptionList] Attempting to fill up from local products to reach $numberOfItems items.');
      
      // Fetch local products that match the healthy categories and are not in pantry
      QuerySnapshot productsSnapshot = await _localProducts
          .where('category', whereIn: categoriesToUse)
          .limit(fetchLimit)
          .get();
      
      List<ShoppingListItemModel> potentialLocalProducts = productsSnapshot.docs.map((doc) {
        var data = doc.data() as Map<String, dynamic>;
        return ShoppingListItemModel(
          id: _uuid.v4(), // Assign unique ID
          productId: doc.id,
          name: data['productName'],
          brand: data['brand'],
          netWeight: data['netWeight'],
          category: data['category'],
          unitPrice: (data['price'] as num?)?.toDouble() ?? 0.0,
          quantity: 1, // Fixed quantity to 1 as per user request
          nutrition: data['nutriScore'],
          ecoscore: data['ecoscore'],
          expirationDate: getExpirationDateForCategory(
            data['category'] ?? 'Other',
            data['productName'],
            DateTime.now(), // Assume manufactured date is now for generated items
          ),
        );
      }).where((item) => item.unitPrice > 0 && !(item.name.toLowerCase().contains('cup noodles'))).toList();

      // Shuffle potential local products to enhance randomization
      potentialLocalProducts.shuffle();
      debugPrint('[generateHealthyOptionList] Shuffled potential local products. Count: ${potentialLocalProducts.length}');

      // Filter potential local products against pantry and existing pool
      for (var item in potentialLocalProducts) {
        final inPantryQty = pantryStock[item.name.toLowerCase()] ?? 0;
        if (inPantryQty == 0 && !productPool.any((poolItem) => poolItem.name == item.name)) {
          productPool.add(item);
          if (productPool.length >= numberOfItems) {
            break; // Stop adding if we have enough items
          }
        }
      }
      debugPrint('[generateHealthyOptionList] Product pool after local product fill-up: ${productPool.length}');
    }

    // Apply UserPrefs filters (diets, allergens, dislikes)
    debugPrint('[generateHealthyOptionList] Product pool before userPrefs filtering: ${productPool.length}');
    productPool = productPool.where((item) {


      // Apply allergen filters
      if (userPrefs != null && userPrefs.allergens.isNotEmpty) {
        bool isAllergenFree = userPrefs.allergens.every((allergen) {
          final itemNameLower = item.name.toLowerCase();
          final itemCategoryLower = item.category?.toLowerCase() ?? '';
          final allergenLower = allergen.toLowerCase();

          if (allergenLower == 'dairy' && (itemNameLower.contains('milk') || itemNameLower.contains('cheese') || itemNameLower.contains('yogurt') || itemCategoryLower.contains('dairy'))) return false;
          if (allergenLower == 'egg' && (itemNameLower.contains('egg') || itemCategoryLower.contains('bakery') || itemCategoryLower.contains('pasta'))) return false;
          if (allergenLower == 'fish' && (itemNameLower.contains('fish') || itemCategoryLower.contains('seafood'))) return false;
          if (allergenLower == 'shellfish' && (itemNameLower.contains('shrimp') || itemNameLower.contains('crab') || itemNameLower.contains('lobster') || itemCategoryLower.contains('seafood'))) return false;
          if (allergenLower == 'peanut' && (itemNameLower.contains('peanut') || itemCategoryLower.contains('nuts'))) return false;
          if (allergenLower == 'tree nuts' && (itemNameLower.contains('almond') || itemNameLower.contains('walnut') || itemNameLower.contains('cashew') || itemCategoryLower.contains('nuts'))) return false;
          if (allergenLower == 'soy' && (itemNameLower.contains('soy') || itemNameLower.contains('tofu') || itemCategoryLower.contains('soy'))) return false;
          if (allergenLower == 'gluten' && (itemNameLower.contains('wheat') || itemNameLower.contains('barley') || itemNameLower.contains('rye') || itemCategoryLower.contains('bakery') || itemCategoryLower.contains('pasta'))) return false;
          if (allergenLower == 'sesame' && (itemNameLower.contains('sesame'))) return false;

          return true;
        });
        if (!isAllergenFree) {
          debugPrint('[generateHealthyOptionList] Filtered out ${item.name} due to allergen: ${userPrefs.allergens}');
          return false;
        }
      }
      debugPrint('[generateHealthyOptionList] Product pool after allergen filtering: ${productPool.length}');


      // Apply dislikes filters
      if (userPrefs != null && userPrefs.dislikes.isNotEmpty) {
        bool isDislikeFree = userPrefs.dislikes.every((dislike) {
          return !item.name.toLowerCase().contains(dislike.toLowerCase());
        });
        if (!isDislikeFree) {
          debugPrint('[generateHealthyOptionList] Filtered out ${item.name} due to dislike: ${userPrefs.dislikes}');
          return false;
        }
      }
      debugPrint('[generateHealthyOptionList] Product pool after dislike filtering: ${productPool.length}');


      return true; // Item passed all filters
    }).toList();
    debugPrint('[generateHealthyOptionList] Product pool after ALL filtering: ${productPool.length}');

    // Group products by category
    Map<String, List<ShoppingListItemModel>> productsByCategory = {};
    for (var product in productPool) {
      if (product.category != null) {
        if (!productsByCategory.containsKey(product.category)) {
          productsByCategory[product.category!] = [];
        }
        productsByCategory[product.category]!.add(product);
      }
    }

    // Shuffle each category list and the list of categories for randomization and diversity
    productsByCategory.values.forEach((list) => list.shuffle());
    List<String> shuffledCategories = productsByCategory.keys.toList()..shuffle(); // Renamed local variable

    int itemsAdded = 0;
    Set<String> addedItemNames = {}; // To track items already added

    // Existing category-balanced loop
    while (itemsAdded < numberOfItems && shuffledCategories.isNotEmpty) {
      for (int i = 0; i < shuffledCategories.length; i++) {
        String category = shuffledCategories[i];
        List<ShoppingListItemModel> categoryProducts = productsByCategory[category]!;

        if (categoryProducts.isNotEmpty) {
          ShoppingListItemModel item = categoryProducts.removeAt(0);
          if (!addedItemNames.contains(item.name)) { // Check for duplicates
            healthyList.add(item.copyWith(quantity: 1));
            addedItemNames.add(item.name);
            itemsAdded++;
            debugPrint('[generateHealthyOptionList] Added ${item.name} (Fixed Qty: 1) from category-balanced. Items added: $itemsAdded');
            if (itemsAdded >= numberOfItems) {
              break;
            }
          }
        }

        if (categoryProducts.isEmpty) {
          shuffledCategories.removeAt(i);
          i--;
        }
      }
    }

    // If still not enough items, fill from the remaining productPool
    if (itemsAdded < numberOfItems) {
      debugPrint('[generateHealthyOptionList] Category-balanced fill-up did not reach $numberOfItems. Attempting to fill from remaining productPool.');
      for (var item in productPool) {
        if (itemsAdded >= numberOfItems) {
          break;
        }
        if (!addedItemNames.contains(item.name)) {
          healthyList.add(item.copyWith(quantity: 1));
          addedItemNames.add(item.name);
          itemsAdded++;
          debugPrint('[generateHealthyOptionList] Added ${item.name} (Fixed Qty: 1) from remaining productPool. Items added: $itemsAdded');
        }
      }
    }

    // Ensure the final list is limited to numberOfItems and shuffle again for final randomization
    if (healthyList.length > numberOfItems) {
      healthyList = healthyList.sublist(0, numberOfItems);
    }
    healthyList.shuffle();
    debugPrint('[generateHealthyOptionList] Final healthy list size: ${healthyList.length}');
    return healthyList;
  }
}
