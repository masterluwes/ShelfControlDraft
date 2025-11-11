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
    WriteBatch batch = _firestore.batch();
    DocumentReference householdRef = _firestore.collection('households').doc(householdId);

    // Get the current household document to find the previously active list
    DocumentSnapshot householdDoc = await householdRef.get();
    String? previouslyActiveListId = (householdDoc.data() as Map<String, dynamic>?)?['activeShoppingListId'];

    // If there was a previously active list, set it to inactive
    if (previouslyActiveListId != null && previouslyActiveListId.isNotEmpty && previouslyActiveListId != listId) {
      DocumentReference prevListRef = _shoppingLists.doc(previouslyActiveListId);
      batch.update(prevListRef, {'isActive': false});
    }

    // Set the new list to active
    DocumentReference newListRef = _shoppingLists.doc(listId);
    batch.update(newListRef, {'isActive': true});

    // Update the household's activeShoppingListId
    batch.update(householdRef, {'activeShoppingListId': listId});

    await batch.commit();
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
      } else if ((productPrices[productName] == null || productPrices[productName] == 0.0)) {
        // Fallback to fetching from local_products_ph if priceAtAction is 0 or null
        final productDetails = await _firestoreService.getProductDetailsByName(productName);
        if (productDetails != null && productDetails.price != null && productDetails.price! > 0) {
          productPrices[productName] = productDetails.price!;
          debugPrint('[_getHistoryBasedProductPool] Fetched price for $productName from local_products_ph: ${productDetails.price}');
        } else {
          productPrices[productName] = 0.0; // Default to 0 if no price found
          debugPrint('[_getHistoryBasedProductPool] No price found for $productName');
        }
      }
      productCategories[productName] = item.category;
      productNetWeights[productName] = item.netWeight;
      productNutriScores[productName] = item.nutrition;
      productEcoscores[productName] = item.ecoscore;
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
              quantity: effectiveQuantity,
              unitPrice: price,
              category: productCategories[productName],
              netWeight: productNetWeights[productName],
              nutrition: productNutriScores[productName],
              ecoscore: productEcoscores[productName],
            ),
          );
          debugPrint('[_getHistoryBasedProductPool] Added $productName to pool (Effective Qty: $effectiveQuantity, Price: $price)');
        } else {
          debugPrint('[_getHistoryBasedProductPool] Skipped $productName due to zero or null price.');
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
      }) async {
    List<ShoppingListItemModel> suggestions = [];

    // Get pantry items
    Query pantryQuery = _firestore.collection('pantryItems').where('householdId', isEqualTo: householdId);
    if (lastPantryDocument != null) {
      pantryQuery = pantryQuery.startAfterDocument(lastPantryDocument);
    }
    var pantrySnapshot = await pantryQuery.limit(limit).get();
    List<PantryItemModel> pantryItems = pantrySnapshot.docs.map((doc) => PantryItemModel.fromFirestore(doc)).toList();

    // Get shopping history
    Query historyQuery = _shoppingHistory.where('householdId', isEqualTo: householdId);
    if (lastHistoryDocument != null) {
      historyQuery = historyQuery.startAfterDocument(lastHistoryDocument);
    }
    var historySnapshot = await historyQuery.limit(limit).get();
    List<ShoppingHistoryItemModel> historyItems = historySnapshot.docs.map((doc) => ShoppingHistoryItemModel.fromFirestore(doc)).toList();

    // Logic for suggestions
    // 1. Out of Stock, Expired, Low Stock from pantry
    for (var item in pantryItems) {
      String? status;
      if (item.qty > 0 && item.qty <= 2) { // Example threshold for "low stock"
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
          suggestionStatus: status, // Set the status here
        ));
      }
    }

    // 2. History-Based
    for (var item in historyItems) {
      bool inPantry = pantryItems.any((pantryItem) => pantryItem.name == item.productName);
      if (!inPantry) {
        final scores = await _openFoodFactsService.getNutriAndEcoScore(item.productName);
        suggestions.add(ShoppingListItemModel(
          id: _firestore.collection('temp').doc().id,
          name: item.productName,
          category: item.category,
          unitPrice: 0,
          quantity: 1,
          nutrition: scores?['nutriScore'],
          ecoscore: scores?['ecoscore'],
          suggestionStatus: 'Out of stock', // History items are considered out of stock
        ));
      }
    }

    // Deduplicate suggestions
    final uniqueSuggestions = <String, ShoppingListItemModel>{};
    for (var item in suggestions) {
      uniqueSuggestions[item.name] = item;
    }

    return uniqueSuggestions.values.toList();
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

    List<ShoppingListItemModel> productPool;

    if (useHistory) {
      productPool = await _getHistoryBasedProductPool(householdId);
      debugPrint('[generateBudgetFriendlyList] Using history-based pool. Size: ${productPool.length}');
      if (productPool.isEmpty) {
        debugPrint('[generateBudgetFriendlyList] History-based pool is empty, falling back to local products.');
        // Fallback to local products if history pool is empty
        QuerySnapshot productsSnapshot = await _localProducts.limit(fetchLimit).get();
        productPool = productsSnapshot.docs.map((doc) {
          var data = doc.data() as Map<String, dynamic>;
          return ShoppingListItemModel(
            id: _uuid.v4(), // Assign unique ID
            productId: doc.id,
            name: data['productName'],
            brand: data['brand'],
            netWeight: data['netWeight'],
            category: data['category'],
            unitPrice: (data['price'] as num?)?.toDouble() ?? 0.0,
            quantity: 1,
            nutrition: data['nutriScore'],
          );
        }).where((item) => item.unitPrice > 0).toList();
      }
    } else {
      debugPrint('[generateBudgetFriendlyList] Not using history, fetching from local products.');
      QuerySnapshot productsSnapshot = await _localProducts.limit(fetchLimit).get();
      productPool = productsSnapshot.docs.map((doc) {
        var data = doc.data() as Map<String, dynamic>;
        return ShoppingListItemModel(
          id: _uuid.v4(), // Assign unique ID
          productId: doc.id,
          name: data['productName'],
          brand: data['brand'],
          netWeight: data['netWeight'],
          category: data['category'],
          unitPrice: (data['price'] as num?)?.toDouble() ?? 0.0,
          quantity: 1,
          nutrition: data['nutriScore'],
        );
      }).where((item) => item.unitPrice > 0).toList();
    }

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

    // Shuffle each category list and the list of categories
    productsByCategory.values.forEach((list) => list.shuffle());
    List<String> categories = productsByCategory.keys.toList()..shuffle();

    // Define a dynamic max price for a single item based on the budget
    final double maxItemPrice = (budgetAmount * 0.3).clamp(0, 500);
    debugPrint('[generateBudgetFriendlyList] Max item price: $maxItemPrice');

    // Iterate through categories to ensure diversity
    while ((numberOfItems == null || itemsAdded < numberOfItems) && categories.isNotEmpty) {
      for (int i = 0; i < categories.length; i++) {
        String category = categories[i];
        List<ShoppingListItemModel> categoryProducts = productsByCategory[category]!;

        if (categoryProducts.isNotEmpty) {
          ShoppingListItemModel item = categoryProducts.removeAt(0);

          if (item.unitPrice <= maxItemPrice && (currentCost + item.unitPrice) <= budgetAmount) {
            budgetList.add(item);
            currentCost += item.unitPrice;
            itemsAdded++;
            debugPrint('[generateBudgetFriendlyList] Added ${item.name}. Current cost: $currentCost, Items added: $itemsAdded');
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

    List<ShoppingListItemModel> productPool;

    if (useHistory) {
      productPool = await _getHistoryBasedProductPool(householdId);
      debugPrint('[generateHealthyOptionList] Using history-based pool. Size: ${productPool.length}');
      if (productPool.isEmpty) {
        debugPrint('[generateHealthyOptionList] History-based pool is empty, falling back to local products.');
        // Fallback to local products if history pool is empty
        QuerySnapshot productsSnapshot = await _localProducts
            .where('category', whereIn: categoriesToUse)
            .limit(fetchLimit)
            .get();
        productPool = productsSnapshot.docs.map((doc) {
          var data = doc.data() as Map<String, dynamic>;
          return ShoppingListItemModel(
            id: _uuid.v4(), // Assign unique ID
            productId: doc.id,
            name: data['productName'],
            brand: data['brand'],
            netWeight: data['netWeight'],
            category: data['category'],
            unitPrice: (data['price'] as num?)?.toDouble() ?? 0.0,
            quantity: 1,
            nutrition: data['nutriScore'],
            ecoscore: data['ecoscore'],
          );
        }).where((item) => item.unitPrice > 0 && !(item.name.toLowerCase().contains('cup noodles'))).toList();
      }
    } else {
      debugPrint('[generateHealthyOptionList] Not using history, fetching from local products.');
      QuerySnapshot productsSnapshot = await _localProducts
          .where('category', whereIn: categoriesToUse)
          .limit(fetchLimit)
          .get();
      productPool = productsSnapshot.docs.map((doc) {
        var data = doc.data() as Map<String, dynamic>;
        return ShoppingListItemModel(
          id: _uuid.v4(), // Assign unique ID
          productId: doc.id,
          name: data['productName'],
          brand: data['brand'],
          netWeight: data['netWeight'],
          category: data['category'],
          unitPrice: (data['price'] as num?)?.toDouble() ?? 0.0,
          quantity: 1,
          nutrition: data['nutriScore'],
          ecoscore: data['ecoscore'],
        );
      }).where((item) => item.unitPrice > 0 && !(item.name.toLowerCase().contains('cup noodles'))).toList();
    }

    // Apply healthy filters (nutriScore, categories) and UserPrefs filters (diets, allergens, dislikes)
    productPool = productPool.where((item) {
      final nutriScore = item.nutrition?.toLowerCase();
      bool isHealthyNutriScore = (nutriScore == 'a' || nutriScore == 'b' || nutriScore == 'c');
      bool isHealthyCategory = categoriesToUse.contains(item.category);

      // Apply dietary filters
      if (userPrefs != null && userPrefs.diets.isNotEmpty) {
        bool meetsDietaryNeeds = userPrefs.diets.every((diet) {
          // Simplified check: assuming product name or category might contain diet-related keywords
          final itemNameLower = item.name.toLowerCase();
          final itemCategoryLower = item.category?.toLowerCase() ?? '';
          final dietLower = diet.toLowerCase();

          // Example: If diet is "vegetarian", check if product is not meat-related
          if (dietLower == 'vegetarian' && (itemNameLower.contains('chicken') || itemNameLower.contains('beef') || itemNameLower.contains('pork') || itemCategoryLower.contains('meat'))) {
            return false;
          }
          // Add more specific dietary checks as needed based on product data
          return true;
        });
        if (!meetsDietaryNeeds) {
          debugPrint('[generateHealthyOptionList] Filtered out ${item.name} due to dietary preference: ${userPrefs.diets}');
          return false;
        }
      }

      // Apply allergen filters
      if (userPrefs != null && userPrefs.allergens.isNotEmpty) {
        bool isAllergenFree = userPrefs.allergens.every((allergen) {
          final itemNameLower = item.name.toLowerCase();
          final itemCategoryLower = item.category?.toLowerCase() ?? '';
          final allergenLower = allergen.toLowerCase();

          // More comprehensive basic checks for common allergens
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

      return (isHealthyNutriScore || isHealthyCategory);
    }).toList();
    debugPrint('[generateHealthyOptionList] Product pool after filtering: ${productPool.length}');

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
    while (itemsAdded < numberOfItems && shuffledCategories.isNotEmpty) {
      for (int i = 0; i < shuffledCategories.length; i++) {
        String category = shuffledCategories[i];
        List<ShoppingListItemModel> categoryProducts = productsByCategory[category]!;

        if (categoryProducts.isNotEmpty) {
          ShoppingListItemModel item = categoryProducts.removeAt(0);
          healthyList.add(item);
          itemsAdded++;
          if (itemsAdded >= numberOfItems) {
            break;
          }
        }

        // If a category is exhausted, remove it
        if (categoryProducts.isEmpty) {
          shuffledCategories.removeAt(i);
          i--; // Adjust index after removal
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
