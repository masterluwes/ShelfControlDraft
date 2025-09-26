import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart'; // Import for ChangeNotifier
import 'package:shelf_control/models/pantry_item_model.dart';
import 'package:shelf_control/models/household_model.dart'; // Import Household model
import 'package:shelf_control/models/product_model.dart'; // Import Product model
import 'package:shelf_control/models/user_model.dart'; // Import UserModel
import 'package:shelf_control/models/shopping_list_model.dart'; // Import ShoppingListModel
// Import ShoppingListItemModel
import 'package:shelf_control/models/shopping_history_item_model.dart'; // Import ShoppingHistoryItemModel
import 'package:uuid/uuid.dart'; // For generating unique IDs
import 'package:shared_preferences/shared_preferences.dart'; // Import SharedPreferences

class FirestoreService extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Uuid _uuid = const Uuid(); // Instantiate Uuid

  FirebaseFirestore get db => _db; // Public getter for _db

  String? get userId => _auth.currentUser?.uid;

  // This will be set by the UI when a household is selected
  String? _selectedHouseholdId; // Make it private

  String? get selectedHouseholdId => _selectedHouseholdId;

  // Setter for selectedHouseholdId that also persists the value
  set selectedHouseholdId(String? value) {
    if (_selectedHouseholdId != value) {
      _selectedHouseholdId = value;
      _saveSelectedHouseholdId(value); // Save to SharedPreferences
      notifyListeners(); // Notify listeners when the selected household changes
    }
  }

  // Save selected household ID to SharedPreferences
  Future<void> _saveSelectedHouseholdId(String? householdId) async {
    final prefs = await SharedPreferences.getInstance();
    if (householdId != null) {
      await prefs.setString('selectedHouseholdId', householdId);
    } else {
      await prefs.remove('selectedHouseholdId');
    }
  }

  // Load selected household ID from SharedPreferences
  Future<String?> _loadSelectedHouseholdId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('selectedHouseholdId');
  }

  // Set the initial selected household for a user
  Future<void> setInitialHousehold(String userId) async {
    // Try to load from SharedPreferences first
    String? storedHouseholdId = await _loadSelectedHouseholdId();

    if (storedHouseholdId != null) {
      // Check if the stored household still exists and the user is a member
      final householdDoc = await _db.collection('households').doc(storedHouseholdId).get();
      if (householdDoc.exists && householdDoc.data() != null && householdDoc.data()!['members'].contains(userId)) {
        selectedHouseholdId = storedHouseholdId; // Use the setter to update and notify
        return;
      }
    }

    // If no stored household or it's invalid, default to personal household
    final userDoc = await _db.collection('users').doc(userId).get();
    if (userDoc.exists && userDoc.data() != null && userDoc.data()!['personalHouseholdId'] != null) {
      selectedHouseholdId = userDoc.data()!['personalHouseholdId']; // Use the setter to update and notify
    }
  }

  // Create a personal household for a new user
  Future<void> createPersonalHousehold(String userId, String userEmail) async {
    final String householdId = _uuid.v4();
    final String joinCode = _uuid.v4().substring(0, 6).toUpperCase(); // Generate a 6-character join code

    final Household personalHousehold = Household(
      id: householdId,
      name: "$userEmail's Personal Pantry",
      ownerId: userId,
      members: [userId],
      joinCode: joinCode,
      isPersonal: true,
    );

    await _db.collection('households').doc(householdId).set(personalHousehold.toFirestore());

    // Update the user document with their personal household ID and add to householdIds
    await _db.collection('users').doc(userId).set({
      'email': userEmail,
      'personalHouseholdId': householdId,
      'householdIds': FieldValue.arrayUnion([householdId]),
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true)); // Use merge to avoid overwriting existing user data

    selectedHouseholdId = householdId; // Automatically select the personal household
    // Also set the initial nickname for the user
    await _db.collection('users').doc(userId).update({
      'nickname': userEmail.split('@').first, // Default nickname from email
    });
  }

  // Get a stream of pantry items for a specific household
  Stream<List<PantryItemModel>> getPantryItemsForHousehold(String householdId) {
    return _db
        .collection('pantryItems')
        .where('householdId', isEqualTo: householdId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PantryItemModel.fromFirestore(doc))
            .toList());
  }

  // Add a new pantry item for the currently selected household
  Future<void> addPantryItem(PantryItemModel item) async {
    if (selectedHouseholdId == null) {
      throw Exception("No household selected.");
    }
    await _db.collection('pantryItems').add(item.toFirestore());
  }

  // Update an existing pantry item for the currently selected household
  Future<void> updatePantryItem(PantryItemModel item) async {
    if (selectedHouseholdId == null || item.id == null) {
      throw Exception("No household selected or item ID is missing.");
    }
    await _db.collection('pantryItems').doc(item.id).update(item.toFirestore());
  }

  // --- Shopping List Methods ---

  // Get a stream of shopping lists for a specific household
  Stream<List<ShoppingListModel>> getShoppingListsForHousehold(String householdId) {
    return _db
        .collection('shoppingLists')
        .where('householdId', isEqualTo: householdId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ShoppingListModel.fromFirestore(doc))
            .toList());
  }

  // Add a new shopping list for the currently selected household
  Future<void> addShoppingList(ShoppingListModel list) async {
    if (selectedHouseholdId == null) {
      throw Exception("No household selected.");
    }
    await _db.collection('shoppingLists').add(list.toFirestore());
  }

  // Update an existing shopping list for the currently selected household
  Future<void> updateShoppingList(ShoppingListModel list) async {
    if (selectedHouseholdId == null || list.id == null) {
      throw Exception("No household selected or list ID is missing.");
    }
    await _db.collection('shoppingLists').doc(list.id).update(list.toFirestore());
  }

  // Delete a shopping list
  Future<void> deleteShoppingList(String listId) async {
    if (selectedHouseholdId == null) {
      throw Exception("No household selected.");
    }
    await _db.collection('shoppingLists').doc(listId).delete();
  }

  // Set a specific shopping list as active and deactivate all others for the household
  Future<void> setActiveShoppingList(String listId, String householdId) async {
    // Deactivate all other lists for this household
    final querySnapshot = await _db
        .collection('shoppingLists')
        .where('householdId', isEqualTo: householdId)
        .where('isActive', isEqualTo: true)
        .get();

    for (final doc in querySnapshot.docs) {
      await _db.collection('shoppingLists').doc(doc.id).update({'isActive': false});
    }

    // Activate the selected list
    await _db.collection('shoppingLists').doc(listId).update({'isActive': true});
  }

  // Get the currently active shopping list for a household
  Stream<ShoppingListModel?> getActiveShoppingListForHousehold(String householdId) {
    return _db
        .collection('shoppingLists')
        .where('householdId', isEqualTo: householdId)
        .where('isActive', isEqualTo: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isNotEmpty) {
            return ShoppingListModel.fromFirestore(snapshot.docs.first);
          }
          return null;
        });
  }

  // --- Shopping History Methods (new model) ---

  // Add an item to shopping history
  Future<void> addShoppingHistoryItem(ShoppingHistoryItemModel item) async {
    if (selectedHouseholdId == null) {
      throw Exception("No household selected.");
    }
    await _db.collection('shoppingHistory').add(item.toFirestore());
  }

  // Get a stream of shopping history items for a specific household
  Stream<List<ShoppingHistoryItemModel>> getShoppingHistoryForHousehold(String householdId) {
    return _db
        .collection('shoppingHistory')
        .where('householdId', isEqualTo: householdId)
        .orderBy('purchaseDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ShoppingHistoryItemModel.fromFirestore(doc))
            .toList());
  }

  // Mark a pantry item as deleted for the currently selected household
  Future<void> deletePantryItem(String itemId) async {
    if (selectedHouseholdId == null) {
      throw Exception("No household selected.");
    }

    // Get the item details before deleting/updating
    final itemDoc = await _db.collection('pantryItems').doc(itemId).get();
    if (!itemDoc.exists) {
      return; // Item doesn't exist
    }
    final item = PantryItemModel.fromFirestore(itemDoc);

    // Determine productId from local_products_ph if barcode is available
    String? productId;
    if (item.barcode != null && item.barcode!.isNotEmpty) {
      final productQuery = await _db.collection('local_products_ph').where('barcode', isEqualTo: item.barcode).limit(1).get();
      if (productQuery.docs.isNotEmpty) {
        productId = productQuery.docs.first.id;
      }
    }

    // Update the status to 'Deleted'
    await _db.collection('pantryItems').doc(itemId).update({
      'status': 'Deleted',
      'deletedAt': FieldValue.serverTimestamp(),
    });

    // Add a record to the shopping history for the deletion
    final historyItem = ShoppingHistoryItemModel(
      householdId: selectedHouseholdId!,
      productId: productId, // Use the fetched productId
      productName: item.name,
      category: item.category,
      quantity: item.qty, // Log the quantity that was deleted
      purchaseDate: DateTime.now(), // Represents deletion date
      actionType: 'Deleted', // Set action type to 'Deleted'
    );
    await _db.collection('shoppingHistory').add(historyItem.toFirestore());
  }

  // Record consumed items
  Future<void> recordConsumedItem(PantryItemModel item, int consumedQty) async {
    if (selectedHouseholdId == null) {
      throw Exception("No household selected.");
    }

    if (consumedQty <= 0) {
      return; // Nothing to consume
    }

    // First, update the original item's quantity in the pantry
    if (item.qty > consumedQty) {
      await _db.collection('pantryItems').doc(item.id).update({
        'qty': item.qty - consumedQty,
      });
    } else {
      // If all available quantity is consumed, delete the item from the pantry
      await _db.collection('pantryItems').doc(item.id).delete();
    }

    // Determine productId from local_products_ph if barcode is available
    String? productId;
    if (item.barcode != null && item.barcode!.isNotEmpty) {
      final productQuery = await _db.collection('local_products_ph').where('barcode', isEqualTo: item.barcode).limit(1).get();
      if (productQuery.docs.isNotEmpty) {
        productId = productQuery.docs.first.id;
      }
    }

    // Add a record to the shopping history
    final historyItem = ShoppingHistoryItemModel(
      householdId: selectedHouseholdId!,
      productId: productId, // Use the fetched productId
      productName: item.name,
      category: item.category,
      quantity: consumedQty,
      purchaseDate: DateTime.now(), // Represents consumption date
      actionType: 'Consumed', // Set action type to 'Consumed'
    );
    await _db.collection('shoppingHistory').add(historyItem.toFirestore());
  }

  // Clean up old shopping history items (e.g., older than 30 days)
  Future<void> cleanUpShoppingHistoryItems(String householdId) async {
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));

    final historyQuery = await _db
        .collection('shoppingHistory')
        .where('householdId', isEqualTo: householdId)
        .where('purchaseDate', isLessThan: thirtyDaysAgo)
        .get();

    for (final doc in historyQuery.docs) {
      await doc.reference.delete();
    }
  }

  // Get a stream of households for the current user
  Stream<List<Household>> getHouseholds() {
    if (userId == null) {
      return Stream.value([]);
    }
    return _db
        .collection('users')
        .doc(userId)
        .snapshots()
        .asyncMap((userDoc) async {
      if (!userDoc.exists || userDoc.data()?['householdIds'] == null) {
        return [];
      }
      List<String> householdIds = List<String>.from(userDoc.data()!['householdIds']);
      if (householdIds.isEmpty) {
        return [];
      }
      final querySnapshot = await _db.collection('households').where(FieldPath.documentId, whereIn: householdIds).get();
      return querySnapshot.docs.map((doc) => Household.fromFirestore(doc)).toList();
    });
  }

  // Create a new household
  Future<void> createHousehold(String name) async {
    if (userId == null) {
      throw Exception("User not logged in.");
    }
    final String householdId = _uuid.v4();
    final String joinCode = _uuid.v4().substring(0, 6).toUpperCase();

    final Household newHousehold = Household(
      id: householdId,
      name: name,
      ownerId: userId!,
      members: [userId!],
      joinCode: joinCode,
      isPersonal: false,
    );

    await _db.collection('households').doc(householdId).set(newHousehold.toFirestore());

    // Add householdId to the user's householdIds array
    await _db.collection('users').doc(userId).update({
      'householdIds': FieldValue.arrayUnion([householdId]),
    });
    // Set a default nickname if not already set
    final userDoc = await _db.collection('users').doc(userId).get();
    if (userDoc.data()?['nickname'] == null) {
      await _db.collection('users').doc(userId).update({
        'nickname': _auth.currentUser?.email?.split('@').first ?? 'User',
      });
    }
  }

  // Join an existing household
  Future<void> joinHousehold(String joinCode) async {
    if (userId == null) {
      throw Exception("User not logged in.");
    }

    final querySnapshot = await _db.collection('households').where('joinCode', isEqualTo: joinCode).limit(1).get();

    if (querySnapshot.docs.isEmpty) {
      throw Exception("Invalid join code.");
    }

    final householdDoc = querySnapshot.docs.first;
    final Household household = Household.fromFirestore(householdDoc);

    if (household.members.contains(userId)) {
      throw Exception("You are already a member of this household.");
    }

    // Add user to household members
    await _db.collection('households').doc(household.id).update({
      'members': FieldValue.arrayUnion([userId!]),
    });

    // Add householdId to the user's householdIds array
    await _db.collection('users').doc(userId).update({
      'householdIds': FieldValue.arrayUnion([household.id]),
    });
    // Set a default nickname if not already set
    final userDoc = await _db.collection('users').doc(userId).get();
    if (userDoc.data()?['nickname'] == null) {
      await _db.collection('users').doc(userId).update({
        'nickname': _auth.currentUser?.email?.split('@').first ?? 'User',
      });
    }
  }

  // Get user data by ID
  Future<UserModel?> getUser(String userId) async {
    final doc = await _db.collection('users').doc(userId).get();
    if (doc.exists) {
      return UserModel.fromFirestore(doc);
    }
    return null;
  }


  // Update a user's nickname
  Future<void> updateUserNickname(String userId, String nickname) async {
    await _db.collection('users').doc(userId).update({
      'nickname': nickname,
    });
  }

  // Leave a household
  Future<void> leaveHousehold(String householdId, String userId) async {
    // Remove user from the household's members array
    await _db.collection('households').doc(householdId).update({
      'members': FieldValue.arrayRemove([userId]),
    });

    // Remove householdId from the user's householdIds array
    await _db.collection('users').doc(userId).update({
      'householdIds': FieldValue.arrayRemove([householdId]),
    });
    notifyListeners(); // Notify listeners after leaving a household
  }

  // Delete all shopping history items for a specific household
  Future<void> deleteAllShoppingHistoryItems(String householdId) async {
    final historyQuery = await _db
        .collection('shoppingHistory')
        .where('householdId', isEqualTo: householdId)
        .get();

    for (final doc in historyQuery.docs) {
      await doc.reference.delete();
    }
  }

  // Search for products in the local_products_ph collection
  Stream<List<Product>> searchProducts(String query) {
    if (query.isEmpty) {
      return Stream.value([]);
    }
    return _db
        .collection('local_products_ph')
        .where('productName', isGreaterThanOrEqualTo: query)
        .where('productName', isLessThanOrEqualTo: '$query\uf8ff')
        .limit(10) // Limit to 10 suggestions
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Product.fromFirestore(doc))
            .toList());
  }
}
