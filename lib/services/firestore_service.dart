import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shelf_control/models/pantry_item_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get userId => _auth.currentUser?.uid;

  // Get a stream of pantry items for the current user
  Stream<List<PantryItemModel>> getPantryItems() {
    if (userId == null) {
      return Stream.value([]); // Return an empty stream if no user is logged in
    }
    return _db
        .collection('users')
        .doc(userId)
        .collection('pantryItems')
        .orderBy('timestamp', descending: true) // Order by timestamp for consistent display
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PantryItemModel.fromFirestore(doc))
            .toList());
  }

  // Add a new pantry item for the current user
  Future<void> addPantryItem(PantryItemModel item) async {
    if (userId == null) {
      throw Exception("User not logged in.");
    }
    await _db
        .collection('users')
        .doc(userId)
        .collection('pantryItems')
        .add(item.toFirestore());
  }

  // Update an existing pantry item for the current user
  Future<void> updatePantryItem(PantryItemModel item) async {
    if (userId == null || item.id == null) {
      throw Exception("User not logged in or item ID is missing.");
    }
    await _db
        .collection('users')
        .doc(userId)
        .collection('pantryItems')
        .doc(item.id)
        .update(item.toFirestore());
  }

  // Delete a pantry item for the current user
  Future<void> deletePantryItem(String itemId) async {
    if (userId == null) {
      throw Exception("User not logged in.");
    }
    await _db
        .collection('users')
        .doc(userId)
        .collection('pantryItems')
        .doc(itemId)
        .delete();
  }
}
