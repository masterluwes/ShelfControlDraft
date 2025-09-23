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
  CollectionReference get _pantryInventory => _firestore.collection('pantryInventory');
  CollectionReference get _shoppingHistory => _firestore.collection('shoppingHistory');
  CollectionReference get _localProducts => _firestore.collection('local_products_ph');

  // Activate a shopping list
  // Get a single shopping list by ID
  Future<ShoppingListModel?> getShoppingListById(String listId) async {
    DocumentSnapshot doc = await _shoppingLists.doc(listId).get();
    if (doc.exists) {
      return ShoppingListModel.fromFirestore(doc);
    }
    return null;
  }

  // Add an item to a shopping list
  Future<void> addShoppingListItem(String listId, ShoppingListItemModel item) async {
    DocumentReference listRef = _shoppingLists.doc(listId);
    // Generate a unique ID for the new item
    String itemId = _firestore.collection('temp').doc().id;
    item.id = itemId;
    await listRef.update({
      'items': FieldValue.arrayUnion([item.toMap()])
    });
  }

  // Update an item in a shopping list
  Future<void> updateShoppingListItem(String listId, ShoppingListItemModel updatedItem) async {
    DocumentReference listRef = _shoppingLists.doc(listId);
    DocumentSnapshot listSnapshot = await listRef.get();

    if (listSnapshot.exists) {
      ShoppingListModel list = ShoppingListModel.fromFirestore(listSnapshot);
      List<ShoppingListItemModel> updatedItems = list.items.map((item) {
        return item.id == updatedItem.id ? updatedItem : item;
      }).toList();

      await listRef.update({
        'items': updatedItems.map((item) => item.toMap()).toList(),
      });
    }
  }

  // Remove an item from a shopping list
  Future<void> removeShoppingListItem(String listId, String itemId) async {
    DocumentReference listRef = _shoppingLists.doc(listId);
    DocumentSnapshot listSnapshot = await listRef.get();

    if (listSnapshot.exists) {
      ShoppingListModel list = ShoppingListModel.fromFirestore(listSnapshot);
      List<ShoppingListItemModel> updatedItems = list.items.where((item) => item.id != itemId).toList();

      await listRef.update({
        'items': updatedItems.map((item) => item.toMap()).toList(),
      });
    }
  }

  // Delete a shopping list
  Future<void> deleteShoppingList(String listId) async {
    await _shoppingLists.doc(listId).delete();
  }

  // Activate a shopping list
  Future<void> setActiveShoppingList(String householdId, String listId) async {
    WriteBatch batch = _firestore.batch();

    // Set all other lists for the household to inactive
    QuerySnapshot querySnapshot = await _shoppingLists.where('householdId', isEqualTo: householdId).get();
    for (var doc in querySnapshot.docs) {
      if (doc.id != listId) {
        batch.update(doc.reference, {'isActive': false});
      }
    }

    // Set the selected list to active
    DocumentReference docRef = _shoppingLists.doc(listId);
    batch.update(docRef, {'isActive': true});

    await batch.commit();
  }

  // Generate Hassle-Free Suggestions
  Future<List<ShoppingListItemModel>> generateHassleFreeSuggestions(String householdId) async {
    List<ShoppingListItemModel> suggestions = [];

    // Get pantry items
    var pantrySnapshot = await _pantryInventory.where('householdId', isEqualTo: householdId).get();
    List<PantryItemModel> pantryItems = pantrySnapshot.docs.map((doc) => PantryItemModel.fromFirestore(doc)).toList();

    // Get shopping history
    var historySnapshot = await _shoppingHistory.where('householdId', isEqualTo: householdId).get();
    List<ShoppingHistoryItemModel> historyItems = historySnapshot.docs.map((doc) => ShoppingHistoryItemModel.fromFirestore(doc)).toList();

    // Logic for suggestions
    // 1. Out of Stock, Expired, Low Stock from pantry
    for (var item in pantryItems) {
      if (item.qty <= 0 || item.status == 'Consumed' || (item.expirationDate != null && item.expirationDate!.isBefore(DateTime.now()))) {
        suggestions.add(ShoppingListItemModel(
          name: item.name,
          brand: item.brand,
          netWeight: item.netWeight,
          category: item.category,
          unitPrice: 0, // Will need to fetch price
          quantity: 1,
        ));
      }
    }

    // 2. History-Based
    for (var item in historyItems) {
      bool inPantry = pantryItems.any((pantryItem) => pantryItem.name == item.productName);
      if (!inPantry) {
        suggestions.add(ShoppingListItemModel(
          name: item.productName,
          category: item.category,
          unitPrice: 0, // Will need to fetch price
          quantity: 1,
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

  // Generate Budget Friendly List
  Future<List<ShoppingListItemModel>> generateBudgetFriendlyList(String householdId, double budgetAmount, {int? numberOfItems}) async {
    var productsSnapshot = await _localProducts.get();
    List<ShoppingListItemModel> allProducts = productsSnapshot.docs.map((doc) {
      var data = doc.data() as Map<String, dynamic>;
      return ShoppingListItemModel(
        productId: doc.id,
        name: data['productName'],
        brand: data['brand'],
        netWeight: data['netWeight'],
        category: data['category'],
        unitPrice: (data['price'] as num?)?.toDouble() ?? 0.0,
        quantity: 1,
      );
    }).toList();

    allProducts.sort((a, b) => a.unitPrice.compareTo(b.unitPrice));

    List<ShoppingListItemModel> budgetList = [];
    double currentCost = 0;

    for (var product in allProducts) {
      if (currentCost + product.unitPrice <= budgetAmount) {
        budgetList.add(product);
        currentCost += product.unitPrice;
        if (numberOfItems != null && budgetList.length >= numberOfItems) {
          break;
        }
      }
    }
    return budgetList;
  }

  // Generate Most Recommended List
  Future<List<ShoppingListItemModel>> generateMostRecommendedList(String householdId, {int? numberOfItems}) async {
    var historySnapshot = await _shoppingHistory.where('householdId', isEqualTo: householdId).get();
    Map<String, int> frequencyMap = {};
    for (var doc in historySnapshot.docs) {
      var data = doc.data() as Map<String, dynamic>;
      String productName = data['productName'];
      frequencyMap[productName] = (frequencyMap[productName] ?? 0) + 1;
    }

    var sortedHistory = frequencyMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    List<ShoppingListItemModel> recommendedList = [];
    for (var entry in sortedHistory) {
      var productSnapshot = await _localProducts.where('productName', isEqualTo: entry.key).limit(1).get();
      if (productSnapshot.docs.isNotEmpty) {
        var doc = productSnapshot.docs.first;
        var data = doc.data() as Map<String, dynamic>;
        recommendedList.add(ShoppingListItemModel(
          productId: doc.id,
          name: data['productName'],
          brand: data['brand'],
          netWeight: data['netWeight'],
          category: data['category'],
          unitPrice: (data['price'] as num?)?.toDouble() ?? 0.0,
          quantity: 1,
        ));
      }
      if (numberOfItems != null && recommendedList.length >= numberOfItems) {
        break;
      }
    }
    return recommendedList;
  }

  // Generate Healthy Option List
  Future<List<ShoppingListItemModel>> generateHealthyOptionList(String householdId, {int? numberOfItems}) async {
    var productsSnapshot = await _localProducts.get();
    List<ShoppingListItemModel> healthyList = [];

    for (var doc in productsSnapshot.docs) {
      var data = doc.data() as Map<String, dynamic>;
      String productName = data['productName'];
      var nutriScore = await _openFoodFactsService.getNutriScore(productName);
      if (nutriScore != null && ['a', 'b', 'c'].contains(nutriScore)) {
        healthyList.add(ShoppingListItemModel(
          productId: doc.id,
          name: data['productName'],
          brand: data['brand'],
          netWeight: data['netWeight'],
          category: data['category'],
          unitPrice: (data['price'] as num?)?.toDouble() ?? 0.0,
          quantity: 1,
        ));
      }
      if (numberOfItems != null && healthyList.length >= numberOfItems) {
        break;
      }
    }
    return healthyList;
  }
}
