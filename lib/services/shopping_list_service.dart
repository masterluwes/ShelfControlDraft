import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shelf_control/models/pantry_item_model.dart';
import 'package:shelf_control/models/shopping_history_item_model.dart';
import 'package:shelf_control/models/shopping_list_item_model.dart';
import 'package:shelf_control/models/shopping_list_model.dart';
import 'package:shelf_control/services/open_food_facts_service.dart';

class ShoppingListService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final OpenFoodFactsService _openFoodFactsService = OpenFoodFactsService();

  // Helper to get a reference to the collections
  CollectionReference get _shoppingLists => _firestore.collection('shoppingLists');
  CollectionReference get _pantryItems => _firestore.collection('pantryItems'); // Corrected collection name
  CollectionReference get _shoppingHistory => _firestore.collection('shoppingHistory');
  CollectionReference get _localProducts => _firestore.collection('local_products_ph');

  // Activate a shopping list
  // Get a single shopping list by ID, including its items from the subcollection
  Future<ShoppingListModel?> getShoppingListById(String listId) async {
    DocumentSnapshot listDoc = await _shoppingLists.doc(listId).get();

    if (listDoc.exists) {
      // Fetch items from the subcollection
      QuerySnapshot itemsSnapshot = await _shoppingLists.doc(listId).collection('items').get();
      List<ShoppingListItemModel> items = itemsSnapshot.docs
          .map((doc) => ShoppingListItemModel.fromFirestore(doc))
          .toList();

      // Create ShoppingListModel from the main document, then add the fetched items
      ShoppingListModel shoppingList = ShoppingListModel.fromFirestore(listDoc);
      shoppingList.items = items; // Assign the fetched items

      return shoppingList;
    }
    return null;
  }

  // Add an item to a shopping list (now uses subcollection)
  Future<void> addShoppingListItem(String listId, ShoppingListItemModel item) async {
    CollectionReference itemsRef = _shoppingLists.doc(listId).collection('items');
    DocumentReference docRef = itemsRef.doc(); // Let Firestore generate the ID
    item.id = docRef.id; // Assign the generated ID to the item
    await docRef.set(item.toMap());
  }

  // Update an item in a shopping list (now uses subcollection)
  Future<void> updateShoppingListItem(String listId, ShoppingListItemModel updatedItem) async {
    if (updatedItem.id == null) {
      throw ArgumentError('Updated item must have an ID.');
    }
    DocumentReference itemRef = _shoppingLists.doc(listId).collection('items').doc(updatedItem.id);
    await itemRef.update(updatedItem.toMap());
  }

  // Remove an item from a shopping list (now uses subcollection)
  Future<void> removeShoppingListItem(String listId, String itemId) async {
    DocumentReference itemRef = _shoppingLists.doc(listId).collection('items').doc(itemId);
    await itemRef.delete();
  }

  // Delete a shopping list
  Future<void> deleteShoppingList(String listId) async {
    await _shoppingLists.doc(listId).delete();
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

  // Generate Hassle-Free Suggestions with Pagination and Limit
  Future<List<ShoppingListItemModel>> generateHassleFreeSuggestions(
      String householdId, {
        DocumentSnapshot? lastPantryDocument, // For pagination of pantry items
        DocumentSnapshot? lastHistoryDocument, // For pagination of shopping history
        int limit = 50, // Default limit for pagination
      }) async {
    List<ShoppingListItemModel> suggestions = [];

    // Get pantry items
    Query pantryQuery = _pantryItems.where('householdId', isEqualTo: householdId);
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
      if (item.qty <= 0 || item.status == 'Consumed' || (item.expirationDate != null && item.expirationDate!.isBefore(DateTime.now()))) {
        // Fetch nutriScore and save it to local_products_ph if not present
        String? nutriScore = await _openFoodFactsService.getNutriScore(item.name);
        if (nutriScore != null) {
          // Assuming there's a way to link pantry item to local_products_ph or create a new entry
          // For now, we'll just add it to the ShoppingListItemModel
          // In a real scenario, you might want to update the local_products_ph collection
        }

        suggestions.add(ShoppingListItemModel(
          id: _firestore.collection('temp').doc().id, // Assign unique ID
          name: item.name,
          brand: item.brand,
          netWeight: item.netWeight,
          category: item.category,
          unitPrice: 0, // Will need to fetch price
          quantity: 1,
          nutrition: nutriScore, // Add nutrition
        ));
      }
    }

    // 2. History-Based
    for (var item in historyItems) {
      bool inPantry = pantryItems.any((pantryItem) => pantryItem.name == item.productName);
      if (!inPantry) {
        // Fetch nutriScore and save it to local_products_ph if not present
        String? nutriScore = await _openFoodFactsService.getNutriScore(item.productName);
        if (nutriScore != null) {
          // Assuming there's a way to link history item to local_products_ph or create a new entry
          // For now, we'll just add it to the ShoppingListItemModel
          // In a real scenario, you might want to update the local_products_ph collection
        }

        suggestions.add(ShoppingListItemModel(
          id: _firestore.collection('temp').doc().id, // Assign unique ID
          name: item.productName,
          category: item.category,
          unitPrice: 0, // Will need to fetch price
          quantity: 1,
          nutrition: nutriScore, // Add nutrition
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
    final Map<String, int> categoryCounts = {}; // To track category diversity

    // Generate a random starting point for the query
    String randomStartId = _firestore.collection('temp').doc().id;

    // Fetch a diverse pool of products using a randomized query
    QuerySnapshot productsSnapshot = await _localProducts
        .orderBy(FieldPath.documentId)
        .startAfter([randomStartId])
        .limit(fetchLimit)
        .get();

    // If not enough items are fetched, try fetching from the beginning
    if (productsSnapshot.docs.length < fetchLimit / 2) {
      final secondSnapshot = await _localProducts
          .orderBy(FieldPath.documentId)
          .limit(fetchLimit - productsSnapshot.docs.length)
          .get();
      productsSnapshot.docs.addAll(secondSnapshot.docs);
    }

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

    // Shuffle the product pool for randomization
    productPool.shuffle();

    // Define a dynamic max price for a single item based on the budget
    // No single item should exceed 30% of the total budget or a fixed realistic max (e.g., ₱500), whichever is lower.
    final double maxItemPrice = (budgetAmount * 0.3).clamp(0, 500);

    // Iterate through the shuffled pool to build the budget list
    for (var item in productPool) {
      if (numberOfItems != null && itemsAdded >= numberOfItems) {
        break;
      }

      // Ensure item price is within a reasonable range and fits the remaining budget
      if (item.unitPrice <= maxItemPrice && (currentCost + item.unitPrice) <= budgetAmount) {
        // Simple category balancing: try to add items from less represented categories
        // This is a basic heuristic and can be refined.
        final String category = item.category ?? 'Other';
        if (categoryCounts.containsKey(category) && categoryCounts[category]! >= 2) {
          // Skip if we already have 2 items from this category, try to find another category
          continue;
        }

        budgetList.add(item);
        currentCost += item.unitPrice;
        itemsAdded++;
        categoryCounts[category] = (categoryCounts[category] ?? 0) + 1;
      }
    }

    // If the budget is not fully utilized and we still need more items,
    // or if we didn't reach the desired number of items,
    // we can try to add more items without strict category balancing,
    // or allow slightly higher priced items if the remaining budget is large.
    // For now, we'll keep it simple to avoid excessive reads.
    // The current approach prioritizes diversity and staying within budget.

    return budgetList;
  }


  // Generate Healthy Option List with Pagination
  Future<List<ShoppingListItemModel>> generateHealthyOptionList(
      String householdId, {
        int? numberOfItems,
        DocumentSnapshot? lastDocument, // For pagination
        int limit = 20, // Default limit for pagination
      }) async {
    Query query = _localProducts
        .where('nutriScore', whereIn: ['a', 'b', 'c', 'A', 'B', 'C']); // Case-insensitive check

    if (lastDocument != null) {
      query = query.startAfterDocument(lastDocument);
    }

    QuerySnapshot productsSnapshot = await query.limit(limit).get();

    List<ShoppingListItemModel> healthyList = [];

    for (var doc in productsSnapshot.docs) {
      var data = doc.data() as Map<String, dynamic>;
      String? nutriScore = data['nutriScore'];

      // Double-check nutriScore and add to list
      if (nutriScore != null && ['a', 'b', 'c'].contains(nutriScore.toLowerCase())) {
        healthyList.add(ShoppingListItemModel(
          id: _firestore.collection('temp').doc().id, // Assign unique ID
          productId: doc.id,
          name: data['productName'],
          brand: data['brand'],
          netWeight: data['netWeight'],
          category: data['category'],
          unitPrice: (data['price'] as num?)?.toDouble() ?? 0.0,
          quantity: 1,
          nutrition: nutriScore, // Pass the nutriScore
        ));
      }
    }

    // If we still need more items, or if the initial query didn't return enough,
    // we could fetch more and then get nutriScores, but for now, this is a good optimization.
    // Add randomness to the selection if more items than requested were fetched
    if (healthyList.length > (numberOfItems ?? 0)) {
      healthyList.shuffle();
      return healthyList.take(numberOfItems ?? healthyList.length).toList();
    }

    return healthyList;
  }
}
