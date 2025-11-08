import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart'; // Import for ChangeNotifier
import 'package:shelf_control/models/pantry_item_model.dart';
import 'package:shelf_control/models/household_model.dart'; // Import Household model
import 'package:shelf_control/models/product_model.dart'; // Import Product model
import 'package:shelf_control/models/user_model.dart'; // Import UserModel
import 'package:shelf_control/models/shopping_list_model.dart'; // Import ShoppingListModel
import 'package:shelf_control/models/shopping_list_item_model.dart'; // Import ShoppingListItemModel
import 'package:shelf_control/models/shopping_history_item_model.dart'; // Import ShoppingHistoryItemModel
import 'package:shelf_control/models/app_notification_model.dart'; // Import AppNotificationModel
import 'package:shelf_control/models/household_task_model.dart'; // Import HouseholdTaskModel
import 'package:shelf_control/services/open_food_facts_service.dart'; // Import OpenFoodFactsService
import 'package:uuid/uuid.dart'; // For generating unique IDs
import 'package:shared_preferences/shared_preferences.dart'; // Import SharedPreferences
import 'dart:convert'; // For JSON encoding/decoding
// import 'package:fuzzywuzzy/fuzzywuzzy.dart'; // Removed fuzzywuzzy
import 'package:shelf_control/models/user_prefs_model.dart';
import 'package:shelf_control/services/normalization.dart';
import 'package:firebase_storage/firebase_storage.dart'; // Import Firebase Storage
import 'dart:io'; // For File type
import 'package:shelf_control/models/waste_report_model.dart'; // Import WasteReportModel
import 'package:flutter/foundation.dart'; // For Uint8List
import 'package:shared_preferences/shared_preferences.dart'; // Import SharedPreferences for rate limiting

class FirestoreService extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance; // Instantiate Firebase Storage
  final Uuid _uuid = const Uuid(); // Instantiate Uuid
  final ValueNotifier<String?> householdIdNotifier = ValueNotifier<String?>(null);

  // Key for storing the last notification check timestamp in SharedPreferences
  static const String _lastPantrySummaryNotificationCheckKey = 'lastPantrySummaryNotificationCheck_';
  static const Duration _notificationCheckInterval = Duration(hours: 24); // Default to 24 hours

  FirebaseFirestore get db => _db; // Public getter for _db

  String? get userId => _auth.currentUser?.uid;

  // This will be set by the UI when a household is selected
  String? _selectedHouseholdId; // Make it private

  String? get selectedHouseholdId => _selectedHouseholdId;

  // Setter for selectedHouseholdId that also persists the value
  set selectedHouseholdId(String? value) {
    if (_selectedHouseholdId != value) {
      _selectedHouseholdId = value;
      debugPrint('DEBUG: FirestoreService.selectedHouseholdId set to: $value');
      _saveSelectedHouseholdId(value); // Save to SharedPreferences
      notifyListeners(); // Notify listeners when the selected household changes
    }
  }

  /// Returns all pantry items for a household.
  Future<List<PantryItemModel>> getPantryForHousehold(
      String householdId) async {
    debugPrint('DEBUG: getPantryForHousehold called for householdId: $householdId');
    final snap = await FirebaseFirestore.instance
        .collection('pantryItems') // Query top-level pantryItems collection
        .where('householdId', isEqualTo: householdId) // Filter by householdId
        .get();

    // If your model has a factory like fromFirestore(DocumentSnapshot):
    // return snap.docs.map((d) => PantryItemModel.fromFirestore(d)).toList();

    // If your model has fromJson(Map<String,dynamic>):
    return snap.docs.map((d) {
      final data = d.data();
      // Include doc id if your model expects it
      return PantryItemModel.fromJson({...data, 'id': d.id});
    }).toList();
  }

  /// Returns user preferences for a user.
  Future<UserPrefs> getUserPrefs({
    required String userId,
    required String householdId,
  }) async {
    debugPrint('DEBUG: getUserPrefs called for userId: $userId, householdId: $householdId');
    // Adjust the path if your prefs live elsewhere
    final doc = await FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .collection('settings')
      .doc('preferences')
      .get();

  if (!doc.exists) {
    // Return defaults but include both required fields
    return UserPrefs(
      userId: userId,
      householdId: householdId,        // ← REQUIRED
      diets: const <String>[],
      allergens: const <String>[],
      dislikes: const <String>[],
      // Provide reasonable defaults if your model requires them:
      dailyCaloriesTarget: 2000,
      maxCookMinutes: 45,
      defaultServings: 2,
    );
  }

  final data = (doc.data() as Map<String, dynamic>?) ?? <String, dynamic>{};

  // Normalize lists → List<String>
  List<String> _asList(dynamic v) {
    if (v is List) {
      return v.map((e) => e?.toString() ?? '').where((s) => s.isNotEmpty).toList();
    }
    return <String>[];
  }

  final diets     = _asList(data['diets']);
  final allergens = _asList(data['allergens']);
  final dislikes  = _asList(data['dislikes']);

  // Your model provides a factory: UserPrefs.fromFirestore(Map<String,dynamic>)
  // Merge userId and householdId so the factory gets both required fields.
  return UserPrefs.fromFirestore({
    ...data,
    'userId': userId,
    'householdId': householdId,
    // Ensure ints exist if your factory expects them:
    'dailyCaloriesTarget': data['dailyCaloriesTarget'] ?? 2000,
    'maxCookMinutes': data['maxCookMinutes'] ?? 45,
    'defaultServings': data['defaultServings'] ?? 2,
    // And overwrite lists with normalized ones
    'diets': diets,
    'allergens': allergens,
    'dislikes': dislikes,
  });
}

  // Save selected household ID to SharedPreferences
  Future<void> _saveSelectedHouseholdId(String? householdId) async {
    final prefs = await SharedPreferences.getInstance();
    if (householdId != null) {
      await prefs.setString('selectedHouseholdId', householdId);
      debugPrint('DEBUG: _saveSelectedHouseholdId: Saved $householdId to SharedPreferences.');
    } else {
      await prefs.remove('selectedHouseholdId');
      debugPrint('DEBUG: _saveSelectedHouseholdId: Removed selectedHouseholdId from SharedPreferences.');
    }
  }

  // Load selected household ID from SharedPreferences
  Future<String?> _loadSelectedHouseholdId() async {
    final prefs = await SharedPreferences.getInstance();
    final String? loadedId = prefs.getString('selectedHouseholdId');
    _selectedHouseholdId = loadedId;
    householdIdNotifier.value = _selectedHouseholdId;
    debugPrint('DEBUG: _loadSelectedHouseholdId: Loaded $loadedId from SharedPreferences.');
    return loadedId;
  }

  // Clear selected household ID from SharedPreferences
  Future<void> clearSelectedHouseholdId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('selectedHouseholdId');
    _selectedHouseholdId = null; // Also clear in-memory
    debugPrint('DEBUG: clearSelectedHouseholdId: Cleared selectedHouseholdId.');
    notifyListeners();
  }

  // Set the initial selected household for a user
  Future<void> setInitialHousehold(String userId) async {
    debugPrint('DEBUG: setInitialHousehold called for userId: $userId');
    debugPrint(
        'DEBUG: Current user is anonymous: ${_auth.currentUser?.isAnonymous ?? false}');

    // Always try to get the personal household ID for authenticated users first
    final userDoc = await _db.collection('users').doc(userId).get();
    String? personalHouseholdId = userDoc.exists && userDoc.data() != null
        ? userDoc.data()!['personalHouseholdId'] as String?
        : null;

    if (!(_auth.currentUser?.isAnonymous ?? false)) {
      // For authenticated users:
      // 1. Prioritize personalHouseholdId
      if (personalHouseholdId != null) {
        selectedHouseholdId = personalHouseholdId;
        debugPrint('DEBUG: Set selectedHouseholdId for authenticated user to personalHouseholdId: $selectedHouseholdId');
        return;
      } else {
        // This case should ideally not happen for a registered user.
        // If it does, it means their user document is missing personalHouseholdId.
        // We might need to create one or handle this as an error.
        debugPrint('DEBUG: Authenticated user has no personalHouseholdId. Attempting to create one.');
        await createPersonalHousehold(userId, _auth.currentUser?.email ?? 'unknown@user.com');
        return;
      }
    } else {
      // For anonymous users:
      // 1. Try to load from SharedPreferences
      String? storedHouseholdId = await _loadSelectedHouseholdId();
      debugPrint('DEBUG: Stored household ID from SharedPreferences (anonymous): $storedHouseholdId');

      if (storedHouseholdId != null) {
        // Check if the stored household still exists and the user is a member (should be userId for anonymous)
        final householdDoc = await _db.collection('households').doc(storedHouseholdId).get();
        if (householdDoc.exists && householdDoc.data() != null && householdDoc.data()!['members'].contains(userId)) {
          selectedHouseholdId = storedHouseholdId;
          debugPrint('DEBUG: Set selectedHouseholdId from stored (anonymous): $selectedHouseholdId');
          return;
        }
      }

      // If no valid stored household, default to personal household (which is userId for anonymous)
      selectedHouseholdId = userId;
      debugPrint(
          'DEBUG: Set selectedHouseholdId for anonymous user: $selectedHouseholdId');
      // Ensure a personal household is created for anonymous users if it doesn't exist
      final householdDoc = await _db.collection('households').doc(userId).get();
      if (!householdDoc.exists) {
        debugPrint('DEBUG: Creating personal household for anonymous user: $userId');
        await createPersonalHousehold(
            userId, 'anonymous@guest.com'); // Use a dummy email for anonymous
      }
    }
    debugPrint(
        'DEBUG: Final selectedHouseholdId after setInitialHousehold: $selectedHouseholdId');
  }

  // Create a personal household for a new user (or anonymous user)
  Future<void> createPersonalHousehold(String userId, String userEmail) async {
    debugPrint('DEBUG: createPersonalHousehold called for userId: $userId, email: $userEmail');
    // For personal households, the householdId is the userId
    final String householdId = userId;
    final String joinCode = _uuid
        .v4()
        .substring(0, 6)
        .toUpperCase(); // Generate a 6-character join code

    final Household personalHousehold = Household(
      id: householdId,
      name: "My Pantry",
      ownerId: userId,
      members: [userId],
      joinCode: joinCode,
      isPersonal: true,
    );

    await _db
        .collection('households')
        .doc(householdId)
        .set(personalHousehold.toFirestore());
    debugPrint('DEBUG: Created personal household: $householdId');

    // Update the user document with their personal household ID and add to householdIds
    await _db.collection('users').doc(userId).set(
        {
          'email': userEmail,
          'personalHouseholdId': householdId,
          'householdIds': FieldValue.arrayUnion([householdId]),
          'createdAt': FieldValue.serverTimestamp(),
        },
        SetOptions(
            merge: true)); // Use merge to avoid overwriting existing user data
    debugPrint('DEBUG: Updated user $userId with personalHouseholdId: $householdId');

    selectedHouseholdId =
        householdId; // Automatically select the personal household
    // Also set the initial nickname for the user
    await _db.collection('users').doc(userId).update({
      'nickname': userEmail.split('@').first, // Default nickname from email
    });
  }

  // --- Local Storage Methods for Guest Users ---

  static const String _guestPantryKey = 'guestPantryItems';
  static const String _guestShoppingListKey = 'guestShoppingLists';
  static const String _guestShoppingHistoryKey = 'guestShoppingHistoryItems'; // New key for guest shopping history

  // Save guest pantry items to local storage
  Future<void> saveGuestPantryItems(List<PantryItemModel> items) async {
    final prefs = await SharedPreferences.getInstance();
    final String encodedData =
        json.encode(items.map((item) => item.toJson()).toList());
    await prefs.setString(_guestPantryKey, encodedData);
    debugPrint(
        'DEBUG: Saved ${items.length} guest pantry items to SharedPreferences.');
    debugPrint('DEBUG: Encoded guest pantry data: $encodedData');
    notifyListeners(); // Notify listeners that guest pantry data has changed
  }

  // Load guest pantry items from local storage
  Future<List<PantryItemModel>> loadGuestPantryItems() async {
    final prefs = await SharedPreferences.getInstance();
    final String? encodedData = prefs.getString(_guestPantryKey);
    if (encodedData == null) {
      debugPrint('DEBUG: No guest pantry data found in SharedPreferences.');
      return [];
    }
    final List<dynamic> decodedData = json.decode(encodedData);
    final List<PantryItemModel> loadedItems =
        decodedData.map((data) => PantryItemModel.fromJson(data)).toList();
    debugPrint(
        'DEBUG: Loaded ${loadedItems.length} guest pantry items from SharedPreferences.');
    debugPrint('DEBUG: Decoded guest pantry data: $encodedData');
    return loadedItems;
  }

  // Save guest shopping lists to local storage
  Future<void> saveGuestShoppingLists(List<ShoppingListModel> lists) async {
    final prefs = await SharedPreferences.getInstance();
    final String encodedData =
        json.encode(lists.map((list) => list.toJson()).toList());
    await prefs.setString(_guestShoppingListKey, encodedData);
    debugPrint('DEBUG: Saved ${lists.length} guest shopping lists to SharedPreferences.');
  }

  // Load guest shopping lists from local storage
  Future<List<ShoppingListModel>> loadGuestShoppingLists() async {
    final prefs = await SharedPreferences.getInstance();
    final String? encodedData = prefs.getString(_guestShoppingListKey);
    if (encodedData == null) {
      debugPrint('DEBUG: No guest shopping list data found in SharedPreferences.');
      return [];
    }
    final List<dynamic> decodedData = json.decode(encodedData);
    final List<ShoppingListModel> loadedLists = decodedData.map((data) => ShoppingListModel.fromJson(data)).toList();
    debugPrint('DEBUG: Loaded ${loadedLists.length} guest shopping lists from SharedPreferences.');
    return loadedLists;
  }

  // Stream for guest shopping lists from local storage
  Stream<List<ShoppingListModel>> guestShoppingListsStream() {
    debugPrint('DEBUG: guestShoppingListsStream called.');
    // This is a simplified stream for guest mode, as SharedPreferences doesn't have native stream support.
    // It will emit the current state whenever `saveGuestShoppingLists` is called.
    // For a more robust solution, a StreamController could be used within FirestoreService.
    return Stream.fromFuture(loadGuestShoppingLists());
  }

  // Save guest shopping history items to local storage
  Future<void> saveGuestShoppingHistoryItems(List<ShoppingHistoryItemModel> items) async {
    final prefs = await SharedPreferences.getInstance();
    final String encodedData = json.encode(items.map((item) => item.toJson()).toList());
    await prefs.setString(_guestShoppingHistoryKey, encodedData);
    debugPrint('DEBUG: Saved ${items.length} guest shopping history items to SharedPreferences.');
    notifyListeners(); // Notify listeners that guest shopping history data has changed
  }

  // Load guest shopping history items from local storage
  Future<List<ShoppingHistoryItemModel>> loadGuestShoppingHistoryItems() async {
    final prefs = await SharedPreferences.getInstance();
    final String? encodedData = prefs.getString(_guestShoppingHistoryKey);
    if (encodedData == null) {
      debugPrint('DEBUG: No guest shopping history data found in SharedPreferences.');
      return [];
    }
    final List<dynamic> decodedData = json.decode(encodedData);
    final List<ShoppingHistoryItemModel> loadedItems = decodedData.map((data) => ShoppingHistoryItemModel.fromJson(data)).toList();
    debugPrint('DEBUG: Loaded ${loadedItems.length} guest shopping history items from SharedPreferences.');
    return loadedItems;
  }

  // Clear all guest data from local storage
  Future<void> clearGuestData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_guestPantryKey);
    await prefs.remove(_guestShoppingListKey);
    await prefs.remove(_guestShoppingHistoryKey); // Clear guest shopping history
    debugPrint('DEBUG: Cleared all guest data from SharedPreferences.');
  }

  // Get a stream of pantry items for a specific household
  Stream<List<PantryItemModel>> getPantryItemsForHousehold(String householdId) {
    debugPrint('DEBUG: getPantryItemsForHousehold called for householdId: $householdId');
    if (_auth.currentUser?.isAnonymous ?? false) {
      return Stream.fromFuture(loadGuestPantryItems());
    }
    return _db
        .collection('pantryItems')
        .where('householdId', isEqualTo: householdId)
        .orderBy('timestamp', descending: true) // keep if you have this field
        .snapshots()
        .map((snapshot) {
          debugPrint('DEBUG: getPantryItemsForHousehold stream update for householdId: $householdId, items: ${snapshot.docs.length}');
          final List<PantryItemModel> items = snapshot.docs
            .map((doc) => PantryItemModel.fromFirestore(doc))
            .toList();

          final now = DateTime.now();
          final batch = _db.batch();
          bool changesMade = false;

          for (var item in items) {
            // Check for expired items that are still 'Available'
            if (item.expirationDate != null &&
                item.expirationDate!.isBefore(now) &&
                item.status == 'Available') {
              debugPrint('DEBUG: Item ${item.name} (ID: ${item.id}) expired. Marking as wasted.');
              batch.update(
                _db.collection('pantryItems').doc(item.id),
                {
                  'status': 'wasted',
                  'wastedAt': Timestamp.fromDate(now),
                },
              );
              item.status = 'wasted'; // Update in memory for current stream emission
              item.wastedAt = now;
              changesMade = true;
            }
          }

          if (changesMade) {
            batch.commit().then((_) {
              debugPrint('DEBUG: Batch commit for expired items completed.');
            }).catchError((error) {
              debugPrint('ERROR: Batch commit for expired items failed: $error');
            });
          }

          return items;
        });
  }

  // Add a new pantry item for the currently selected household
  Future<void> addPantryItem(PantryItemModel item) async {
    if (selectedHouseholdId == null) {
      throw Exception("No household selected.");
    }
    debugPrint('DEBUG: addPantryItem called for householdId: $selectedHouseholdId, item: ${item.name}');

    if (_auth.currentUser?.isAnonymous ?? false) {
      // For guest users, save to local storage
      List<PantryItemModel> currentGuestPantry = await loadGuestPantryItems();
      // Assign a temporary ID for guest items if not already present
      PantryItemModel itemWithId =
          item.copyWith(id: item.id?.isEmpty ?? true ? _uuid.v4() : item.id!);
      currentGuestPantry.add(itemWithId);
      await saveGuestPantryItems(currentGuestPantry);
    } else {
      // For registered users, save to Firestore
      await _pantryCol(selectedHouseholdId!)
          .add(item.copyWith(timestamp: DateTime.now()).toFirestore());
    }
  }

  // Update an existing pantry item for the currently selected household
  Future<void> updatePantryItem(PantryItemModel item) async {
    if (selectedHouseholdId == null || item.id == null) {
      throw Exception("No household selected or item ID is missing.");
    }
    debugPrint('DEBUG: updatePantryItem called for householdId: $selectedHouseholdId, item: ${item.name}');

    if (_auth.currentUser?.isAnonymous ?? false) {
      // For guest users, update in local storage
      List<PantryItemModel> currentGuestPantry = await loadGuestPantryItems();
      int itemIndex =
          currentGuestPantry.indexWhere((element) => element.id == item.id);
      if (itemIndex != -1) {
        currentGuestPantry[itemIndex] = item;
        await saveGuestPantryItems(currentGuestPantry);
      }
    } else {
      // For registered users, update in Firestore
      await _pantryCol(selectedHouseholdId!)
          .doc(item.id)
          .update(item.copyWith(timestamp: DateTime.now()).toFirestore());
    }
  }

  // --- Shopping List Methods ---

  // Get a stream of shopping lists for a specific household
  Stream<List<ShoppingListModel>> getShoppingListsForHousehold(
      String householdId) {
    debugPrint('DEBUG: getShoppingListsForHousehold called for householdId: $householdId');
    if (_auth.currentUser?.isAnonymous ?? false) {
      // For guest users, return a stream from local storage
      return Stream.fromFuture(loadGuestShoppingLists());
    }
    return _db
        .collection('shoppingLists')
        .where('householdId', isEqualTo: householdId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          debugPrint('DEBUG: getShoppingListsForHousehold stream update for householdId: $householdId, lists: ${snapshot.docs.length}');
          return snapshot.docs
            .map((doc) => ShoppingListModel.fromFirestore(doc))
            .toList();
        });
  }

  // Add a new shopping list for the currently selected household
  Future<void> addShoppingList(ShoppingListModel list) async {
    if (selectedHouseholdId == null) {
      throw Exception("No household selected.");
    }
    debugPrint('DEBUG: addShoppingList called for householdId: $selectedHouseholdId, list: ${list.name}');
    await _db.collection('shoppingLists').add(list.toFirestore());
  }

  // Update an existing shopping list for the currently selected household
  Future<void> updateShoppingList(ShoppingListModel list) async {
    if (selectedHouseholdId == null || list.id == null) {
      throw Exception("No household selected or list ID is missing.");
    }
    debugPrint('DEBUG: updateShoppingList called for householdId: $selectedHouseholdId, list: ${list.name}');
    await _db
        .collection('shoppingLists')
        .doc(list.id)
        .update(list.toFirestore());
  }

  // Delete a shopping list
  Future<void> deleteShoppingList(String listId) async {
    if (selectedHouseholdId == null) {
      throw Exception("No household selected.");
    }
    debugPrint('DEBUG: deleteShoppingList called for householdId: $selectedHouseholdId, listId: $listId');
    await _db.collection('shoppingLists').doc(listId).delete();
  }

  // Delete a household and all associated data
  Future<void> deleteHousehold(String householdId) async {
    debugPrint('DEBUG: deleteHousehold called for householdId: $householdId');
    // 1. Delete all pantry items for the household
    final pantryItemsQuery = await _db
        .collection('pantryItems')
        .where('householdId', isEqualTo: householdId)
        .get();
    for (final doc in pantryItemsQuery.docs) {
      await doc.reference.delete();
    }
    debugPrint('DEBUG: Deleted ${pantryItemsQuery.docs.length} pantry items for household: $householdId');

    // 2. Delete all shopping lists for the household
    final shoppingListsQuery = await _db
        .collection('shoppingLists')
        .where('householdId', isEqualTo: householdId)
        .get();
    for (final doc in shoppingListsQuery.docs) {
      await doc.reference.delete();
    }
    debugPrint('DEBUG: Deleted ${shoppingListsQuery.docs.length} shopping lists for household: $householdId');

    // 3. Delete all shopping history items for the household
    final shoppingHistoryQuery = await _db
        .collection('shoppingHistory')
        .where('householdId', isEqualTo: householdId)
        .get();
    for (final doc in shoppingHistoryQuery.docs) {
      await doc.reference.delete();
    }
    debugPrint('DEBUG: Deleted ${shoppingHistoryQuery.docs.length} shopping history items for household: $householdId');

    // 4. Remove the householdId from all member users' householdIds array
    final usersQuery = await _db
        .collection('users')
        .where('householdIds', arrayContains: householdId)
        .get();
    for (final userDoc in usersQuery.docs) {
      await userDoc.reference.update({
        'householdIds': FieldValue.arrayRemove([householdId]),
      });
      // If the deleted household was the user's personal household, clear personalHouseholdId
      if (userDoc.data().containsKey('personalHouseholdId') &&
          userDoc.data()['personalHouseholdId'] == householdId) {
        await userDoc.reference.update({
          'personalHouseholdId': FieldValue.delete(),
        });
      }
    }
    debugPrint('DEBUG: Removed householdId $householdId from member users.');

    // 5. Finally, delete the household document itself
    await _db.collection('households').doc(householdId).delete();
    debugPrint('DEBUG: Deleted household document: $householdId');

    // If the deleted household was the currently selected one, reset selectedHouseholdId
    if (_selectedHouseholdId == householdId) {
      _selectedHouseholdId = null; // Clear the selected household
      debugPrint('DEBUG: Cleared selectedHouseholdId as the deleted household was active.');
      // Attempt to set an initial household (e.g., personal household)
      if (userId != null) {
        await setInitialHousehold(userId!);
      }
    }
    notifyListeners(); // Notify listeners after deletion
  }

  // Set a specific shopping list as active and deactivate all others for the household
  Future<void> setActiveShoppingList(String listId, String householdId) async {
    debugPrint('DEBUG: setActiveShoppingList called for listId: $listId, householdId: $householdId');
    // Deactivate all other lists for this household
    final querySnapshot = await _db
        .collection('shoppingLists')
        .where('householdId', isEqualTo: householdId)
        .where('isActive', isEqualTo: true)
        .get();

    for (final doc in querySnapshot.docs) {
      await _db
          .collection('shoppingLists')
          .doc(doc.id)
          .update({'isActive': false});
      debugPrint('DEBUG: Deactivated shopping list: ${doc.id}');
    }

    // Activate the selected list
    await _db
        .collection('shoppingLists')
        .doc(listId)
        .update({'isActive': true});
    debugPrint('DEBUG: Activated shopping list: $listId');
  }

  // Get the currently active shopping list for a household
  Stream<ShoppingListModel?> streamActiveShoppingList(String householdId) {
    debugPrint('DEBUG: streamActiveShoppingList called for householdId: $householdId');
    return _db
        .collection('shoppingLists')
        .where('householdId', isEqualTo: householdId)
        .where('isActive', isEqualTo: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isNotEmpty) {
            final activeList = ShoppingListModel.fromFirestore(snapshot.docs.first);
            debugPrint('DEBUG: streamActiveShoppingList stream update for householdId: $householdId, activeList: ${activeList.name}');
            return activeList;
          }
          debugPrint('DEBUG: streamActiveShoppingList stream update for householdId: $householdId, no active list found.');
          return null;
        });
  }

  // Get the active shopping list ID for a household
  Future<String?> getActiveShoppingListId(String householdId) async {
    debugPrint('DEBUG: getActiveShoppingListId called for householdId: $householdId');
    final householdDoc = await _db.collection('households').doc(householdId).get();
    if (householdDoc.exists && householdDoc.data() != null) {
      final activeListId = householdDoc.data()!['activeShoppingListId'] as String?;
      debugPrint('DEBUG: getActiveShoppingListId for householdId: $householdId, activeListId: $activeListId');
      return activeListId;
    }
    debugPrint('DEBUG: getActiveShoppingListId for householdId: $householdId, no household doc or data found.');
    return null;
  }

  // Stream for suggestions (adapting from ShoppingListService)
  Stream<List<ShoppingListItemModel>> streamSuggestions(String householdId) {
    debugPrint('DEBUG: streamSuggestions called for householdId: $householdId');
    // This stream will combine data from pantryItems and shoppingHistory
    // and then process it to generate suggestions.
    // This is a more complex stream as it depends on multiple collections.
    // For simplicity, we'll re-fetch on changes to either collection.
    // A more advanced solution might use RxDart to combine streams.

    final pantryStream = _db.collection('pantryItems')
        .where('householdId', isEqualTo: householdId)
        .snapshots();

    final historyStream = _db.collection('shoppingHistory')
        .where('householdId', isEqualTo: householdId)
        .snapshots();

    return pantryStream.asyncMap((pantrySnapshot) async {
      final historySnapshot = await historyStream.first; // Get current history state

      List<PantryItemModel> pantryItems = pantrySnapshot.docs.map((doc) => PantryItemModel.fromFirestore(doc)).toList();
      List<ShoppingHistoryItemModel> historyItems = historySnapshot.docs.map((doc) => ShoppingHistoryItemModel.fromFirestore(doc)).toList();

      debugPrint('DEBUG: streamSuggestions processing for householdId: $householdId');
      debugPrint('DEBUG: Pantry items count: ${pantryItems.length}');
      debugPrint('DEBUG: History items count: ${historyItems.length}');

      List<ShoppingListItemModel> suggestions = [];
      final OpenFoodFactsService openFoodFactsService = OpenFoodFactsService(); // Instantiate here

      // Get the active shopping list items to filter out already added suggestions
      List<ShoppingListItemModel> activeListItems = [];
      final activeListDoc = await _db.collection('shoppingLists')
          .where('householdId', isEqualTo: householdId)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();
      if (activeListDoc.docs.isNotEmpty) {
        activeListItems = ShoppingListModel.fromFirestore(activeListDoc.docs.first).items;
      }
      final Set<String> activeListItemNames = activeListItems.map((item) => item.name.toLowerCase()).toSet();
      debugPrint('DEBUG: Active shopping list items count (for filtering suggestions): ${activeListItems.length}');


      // Collect all unique item names for Nutri/Eco scores
      final Set<String> allItemNames = {};
      for (var item in pantryItems) {
        allItemNames.add(item.name);
      }
      for (var item in historyItems) {
        allItemNames.add(item.productName);
      }

      // Collect all unique barcodes for product prices from pantry items
      final Set<String> allBarcodes = {};
      for (var item in pantryItems) {
        if (item.barcode != null && item.barcode!.isNotEmpty) {
          allBarcodes.add(item.barcode!);
        }
      }

      // Fetch all Nutri/Eco scores in parallel
      final Map<String, Map<String, String?>?> allScores = {};
      final List<Future<void>> scoreFutures = allItemNames.map((name) async {
        allScores[name] = await openFoodFactsService.getNutriAndEcoScore(name);
      }).toList();
      await Future.wait(scoreFutures);

      // Fetch all product prices in parallel (batching if many items)
      final Map<String, double> productPrices = {};
      final List<Future<void>> priceFutures = [];

      // For barcodes
      if (allBarcodes.isNotEmpty) {
        // Split into chunks of 10 for whereIn clause
        for (int i = 0; i < allBarcodes.length; i += 10) {
          final chunk = allBarcodes.skip(i).take(10).toList();
          priceFutures.add(_db.collection('local_products_ph').where('barcode', whereIn: chunk).get().then((result) {
            for (final doc in result.docs) {
              final data = doc.data();
              if (data.containsKey('barcode') && data.containsKey('price')) {
                productPrices[data['barcode'] as String] = (data['price'] as num?)?.toDouble() ?? 0.0;
              }
            }
          }));
        }
      }

      // For history product names (if no barcode, or if we need to search by name)
      final Set<String> historyProductNames = historyItems.map((e) => e.productName).toSet();
      if (historyProductNames.isNotEmpty) {
        for (int i = 0; i < historyProductNames.length; i += 10) {
          final chunk = historyProductNames.skip(i).take(10).toList();
          priceFutures.add(_db.collection('local_products_ph').where('productName', whereIn: chunk).get().then((result) {
            for (final doc in result.docs) {
              final data = doc.data();
              if (data.containsKey('productName') && data.containsKey('price')) {
                productPrices[data['productName'] as String] = (data['price'] as num?)?.toDouble() ?? 0.0;
              }
            }
          }));
        }
      }
      await Future.wait(priceFutures);


      // 1. Out of Stock, Expired, Low Stock from pantry
      for (var item in pantryItems) {
        String? status;
        if (item.qty > 0 && item.qty <= 2) { // Example threshold for "low stock"
          status = 'Low on stock';
        } else if (item.qty <= 0 || item.status == 'Consumed' || (item.expirationDate != null && item.expirationDate!.isBefore(DateTime.now()))) {
          status = 'Out of stock';
        }

        if (status != null && !activeListItemNames.contains(item.name.toLowerCase())) {
          final scores = allScores[item.name];
          double productPrice = 0.0;
          if (item.barcode != null && item.barcode!.isNotEmpty) {
            productPrice = productPrices[item.barcode!] ?? 0.0;
          }

          suggestions.add(ShoppingListItemModel(
            id: _uuid.v4(), // Assign unique ID
            name: item.name,
            netWeight: item.netWeight,
            category: item.category,
            unitPrice: productPrice, // Use fetched price
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
        if (!inPantry && !activeListItemNames.contains(item.productName.toLowerCase())) {
          final scores = allScores[item.productName];
          double productPrice = productPrices[item.productName] ?? 0.0; // Try to get price by name

          suggestions.add(ShoppingListItemModel(
            id: _uuid.v4(), // Assign unique ID
            name: item.productName,
            category: item.category,
            unitPrice: productPrice, // Use fetched price
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
      debugPrint('DEBUG: Generated ${uniqueSuggestions.values.length} unique suggestions for householdId: $householdId');

      // Limit the number of suggestions to 15 as requested
      return uniqueSuggestions.values.take(15).toList();
    });
  }

  // --- Notification Settings Methods ---

  // Save notification settings for a user
  Future<void> saveNotificationSettings(
      String userId, Map<String, dynamic> settings) async {
    debugPrint('DEBUG: saveNotificationSettings called for userId: $userId');
    await _db.collection('users').doc(userId).update({
      'notificationSettings': settings,
    });
  }

  // Get notification settings for a user
  Future<Map<String, dynamic>?> getNotificationSettings(String userId) async {
    debugPrint('DEBUG: getNotificationSettings called for userId: $userId');
    final doc = await _db.collection('users').doc(userId).get();
    if (doc.exists &&
        doc.data() != null &&
        doc.data()!.containsKey('notificationSettings')) {
      return Map<String, dynamic>.from(doc.data()!['notificationSettings']);
    }
    return null; // Or return default settings if preferred
  }

  // Get a stream of notification settings for a user
  Stream<Map<String, dynamic>?> getNotificationSettingsStream(String userId) {
    debugPrint('DEBUG: getNotificationSettingsStream called for userId: $userId');
    return _db.collection('users').doc(userId).snapshots().map((userDoc) {
      if (userDoc.exists &&
          userDoc.data() != null &&
          userDoc.data()!.containsKey('notificationSettings')) {
        return Map<String, dynamic>.from(
            userDoc.data()!['notificationSettings']);
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
    debugPrint('DEBUG: addShoppingHistoryItem called for householdId: $selectedHouseholdId, item: ${item.productName}');
    await _db.collection('shoppingHistory').add(item.toFirestore());
  }

  // Get a stream of shopping history items for a specific household
  Stream<List<ShoppingHistoryItemModel>> getShoppingHistoryForHousehold(
      String householdId) {
    debugPrint('DEBUG: getShoppingHistoryForHousehold called for householdId: $householdId');
    if (_auth.currentUser?.isAnonymous ?? false) {
      return Stream.fromFuture(loadGuestShoppingHistoryItems());
    }
    return _db
        .collection('shoppingHistory')
        .where('householdId', isEqualTo: householdId)
        .orderBy('purchaseDate', descending: true)
        .snapshots()
        .map((snapshot) {
          debugPrint('DEBUG: getShoppingHistoryForHousehold stream update for householdId: $householdId, items: ${snapshot.docs.length}');
          return snapshot.docs
            .map((doc) => ShoppingHistoryItemModel.fromFirestore(doc))
            .toList();
        });
  }

  // Mark a pantry item as deleted for the currently selected household
  Future<void> deletePantryItem(String itemId) async {
    if (selectedHouseholdId == null) {
      throw Exception("No household selected.");
    }
    debugPrint('DEBUG: deletePantryItem called for householdId: $selectedHouseholdId, itemId: $itemId');

    if (_auth.currentUser?.isAnonymous ?? false) {
      // For guest users, delete from local storage
      List<PantryItemModel> currentGuestPantry = await loadGuestPantryItems();
      currentGuestPantry.removeWhere((element) => element.id == itemId);
      await saveGuestPantryItems(currentGuestPantry);
    } else {
      // Get the item details before deleting/updating
      final itemDoc = await _pantryCol(selectedHouseholdId!).doc(itemId).get();
      if (!itemDoc.exists) {
        return; // Item doesn't exist
      }
      final item = PantryItemModel.fromFirestore(itemDoc);

      // If the item is already marked as 'wasted' (e.g., by background expiry check),
      // record it as 'Expired Waste' and then delete it.
      if (item.status == 'wasted') {
        await recordWastedItem(item, item.qty, actionType: 'Expired Waste');
        await _pantryCol(selectedHouseholdId!).doc(itemId).delete();
        debugPrint('DEBUG: Deleted expired pantry item $itemId from pantry and recorded as Expired Waste.');
        return;
      }

      // Determine productId from local_products_ph if barcode is available
      String? productId;
      if (item.barcode != null && item.barcode!.isNotEmpty) {
        final productQuery = await _db
            .collection('local_products_ph')
            .where('barcode', isEqualTo: item.barcode)
            .limit(1)
            .get();
        if (productQuery.docs.isNotEmpty) {
          productId = productQuery.docs.first.id;
        }
      }

      // Update the status to 'Deleted'
      await _pantryCol(selectedHouseholdId!).doc(itemId).update({
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
        priceAtAction: item.price, // Save the price at the time of deletion
      );
      await _db.collection('shoppingHistory').add(historyItem.toFirestore());
    }
  }

  // Record consumed items
  Future<void> recordConsumedItem(PantryItemModel item, int consumedQty) async {
    if (selectedHouseholdId == null) {
      throw Exception("No household selected.");
    }
    debugPrint('DEBUG: recordConsumedItem called for householdId: $selectedHouseholdId, item: ${item.name}, qty: $consumedQty');

    if (consumedQty <= 0) {
      return; // Nothing to consume
    }

    // Determine productId from local_products_ph if barcode is available
    String? productId;
    if (item.barcode != null && item.barcode!.isNotEmpty) {
      final productQuery = await _db
          .collection('local_products_ph')
          .where('barcode', isEqualTo: item.barcode)
          .limit(1)
          .get();
      if (productQuery.docs.isNotEmpty) {
        productId = productQuery.docs.first.id;
      }
    }

    // Create a history item regardless of guest or registered user
    final historyItem = ShoppingHistoryItemModel(
      id: _uuid.v4(), // Assign a unique ID for local storage
      householdId: selectedHouseholdId!,
      productId: productId,
      productName: item.name,
      category: item.category,
      quantity: consumedQty,
      purchaseDate: DateTime.now(),
      actionType: 'Consumed',
      priceAtAction: item.price,
    );

    if (_auth.currentUser?.isAnonymous ?? false) {
      // For guest users, update in local storage and add to local history
      List<PantryItemModel> currentGuestPantry = await loadGuestPantryItems();
      int itemIndex =
          currentGuestPantry.indexWhere((element) => element.id == item.id);
      if (itemIndex != -1) {
        PantryItemModel existingItem = currentGuestPantry[itemIndex];
        if (existingItem.qty > consumedQty) {
          currentGuestPantry[itemIndex] =
              existingItem.copyWith(qty: existingItem.qty - consumedQty);
        } else {
          currentGuestPantry.removeAt(itemIndex);
        }
        await saveGuestPantryItems(currentGuestPantry);
      }
      // Add to guest shopping history
      List<ShoppingHistoryItemModel> currentGuestHistory = await loadGuestShoppingHistoryItems();
      currentGuestHistory.add(historyItem);
      await saveGuestShoppingHistoryItems(currentGuestHistory);
    } else {
      // For registered users, update in Firestore and add to Firestore history
      if (item.qty > consumedQty) {
        await _pantryCol(selectedHouseholdId!).doc(item.id).update({
          'qty': item.qty - consumedQty,
        });
      } else {
        await _pantryCol(selectedHouseholdId!).doc(item.id).delete();
        debugPrint('DEBUG: Deleted pantry item ${item.id} as quantity reached 0 after consumption.');
      }
      await _db.collection('shoppingHistory').add(historyItem.toFirestore());
    }
  }

  // Record wasted items
  Future<void> recordWastedItem(PantryItemModel item, int wastedQty, {String actionType = 'Wasted'}) async {
    if (selectedHouseholdId == null) {
      throw Exception("No household selected.");
    }
    debugPrint('DEBUG: recordWastedItem called for householdId: $selectedHouseholdId, item: ${item.name}, qty: $wastedQty, actionType: $actionType');

    if (wastedQty <= 0) {
      return; // Nothing to waste
    }

    if (_auth.currentUser?.isAnonymous ?? false) {
      // For guest users, update in local storage
      List<PantryItemModel> currentGuestPantry = await loadGuestPantryItems();
      int itemIndex =
          currentGuestPantry.indexWhere((element) => element.id == item.id);
      if (itemIndex != -1) {
        PantryItemModel existingItem = currentGuestPantry[itemIndex];
        if (existingItem.qty > wastedQty) {
          currentGuestPantry[itemIndex] =
              existingItem.copyWith(qty: existingItem.qty - wastedQty);
        } else {
          currentGuestPantry.removeAt(itemIndex);
        }
        await saveGuestPantryItems(currentGuestPantry);
      }
    } else {
      // First, update the original item's quantity in the pantry
      if (item.qty > wastedQty) {
        await _pantryCol(selectedHouseholdId!).doc(item.id).update({
          'qty': item.qty - wastedQty,
          // Status remains 'Available' or whatever it was if partially wasted
        });
      } else {
        // If all available quantity is wasted, update status and wastedAt
        await _pantryCol(selectedHouseholdId!).doc(item.id).update({
          'qty': 0, // Set quantity to 0
          'status': 'wasted',
          'wastedAt': Timestamp.fromDate(DateTime.now()),
        });
      }

      // Determine productId from local_products_ph if barcode is available
      String? productId;
      if (item.barcode != null && item.barcode!.isNotEmpty) {
        final productQuery = await _db
            .collection('local_products_ph')
            .where('barcode', isEqualTo: item.barcode)
            .limit(1)
            .get();
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
        quantity: wastedQty,
        purchaseDate: DateTime.now(), // Represents wastage date
        actionType: actionType, // Set action type to 'Wasted' or 'Expired Waste'
        priceAtAction: item.price, // Save the price at the time of wastage
      );
      await _db.collection('shoppingHistory').add(historyItem.toFirestore());
    }
  }

  // Clean up old shopping history items (e.g., older than 30 days)
  Future<void> cleanUpShoppingHistoryItems(String householdId) async {
    debugPrint('DEBUG: cleanUpShoppingHistoryItems called for householdId: $householdId');
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));

    final historyQuery = await _db
        .collection('shoppingHistory')
        .where('householdId', isEqualTo: householdId)
        .where('purchaseDate', isLessThan: thirtyDaysAgo)
        .get();

    for (final doc in historyQuery.docs) {
      await doc.reference.delete();
    }
    debugPrint('DEBUG: Cleaned up ${historyQuery.docs.length} old shopping history items for household: $householdId');
  }

  // Get a stream of households for the current user
  Stream<List<Household>> getHouseholds() {
    if (userId == null) {
      debugPrint('DEBUG: getHouseholds called but userId is null.');
      return Stream.value([]);
    }
    debugPrint('DEBUG: getHouseholds called for userId: $userId');
    return _db
        .collection('users')
        .doc(userId)
        .snapshots()
        .asyncMap((userDoc) async {
      if (!userDoc.exists || userDoc.data()?['householdIds'] == null) {
        debugPrint('DEBUG: User doc does not exist or no householdIds for userId: $userId');
        return [];
      }
      List<String> householdIds =
          List<String>.from(userDoc.data()!['householdIds']);
      if (householdIds.isEmpty) {
        debugPrint('DEBUG: No householdIds found for userId: $userId');
        return [];
      }
      debugPrint('DEBUG: Fetching households for IDs: $householdIds');
      final querySnapshot = await _db
          .collection('households')
          .where(FieldPath.documentId, whereIn: householdIds)
          .get();
      debugPrint('DEBUG: Found ${querySnapshot.docs.length} households for userId: $userId');
      return querySnapshot.docs
          .map((doc) => Household.fromFirestore(doc))
          .toList();
    });
  }

  // Create a new household
  Future<void> createHousehold(String name) async {
    if (userId == null) {
      throw Exception("User not logged in.");
    }
    debugPrint('DEBUG: createHousehold called for userId: $userId, name: $name');
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

    await _db
        .collection('households')
        .doc(householdId)
        .set(newHousehold.toFirestore());
    debugPrint('DEBUG: Created new household: $householdId with name: $name');

    // Add householdId to the user's householdIds array
    await _db.collection('users').doc(userId).update({
      'householdIds': FieldValue.arrayUnion([householdId]),
    });
    debugPrint('DEBUG: Added householdId $householdId to user $userId householdIds.');
    // Set a default nickname if not already set
    final userDoc = await _db.collection('users').doc(userId).get();
    if (userDoc.data()?['nickname'] == null) {
      await _db.collection('users').doc(userId).update({
        'nickname': _auth.currentUser?.email?.split('@').first ?? 'User',
      });
    }
  }

  

  Future<void> consumePantryForRecipe({
  required String householdId,
  required List<Map<String, dynamic>> ingredients,
}) async {
  debugPrint('DEBUG: consumePantryForRecipe called for householdId: $householdId, ingredients count: ${ingredients.length}');
  final db = FirebaseFirestore.instance;

  // Load pantry items
  final pantrySnap = await db
      .collection('households')
      .doc(householdId)
      .collection('pantryItems')
      .get();

  // Index by normalized name
  final byName = <String, QueryDocumentSnapshot<Map<String, dynamic>>>{};
  for (final d in pantrySnap.docs) {
    final data = d.data();
    final name = normalizeName((data['name'] ?? '').toString());
    byName[name] = d;
  }

  final batch = db.batch();

  for (final ing in ingredients) {
    final raw = (ing['name'] ?? '').toString();
    if (raw.isEmpty) continue;

    final norm = normalizeName(raw);
    final doc = byName[norm];
    if (doc == null) continue; // no pantry match

    final data = doc.data();
    final currentQty = ((data['qty'] ?? data['quantity']) is num)
        ? ((data['qty'] ?? data['quantity']) as num).toDouble()
        : 1.0;
    final currentUnit = (data['unit'] ?? '').toString();

    // Parse amount like "2", "200 g", "1 cup"
    final amount = (ing['amount'] ?? '').toString().trim();
    double reqQty = 1.0; // default decrement by 1
    String reqUnit = currentUnit;

    if (amount.isNotEmpty) {
      final parts = amount.split(RegExp(r'\s+'));
      final maybeNum = double.tryParse(parts.first.replaceAll(',', '.'));
      if (maybeNum != null) reqQty = maybeNum;
      if (parts.length > 1) reqUnit = parts[1];
    }

    // Skip if units obviously mismatch
    if (currentUnit.isNotEmpty && reqUnit.isNotEmpty && currentUnit != reqUnit) {
      debugPrint('DEBUG: Skipping ingredient $raw due to unit mismatch: $currentUnit vs $reqUnit');
      continue;
    }

    final newQty = (currentQty - reqQty).clamp(0, double.infinity);

    if (newQty == 0) {
      batch.delete(doc.reference);
      debugPrint('DEBUG: Deleting pantry item ${doc.id} ($raw) as quantity reached 0.');
    } else {
      batch.update(doc.reference, {
        'qty': newQty,
        'unit': currentUnit.isNotEmpty ? currentUnit : reqUnit,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('DEBUG: Updating pantry item ${doc.id} ($raw) to quantity: $newQty');
    }
  }

  await batch.commit();
  debugPrint('DEBUG: Batch commit for consumePantryForRecipe completed.');
}

  // Join an existing household
  Future<void> joinHousehold(String joinCode) async {
    if (userId == null) {
      throw Exception("User not logged in.");
    }
    debugPrint('DEBUG: joinHousehold called for userId: $userId, joinCode: $joinCode');

    final querySnapshot = await _db
        .collection('households')
        .where('joinCode', isEqualTo: joinCode)
        .limit(1)
        .get();

    if (querySnapshot.docs.isEmpty) {
      debugPrint('DEBUG: Invalid join code: $joinCode');
      throw Exception("Invalid join code.");
    }

    final householdDoc = querySnapshot.docs.first;
    final Household household = Household.fromFirestore(householdDoc);

    if (household.members.contains(userId)) {
      debugPrint('DEBUG: User $userId already a member of household ${household.id}');
      throw Exception("You are already a member of this household.");
    }

    // Add user to household members
    await _db.collection('households').doc(household.id).update({
      'members': FieldValue.arrayUnion([userId!]),
    });
    debugPrint('DEBUG: User $userId added to household ${household.id} members.');

    // Add householdId to the user's householdIds array
    await _db.collection('users').doc(userId).update({
      'householdIds': FieldValue.arrayUnion([household.id]),
    });
    debugPrint('DEBUG: HouseholdId ${household.id} added to user $userId householdIds.');
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
    debugPrint('DEBUG: getUser called for userId: $userId');
    final doc = await _db.collection('users').doc(userId).get();
    if (doc.exists) {
      return UserModel.fromFirestore(doc);
    }
    debugPrint('DEBUG: User $userId not found.');
    return null;
  }

  // Update a user's nickname
  Future<void> updateUserNickname(String userId, String nickname) async {
    debugPrint('DEBUG: updateUserNickname called for userId: $userId, nickname: $nickname');
    await _db.collection('users').doc(userId).update({
      'nickname': nickname,
    });
  }

  // Update a household's name
  Future<void> updateHouseholdName(String householdId, String newName) async {
    debugPrint('DEBUG: updateHouseholdName called for householdId: $householdId, newName: $newName');
    await _db.collection('households').doc(householdId).update({
      'name': newName,
    });
    notifyListeners(); // Notify listeners of the change
  }

  // Update a user's FCM token
  Future<void> updateUserFCMToken(String userId, String token) async {
    debugPrint('DEBUG: updateUserFCMToken called for userId: $userId, token: $token');
    await _db.collection('users').doc(userId).set(
        {
          'fcmToken': token,
        },
        SetOptions(
            merge: true)); // Use merge to avoid overwriting other user data
  }

  // Leave a household
  Future<void> leaveHousehold(String householdId, String userId) async {
    debugPrint('DEBUG: leaveHousehold called for householdId: $householdId, userId: $userId');
    // Remove user from the household's members array
    await _db.collection('households').doc(householdId).update({
      'members': FieldValue.arrayRemove([userId]),
    });
    debugPrint('DEBUG: User $userId removed from household $householdId members.');

    // Remove householdId from the user's householdIds array
    await _db.collection('users').doc(userId).update({
      'householdIds': FieldValue.arrayRemove([householdId]),
    });
    debugPrint('DEBUG: HouseholdId $householdId removed from user $userId householdIds.');
    notifyListeners(); // Notify listeners after leaving a household
  }

  // Delete all shopping history items for a specific household
  Future<void> deleteAllShoppingHistoryItems(String householdId) async {
    debugPrint('DEBUG: deleteAllShoppingHistoryItems called for householdId: $householdId');
    final historyQuery = await _db
        .collection('shoppingHistory')
        .where('householdId', isEqualTo: householdId)
        .get();

    for (final doc in historyQuery.docs) {
      await doc.reference.delete();
    }
    debugPrint('DEBUG: Deleted ${historyQuery.docs.length} shopping history items for household: $householdId');
  }

  Future<void> markAsWasted(PantryItemModel item) async {
    if (selectedHouseholdId == null || item.id == null) {
      throw Exception("No household selected or item ID is missing.");
    }
    debugPrint('DEBUG: markAsWasted called for householdId: $selectedHouseholdId, item: ${item.name}');
    final updated = item.copyWith(
      status: 'wasted',
      wastedAt: DateTime.now(),
    );
    await _pantryCol(selectedHouseholdId!)
        .doc(item.id)
        .update(updated.toFirestore());
  }

  // Search for products in the local_products_ph collection
  Stream<List<Product>> searchProducts(String query) {
    debugPrint('DEBUG: searchProducts called for query: $query');
    if (query.isEmpty) {
      return Stream.value([]);
    }
    return _db
        .collection('local_products_ph')
        .where('productName', isGreaterThanOrEqualTo: query)
        .where('productName', isLessThanOrEqualTo: '$query\uf8ff')
        .limit(10) // Limit to 10 suggestions
        .snapshots()
        .map((snapshot) {
          debugPrint('DEBUG: searchProducts stream update for query: $query, products: ${snapshot.docs.length}');
          return snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList();
        });
  }

  CollectionReference<Map<String, dynamic>> _pantryCol(String householdId) {
    return _db.collection('pantryItems');
  }

  // Get product price from local_products_ph collection
  Future<double?> getProductPrice(String productId) async {
    debugPrint('DEBUG: getProductPrice called for productId: $productId');
    try {
      final doc = await _db.collection('local_products_ph').doc(productId).get();
      if (doc.exists) {
        final data = doc.data();
        if (data != null && data.containsKey('price')) {
          return (data['price'] as num?)?.toDouble();
        }
      }
      debugPrint('DEBUG: Product $productId not found or price missing.');
      return null;
    } catch (e) {
      debugPrint('Error getting product price for $productId: $e');
      return null;
    }
  }

  // Get weekly waste and consumption summary for a household
  Future<Map<String, dynamic>> getWeeklyWasteAndConsumptionSummary(String householdId) async {
    debugPrint('DEBUG: getWeeklyWasteAndConsumptionSummary called for householdId: $householdId');
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));

    final querySnapshot = await _db
        .collection('shoppingHistory')
        .where('householdId', isEqualTo: householdId)
        .where('purchaseDate', isGreaterThanOrEqualTo: sevenDaysAgo)
        .get();

    int totalConsumedQuantity = 0;
    int totalWastedQuantity = 0;
    int expiredWastedQuantity = 0;

    for (final doc in querySnapshot.docs) {
      final historyItem = ShoppingHistoryItemModel.fromFirestore(doc);
      if (historyItem.actionType == 'Consumed') {
        totalConsumedQuantity += historyItem.quantity;
      } else if (historyItem.actionType == 'Wasted') {
        totalWastedQuantity += historyItem.quantity;
      } else if (historyItem.actionType == 'Expired Waste') {
        totalWastedQuantity += historyItem.quantity;
        expiredWastedQuantity += historyItem.quantity;
      }
    }

    final totalOutflowQuantity = totalConsumedQuantity + totalWastedQuantity;

    return {
      'totalConsumedQuantity': totalConsumedQuantity,
      'totalWastedQuantity': totalWastedQuantity,
      'expiredWastedQuantity': expiredWastedQuantity,
      'totalOutflowQuantity': totalOutflowQuantity,
    };
  }

  // Get frequently consumed items for a household
  Future<List<Map<String, dynamic>>> getFrequentlyConsumedItems(
      String householdId,
      {int limit = 5,
      int days = 30}) async {
    debugPrint('DEBUG: getFrequentlyConsumedItems called for householdId: $householdId');
    final thirtyDaysAgo = DateTime.now().subtract(Duration(days: days));

    final querySnapshot = await _db
        .collection('shoppingHistory')
        .where('householdId', isEqualTo: householdId)
        .where('actionType', isEqualTo: 'Consumed')
        .where('purchaseDate', isGreaterThanOrEqualTo: thirtyDaysAgo)
        .get();

    final Map<String, int> consumptionCounts = {};
    final Map<String, PantryItemModel> latestPantryItems =
        {}; // To get current pantry item details

    for (final doc in querySnapshot.docs) {
      final historyItem = ShoppingHistoryItemModel.fromFirestore(doc);
      final productName = historyItem.productName;
      consumptionCounts[productName] =
          (consumptionCounts[productName] ?? 0) + historyItem.quantity;

      // Try to get the latest pantry item for this product name
      // This is a simplified approach; a more robust solution might involve tracking item IDs in history
      final pantryItemQuery = await _db
          .collection('pantryItems')
          .where('householdId', isEqualTo: householdId)
          .where('name', isEqualTo: productName)
          .orderBy('timestamp',
              descending:
                  true) // Assuming 'timestamp' is when it was added/updated
          .limit(1)
          .get();

      if (pantryItemQuery.docs.isNotEmpty) {
        latestPantryItems[productName] =
            PantryItemModel.fromFirestore(pantryItemQuery.docs.first);
      }
    }

    final List<Map<String, dynamic>> sortedItems = consumptionCounts.entries
        .map((entry) => {
              'productName': entry.key,
              'totalConsumed': entry.value,
              'pantryItem': latestPantryItems[entry.key]
                  ?.toFirestore(), // Include pantry item details if found
            })
        .toList();

    sortedItems
        .sort((a, b) => b['totalConsumed'].compareTo(a['totalConsumed']));
    debugPrint('DEBUG: Generated ${sortedItems.length} frequently consumed items for householdId: $householdId');

    return sortedItems.take(limit).toList();
  }

  // --- Batch Consumption Method ---
  Future<void> batchConsumePantryItems(
      String householdId, Map<String, int> itemsToConsume) async {
    debugPrint('DEBUG: batchConsumePantryItems called for householdId: $householdId, items to consume count: ${itemsToConsume.length}');
    final batch = _db.batch();

    for (final entry in itemsToConsume.entries) {
      final itemId = entry.key;
      final consumedQty = entry.value;

      final itemRef = _db.collection('pantryItems').doc(itemId);
      final itemDoc = await itemRef.get();

      if (itemDoc.exists) {
        final item = PantryItemModel.fromFirestore(itemDoc);
        if (item.qty > consumedQty) {
          batch.update(itemRef, {'qty': item.qty - consumedQty});
          debugPrint('DEBUG: Batch update pantry item $itemId, new qty: ${item.qty - consumedQty}');
        } else {
          batch.delete(itemRef);
          debugPrint('DEBUG: Batch delete pantry item $itemId as quantity reached 0.');
        }

        // Determine productId from local_products_ph if barcode is available
        String? productId;
        if (item.barcode != null && item.barcode!.isNotEmpty) {
          final productQuery = await _db
              .collection('local_products_ph')
              .where('barcode', isEqualTo: item.barcode)
              .limit(1)
              .get();
          if (productQuery.docs.isNotEmpty) {
            productId = productQuery.docs.first.id;
          }
        }

        // Add a record to the shopping history
        final historyItem = ShoppingHistoryItemModel(
          householdId: householdId,
          productId: productId,
          productName: item.name,
          category: item.category,
          quantity: consumedQty,
          purchaseDate: DateTime.now(),
          actionType: 'Consumed',
        );
        batch.set(
            _db.collection('shoppingHistory').doc(), historyItem.toFirestore());
        debugPrint('DEBUG: Added history item for consumed product: ${item.name}');
      }
    }
    await batch.commit();
    debugPrint('DEBUG: Batch commit for batchConsumePantryItems completed.');
  }

  // --- App Notification Methods ---

  // Add or update an app notification to prevent duplicates
  Future<void> addAppNotification(AppNotificationModel notification) async {
    debugPrint('DEBUG: addAppNotification called for userId: ${notification.userId}, type: ${notification.type}');
    QuerySnapshot querySnapshot;

    if (notification.type == 'pantry_summary') {
      // For pantry_summary, ensure only one exists per household
      querySnapshot = await _db
          .collection('appNotifications')
          .where('userId', isEqualTo: notification.userId) // Filter by userId
          .where('type', isEqualTo: 'pantry_summary')
          .where('householdId',
              isEqualTo: notification
                  .householdId) // Use householdId for summary notifications
          .limit(1)
          .get();
    } else {
      // For other types, use existing de-duplication logic
      querySnapshot = await _db
          .collection('appNotifications')
          .where('userId', isEqualTo: notification.userId) // Filter by userId
          .where('type', isEqualTo: notification.type)
          .where('payload', isEqualTo: notification.payload)
          .limit(1)
          .get();
    }

    if (querySnapshot.docs.isNotEmpty) {
      // Update existing notification
      final existingNotificationDoc = querySnapshot.docs.first;
      await existingNotificationDoc.reference.update({
        'createdAt': Timestamp.now(), // Refresh timestamp
        'isRead': false, // Mark as unread
        'title': notification.title, // Update title
        'body': notification.body, // Update body
        'payload': notification.payload, // Update payload
      });
      debugPrint('DEBUG: Updated existing notification: ${existingNotificationDoc.id}');
    } else {
      // Add new notification
      await _db.collection('appNotifications').add(notification.toFirestore());
      debugPrint('DEBUG: Added new notification: ${notification.title}');
    }
  }

  // Get a stream of app notifications for a user
  Stream<List<AppNotificationModel>> getAppNotificationsStream(String userId) {
    debugPrint('DEBUG: getAppNotificationsStream called for userId: $userId');
    return _db
        .collection('appNotifications')
        .where('userId', isEqualTo: userId) // Filter by userId
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          debugPrint('DEBUG: getAppNotificationsStream stream update for userId: $userId, notifications: ${snapshot.docs.length}');
          return snapshot.docs
            .map((doc) => AppNotificationModel.fromFirestore(doc))
            .toList();
        });
  }

  // Mark a specific notification as read
  Future<void> markNotificationAsRead(
      String userId, String notificationId) async {
    debugPrint('DEBUG: markNotificationAsRead called for userId: $userId, notificationId: $notificationId');
    await _db.collection('appNotifications').doc(notificationId).update({
      'isRead': true,
    });
  }

  // Get a stream of the count of unread notifications for a user
  Stream<int> getUnreadNotificationsCountStream(String userId) {
    debugPrint('DEBUG: getUnreadNotificationsCountStream called for userId: $userId');
    return _db
        .collection('appNotifications')
        .where('userId', isEqualTo: userId) // Filter by userId
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) {
          debugPrint('DEBUG: getUnreadNotificationsCountStream stream update for userId: $userId, unread count: ${snapshot.docs.length}');
          return snapshot.docs.length;
        });
  }

  // --- Feedback Methods ---

  // Upload a file to Firebase Storage and return its download URL
  Future<String?> uploadFile(File file, String path) async {
    debugPrint('DEBUG: uploadFile called for path: $path');
    try {
      final ref = _storage.ref().child(path);
      final uploadTask = ref.putFile(file);
      final snapshot = await uploadTask.whenComplete(() {});
      final downloadUrl = await snapshot.ref.getDownloadURL();
      debugPrint('DEBUG: File uploaded to: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading file: $e');
      return null;
    }
  }

  // Add feedback to Firestore
  Future<void> addFeedback({
    required String userId,
    required int rating,
    required String category,
    required String comments,
    String? fileUrl,
  }) async {
    debugPrint('DEBUG: addFeedback called for userId: $userId, category: $category');
    await _db.collection('feedback').add({
      'userId': userId,
      'rating': rating,
      'category': category,
      'comments': comments,
      'fileUrl': fileUrl,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Save a waste report (metadata and PDF) to Firebase
  Future<void> saveWasteReport(WasteReportModel report, Uint8List pdfBytes) async {
    if (userId == null) {
      throw Exception("User not logged in.");
    }
    debugPrint('DEBUG: saveWasteReport called for householdId: ${report.householdId}, week: ${report.weekStart.toIso8601String()}');

    // 1. Upload PDF to Firebase Storage
    final String storagePath = 'waste_reports/${report.userId}/${report.householdId}/report_${report.id}.pdf';
    final Reference ref = _storage.ref().child(storagePath);
    final UploadTask uploadTask = ref.putData(pdfBytes);
    await uploadTask.whenComplete(() {});
    debugPrint('DEBUG: PDF uploaded to Storage at path: $storagePath');

    // 2. Save report metadata to Firestore, storing the path instead of the URL
    final updatedReport = report.copyWith(pdfStoragePath: storagePath);
    await _db.collection('wasteReports').doc(report.id).set(updatedReport.toFirestore());
    debugPrint('DEBUG: Waste report metadata saved to Firestore: ${report.id}');
  }

  // Get a stream of waste reports for a household
  Stream<List<WasteReportModel>> getWasteReportsForHousehold(String householdId) {
    debugPrint("DEBUG: Querying wasteReports for householdId: $householdId");
    return _db
        .collection("wasteReports")
        .where("householdId", isEqualTo: householdId)
        .orderBy("generatedAt", descending: true)
        .snapshots()
        .map((snapshot) {
          debugPrint("DEBUG: getWasteReportsForHousehold found ${snapshot.docs.length} reports for householdId: $householdId");
          return snapshot.docs
            .map((doc) => WasteReportModel.fromFirestore(doc))
            .toList();
        });
  }

  // Get the download URL for a report PDF from its storage path
  Future<String?> getReportPdfUrl(String storagePath) async {
    try {
      // Get the download URL from the storage path
      final String downloadUrl = await _storage.ref(storagePath).getDownloadURL();
      return downloadUrl;
    } catch (e) {
      debugPrint("Error getting report PDF URL for path $storagePath: $e");
      return null;
    }
  }

  // --- Household Task Methods ---

  // Create a new household task
  Future<void> createHouseholdTask(HouseholdTask task) async {
    debugPrint('DEBUG: createHouseholdTask called for householdId: ${task.householdId}, assignedTo: ${task.assignedToUserId}');
    await _db.collection('householdTasks').add(task.toFirestore());
  }

  // Get a stream of household tasks assigned to a specific member
  Stream<List<HouseholdTask>> streamHouseholdTasksForMember(String householdId, String assignedToUserId) {
    debugPrint('DEBUG: streamHouseholdTasksForMember called for householdId: $householdId, assignedTo: $assignedToUserId');
    return _db
        .collection('householdTasks')
        .where('householdId', isEqualTo: householdId)
        .where('assignedToUserId', isEqualTo: assignedToUserId)
        .where('status', isEqualTo: 'pending') // Only show pending tasks
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          debugPrint('DEBUG: streamHouseholdTasksForMember stream update for householdId: $householdId, tasks: ${snapshot.docs.length}');
          return snapshot.docs
            .map((doc) => HouseholdTask.fromFirestore(doc))
            .toList();
        });
  }

  // Update the status of a household task
  Future<void> updateHouseholdTaskStatus(String taskId, String newStatus) async {
    debugPrint('DEBUG: updateHouseholdTaskStatus called for taskId: $taskId, newStatus: $newStatus');
    await _db.collection('householdTasks').doc(taskId).update({
      'status': newStatus,
      'completedAt': newStatus == 'done' ? FieldValue.serverTimestamp() : null,
    });
  }

  // Delete a household task
  Future<void> deleteHouseholdTask(String taskId) async {
    debugPrint('DEBUG: deleteHouseholdTask called for taskId: $taskId');
    await _db.collection('householdTasks').doc(taskId).delete();
  }

  // Update the lastLoginAt field for a user
  Future<void> updateLastLoginAt(String userId) async {
    debugPrint('DEBUG: updateLastLoginAt called for userId: $userId');
    await _db.collection('users').doc(userId).set(
        {
          'lastLoginAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true));
  }

  // Get household data by ID
  Future<Household?> getHousehold(String householdId) async {
    debugPrint('DEBUG: getHousehold called for householdId: $householdId');
    final doc = await _db.collection('households').doc(householdId).get();
    if (doc.exists) {
      return Household.fromFirestore(doc);
    }
    debugPrint('DEBUG: Household $householdId not found.');
    return null;
  }

  // Generate and add/update a pantry summary notification for a specific household
  Future<void> generatePantrySummaryNotification(String userId, String householdId, List<PantryItemModel> pantryItems) async {
    debugPrint('DEBUG: generatePantrySummaryNotification called for userId: $userId, householdId: $householdId with ${pantryItems.length} items');

    final prefs = await SharedPreferences.getInstance();
    final lastCheckString = prefs.getString(_lastPantrySummaryNotificationCheckKey + householdId);
    DateTime? lastCheck;
    if (lastCheckString != null) {
      lastCheck = DateTime.tryParse(lastCheckString);
    }

    // Only generate a new notification if the interval has passed or it's the first time
    if (lastCheck != null && DateTime.now().difference(lastCheck) < _notificationCheckInterval) {
      debugPrint('DEBUG: Skipping pantry summary notification for household $householdId. Last check was ${DateTime.now().difference(lastCheck).inMinutes} minutes ago.');
      return;
    }

    final now = DateTime.now();
    final int daysForAtRisk = 7; // Default to 7 days for at-risk

    final List<String> expiredItemNames = [];
    final List<String> atRiskItemNames = [];

    for (final item in pantryItems) {
      if (item.expirationDate != null) {
        final daysUntilExpiry = item.expirationDate!.difference(now).inDays;

        // An item is considered "expired" for the notification if its expiration date is in the past
        // AND its status is still 'Available' or 'wasted'.
        if (daysUntilExpiry < 0 && (item.status == 'Available' || item.status == 'wasted')) {
          expiredItemNames.add(item.name);
        }
        // An item is considered "at risk" if its expiration date is within the threshold
        // AND its status is still 'Available'.
        else if (daysUntilExpiry >= 0 && daysUntilExpiry <= daysForAtRisk && item.status == 'Available') {
          atRiskItemNames.add(item.name);
        }
      }
    }

    String title = 'Pantry Alert!';
    String body = '';
    if (expiredItemNames.isNotEmpty || atRiskItemNames.isNotEmpty) {
      if (expiredItemNames.isNotEmpty) {
        body += 'You have ${expiredItemNames.length} expired item(s): ${expiredItemNames.join(', ')}. ';
      }
      if (atRiskItemNames.isNotEmpty) {
        body += 'You have ${atRiskItemNames.length} item(s) at risk of expiring soon: ${atRiskItemNames.join(', ')}.';
      }
    } else {
      body = 'All items in your pantry are fresh!';
    }

    final household = await getHousehold(householdId);
    final householdName = household?.name ?? 'Your Pantry';

    final payload = jsonEncode({
      'householdId': householdId,
      'expiredItemNames': expiredItemNames,
      'atRiskItemNames': atRiskItemNames,
    });

    await addAppNotification(
      AppNotificationModel(
        userId: userId,
        householdId: householdId,
        title: '[$householdName] $title',
        body: body.trim(),
        type: 'pantry_summary',
        createdAt: Timestamp.now(),
        isRead: false,
        payload: payload,
      ),
    );

    // Update the last check timestamp after generating a notification
    await prefs.setString(_lastPantrySummaryNotificationCheckKey + householdId, DateTime.now().toIso8601String());
  }
}
