import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart'; // Import for ChangeNotifier
import 'package:shelf_control/models/pantry_item_model.dart';
import 'package:shelf_control/models/household_model.dart'; // Import Household model
import 'package:shelf_control/models/user_model.dart'; // Import UserModel
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

  // Mark a pantry item as deleted for the currently selected household
  Future<void> deletePantryItem(String itemId) async {
    if (selectedHouseholdId == null) {
      throw Exception("No household selected.");
    }
    await _db.collection('pantryItems').doc(itemId).update({
      'status': 'Deleted',
      'deletedAt': FieldValue.serverTimestamp(),
    });
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

    // Now, handle the consumed portion for history
    QuerySnapshot existingConsumedItems;
    if (item.barcode != null && item.barcode!.isNotEmpty) {
      // Try to find an existing consumed item by barcode
      existingConsumedItems = await _db
          .collection('pantryItems')
          .where('householdId', isEqualTo: selectedHouseholdId)
          .where('status', isEqualTo: 'Consumed')
          .where('barcode', isEqualTo: item.barcode)
          .limit(1)
          .get();
    } else {
      // Fallback to name if no barcode
      existingConsumedItems = await _db
          .collection('pantryItems')
          .where('householdId', isEqualTo: selectedHouseholdId)
          .where('status', isEqualTo: 'Consumed')
          .where('name', isEqualTo: item.name)
          .limit(1)
          .get();
    }

    if (existingConsumedItems.docs.isNotEmpty) {
      // Update existing consumed item
      final existingDoc = existingConsumedItems.docs.first;
      final existingItem = PantryItemModel.fromFirestore(existingDoc);
      await _db.collection('pantryItems').doc(existingDoc.id).update({
        'qty': existingItem.qty + consumedQty,
        'consumedAt': FieldValue.serverTimestamp(), // Update to latest consumption time
      });
    } else {
      // Create a new consumed entry
      final consumedItem = item.copyWith(
        id: null, // Let Firestore generate a new ID
        qty: consumedQty,
        status: 'Consumed',
        consumedAt: DateTime.now(),
        // Ensure other fields like barcode, name, etc., are copied for identification
      );
      await _db.collection('pantryItems').add(consumedItem.toFirestore());
    }
  }

  // Get a stream of history items (consumed or deleted) for a specific household
  Stream<List<PantryItemModel>> getHistoryItemsForHousehold(String householdId) {
    return _db
        .collection('pantryItems')
        .where('householdId', isEqualTo: householdId)
        .where('status', whereIn: ['Consumed', 'Deleted'])
        .orderBy('consumedAt', descending: true) // Order by consumedAt first
        .orderBy('deletedAt', descending: true) // Then by deletedAt
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PantryItemModel.fromFirestore(doc))
            .toList());
  }

  // Clean up history items older than 30 days
  Future<void> cleanUpHistoryItems(String householdId) async {
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));

    // Query for consumed items older than 30 days
    final consumedQuery = await _db
        .collection('pantryItems')
        .where('householdId', isEqualTo: householdId)
        .where('status', isEqualTo: 'Consumed')
        .where('consumedAt', isLessThan: thirtyDaysAgo)
        .get();

    for (final doc in consumedQuery.docs) {
      await doc.reference.delete();
    }

    // Query for deleted items older than 30 days
    final deletedQuery = await _db
        .collection('pantryItems')
        .where('householdId', isEqualTo: householdId)
        .where('status', isEqualTo: 'Deleted')
        .where('deletedAt', isLessThan: thirtyDaysAgo)
        .get();

    for (final doc in deletedQuery.docs) {
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

  // Delete all history items (consumed and deleted) for a specific household
  Future<void> deleteAllHistoryItems(String householdId) async {
    final historyQuery = await _db
        .collection('pantryItems')
        .where('householdId', isEqualTo: householdId)
        .where('status', whereIn: ['Consumed', 'Deleted'])
        .get();

    for (final doc in historyQuery.docs) {
      await doc.reference.delete();
    }
  }
}
