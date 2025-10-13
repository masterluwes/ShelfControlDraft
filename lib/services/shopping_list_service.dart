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

class ShoppingListService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance; // Instantiate FirebaseAuth
  final OpenFoodFactsService _openFoodFactsService = OpenFoodFactsService();
  final Uuid _uuid = const Uuid(); // Instantiate Uuid

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
  }) async {
    List<ShoppingListItemModel> budgetList = [];
    double currentCost = 0;
    int itemsAdded = 0;
    final List<String> excludedCategories = ['frozen', 'vegetable', 'fruit', 'meat'];

    // Fetch a diverse pool of products, excluding specified categories
    Query productsQuery = _localProducts.where('category', whereNotIn: excludedCategories);

    QuerySnapshot productsSnapshot = await productsQuery.limit(fetchLimit).get();

    List<ShoppingListItemModel> productPool = productsSnapshot.docs.map((doc) {
      var data = doc.data() as Map<String, dynamic>;
      return ShoppingListItemModel(
        id: _firestore.collection('temp').doc().id, // Assign unique ID
        productId: doc.id,
        name: data['productName'],
        brand: data['brand'],
        netWeight: data['netWeight'],
        category: data['category'],
        unitPrice: (data['price'] as num?)?.toDouble() ?? 0.0,
        quantity: 1,
        nutrition: data['nutriScore'],
      );
    }).where((item) => item.unitPrice > 0).toList(); // Filter out items with no price

    // Group products by category
    Map<String, List<ShoppingListItemModel>> productsByCategory = {};
    for (var product in productPool) {
      if (!productsByCategory.containsKey(product.category)) {
        productsByCategory[product.category!] = [];
      }
      productsByCategory[product.category]!.add(product);
    }

    // Shuffle each category list and the list of categories
    productsByCategory.values.forEach((list) => list.shuffle());
    List<String> categories = productsByCategory.keys.toList()..shuffle();

    // Define a dynamic max price for a single item based on the budget
    final double maxItemPrice = (budgetAmount * 0.3).clamp(0, 500);

    // Iterate through categories to ensure diversity
    while ((numberOfItems == null || itemsAdded < numberOfItems!) && categories.isNotEmpty) {
      for (int i = 0; i < categories.length; i++) {
        String category = categories[i];
        List<ShoppingListItemModel> categoryProducts = productsByCategory[category]!;

        if (categoryProducts.isNotEmpty) {
          ShoppingListItemModel item = categoryProducts.removeAt(0);

          if (item.unitPrice <= maxItemPrice && (currentCost + item.unitPrice) <= budgetAmount) {
            budgetList.add(item);
            currentCost += item.unitPrice;
            itemsAdded++;
            if (numberOfItems != null && itemsAdded >= numberOfItems) {
              break;
            }
          }
        }

        // If a category is exhausted, remove it
        if (categoryProducts.isEmpty) {
          categories.removeAt(i);
          i--; // Adjust index after removal
        }
      }
    }

    return budgetList;
  }


  // Generate Healthy Option List with Randomization and Category Balancing
  Future<List<ShoppingListItemModel>> generateHealthyOptionList(
    String householdId, {
    int numberOfItems = 15, // Default to 15 items, can be overridden
    int fetchLimit = 200, // Fetch a larger pool of items to ensure enough healthy options
  }) async {
    List<ShoppingListItemModel> healthyList = [];
    final List<String> healthyCategories = ['Dairy', 'Bakery', 'Dry Goods']; // Prioritized healthy categories

    // Step 1: Query _localProducts_ph for items within healthy categories
    QuerySnapshot productsSnapshot = await _localProducts
        .where('category', whereIn: healthyCategories)
        .limit(fetchLimit)
        .get();

    List<ShoppingListItemModel> productPool = productsSnapshot.docs.map((doc) {
      var data = doc.data() as Map<String, dynamic>;
      return ShoppingListItemModel(
        id: _firestore.collection('temp').doc().id, // Assign unique ID
        productId: doc.id,
        name: data['productName'],
        brand: data['brand'],
        netWeight: data['netWeight'],
        category: data['category'],
        unitPrice: (data['price'] as num?)?.toDouble() ?? 0.0,
        quantity: 1,
        nutrition: data['nutriScore'], // Use actual nutriScore if available
        ecoscore: data['ecoscore'], // Use actual ecoscore if available
      );
    }).where((item) => item.unitPrice > 0 && !(item.name.toLowerCase().contains('cup noodles'))).toList(); // Filter out items with no price and "cup noodles"

    // Filter out items that are explicitly not healthy (e.g., based on nutriScore or other criteria)
    // For now, we'll consider items with a nutriScore of 'A', 'B', or 'C' as healthy, or if nutriScore is null/empty, we'll rely on category.
    productPool = productPool.where((item) {
      final nutriScore = item.nutrition?.toLowerCase();
      if (nutriScore == 'a' || nutriScore == 'b' || nutriScore == 'c') {
        return true;
      }
      // If no nutriScore, rely on category to be one of the healthy categories
      return healthyCategories.contains(item.category);
    }).toList();

    // Group products by category
    Map<String, List<ShoppingListItemModel>> productsByCategory = {};
    for (var product in productPool) {
      if (product.category != null) { // Removed healthyCategories.contains(product.category) as it's already filtered in productPool
        if (!productsByCategory.containsKey(product.category)) {
          productsByCategory[product.category!] = [];
        }
        productsByCategory[product.category]!.add(product);
      }
    }

    // Shuffle each category list and the list of categories for randomization and diversity
    productsByCategory.values.forEach((list) => list.shuffle());
    List<String> categories = productsByCategory.keys.toList()..shuffle();

    int itemsAdded = 0;
    while (itemsAdded < numberOfItems && categories.isNotEmpty) {
      for (int i = 0; i < categories.length; i++) {
        String category = categories[i];
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
          categories.removeAt(i);
          i--; // Adjust index after removal
        }
      }
    }

    // Ensure the final list is limited to numberOfItems and shuffle again for final randomization
    if (healthyList.length > numberOfItems) {
      healthyList = healthyList.sublist(0, numberOfItems);
    }
    healthyList.shuffle();

    return healthyList;
  }
}
