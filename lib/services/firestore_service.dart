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
import 'package:shelf_control/services/open_food_facts_service.dart'; // Import OpenFoodFactsService
import 'package:uuid/uuid.dart'; // For generating unique IDs
import 'package:shared_preferences/shared_preferences.dart'; // Import SharedPreferences
import 'dart:convert'; // For JSON encoding/decoding
// import 'package:fuzzywuzzy/fuzzywuzzy.dart'; // Removed fuzzywuzzy
import 'package:shelf_control/models/user_prefs_model.dart';
import 'package:shelf_control/services/normalization.dart';

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

  /// Returns all pantry items for a household.
  Future<List<PantryItemModel>> getPantryForHousehold(
      String householdId) async {
    final snap = await FirebaseFirestore.instance
        .collection('households')
        .doc(householdId)
        .collection('pantryItems')
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
    } else {
      await prefs.remove('selectedHouseholdId');
    }
  }

  // Load selected household ID from SharedPreferences
  Future<String?> _loadSelectedHouseholdId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('selectedHouseholdId');
  }

  // Clear selected household ID from SharedPreferences
  Future<void> clearSelectedHouseholdId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('selectedHouseholdId');
    _selectedHouseholdId = null; // Also clear in-memory
    notifyListeners();
  }

  // Set the initial selected household for a user
  Future<void> setInitialHousehold(String userId) async {
    print('DEBUG: setInitialHousehold called for userId: $userId');
    print(
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
        print('DEBUG: Set selectedHouseholdId for authenticated user to personalHouseholdId: $selectedHouseholdId');
        return;
      } else {
        // This case should ideally not happen for a registered user.
        // If it does, it means their user document is missing personalHouseholdId.
        // We might need to create one or handle this as an error.
        print('DEBUG: Authenticated user has no personalHouseholdId. Attempting to create one.');
        await createPersonalHousehold(userId, _auth.currentUser?.email ?? 'unknown@user.com');
        return;
      }
    } else {
      // For anonymous users:
      // 1. Try to load from SharedPreferences
      String? storedHouseholdId = await _loadSelectedHouseholdId();
      print('DEBUG: Stored household ID from SharedPreferences (anonymous): $storedHouseholdId');

      if (storedHouseholdId != null) {
        // Check if the stored household still exists and the user is a member (should be userId for anonymous)
        final householdDoc = await _db.collection('households').doc(storedHouseholdId).get();
        if (householdDoc.exists && householdDoc.data() != null && householdDoc.data()!['members'].contains(userId)) {
          selectedHouseholdId = storedHouseholdId;
          print('DEBUG: Set selectedHouseholdId from stored (anonymous): $selectedHouseholdId');
          return;
        }
      }

      // If no valid stored household, default to personal household (which is userId for anonymous)
      selectedHouseholdId = userId;
      print(
          'DEBUG: Set selectedHouseholdId for anonymous user: $selectedHouseholdId');
      // Ensure a personal household is created for anonymous users if it doesn't exist
      final householdDoc = await _db.collection('households').doc(userId).get();
      if (!householdDoc.exists) {
        print('DEBUG: Creating personal household for anonymous user: $userId');
        await createPersonalHousehold(
            userId, 'anonymous@guest.com'); // Use a dummy email for anonymous
      }
    }
    print(
        'DEBUG: Final selectedHouseholdId after setInitialHousehold: $selectedHouseholdId');
  }

  // Create a personal household for a new user (or anonymous user)
  Future<void> createPersonalHousehold(String userId, String userEmail) async {
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

  // Save guest pantry items to local storage
  Future<void> saveGuestPantryItems(List<PantryItemModel> items) async {
    final prefs = await SharedPreferences.getInstance();
    final String encodedData =
        json.encode(items.map((item) => item.toJson()).toList());
    await prefs.setString(_guestPantryKey, encodedData);
    print(
        'DEBUG: Saved ${items.length} guest pantry items to SharedPreferences.');
    print('DEBUG: Encoded guest pantry data: $encodedData');
    notifyListeners(); // Notify listeners that guest pantry data has changed
  }

  // Load guest pantry items from local storage
  Future<List<PantryItemModel>> loadGuestPantryItems() async {
    final prefs = await SharedPreferences.getInstance();
    final String? encodedData = prefs.getString(_guestPantryKey);
    if (encodedData == null) {
      print('DEBUG: No guest pantry data found in SharedPreferences.');
      return [];
    }
    final List<dynamic> decodedData = json.decode(encodedData);
    final List<PantryItemModel> loadedItems =
        decodedData.map((data) => PantryItemModel.fromJson(data)).toList();
    print(
        'DEBUG: Loaded ${loadedItems.length} guest pantry items from SharedPreferences.');
    print('DEBUG: Decoded guest pantry data: $encodedData');
    return loadedItems;
  }

  // Save guest shopping lists to local storage
  Future<void> saveGuestShoppingLists(List<ShoppingListModel> lists) async {
    final prefs = await SharedPreferences.getInstance();
    final String encodedData =
        json.encode(lists.map((list) => list.toJson()).toList());
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
    return decodedData.map((data) => ShoppingListModel.fromJson(data)).toList();
  }

  // Stream for guest shopping lists from local storage
  Stream<List<ShoppingListModel>> guestShoppingListsStream() {
    // This is a simplified stream for guest mode, as SharedPreferences doesn't have native stream support.
    // It will emit the current state whenever `saveGuestShoppingLists` is called.
    // For a more robust solution, a StreamController could be used within FirestoreService.
    return Stream.fromFuture(loadGuestShoppingLists());
  }

  // Clear all guest data from local storage
  Future<void> clearGuestData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_guestPantryKey);
    await prefs.remove(_guestShoppingListKey);
  }

  // Get a stream of pantry items for a specific household
  Stream<List<PantryItemModel>> getPantryItemsForHousehold(String householdId) {
    if (_auth.currentUser?.isAnonymous ?? false) {
      return Stream.fromFuture(loadGuestPantryItems());
    }
    return _db
        .collection('pantryItems')
        .where('householdId', isEqualTo: householdId)
        .orderBy('timestamp', descending: true) // keep if you have this field
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
    if (_auth.currentUser?.isAnonymous ?? false) {
      // For guest users, return a stream from local storage
      return Stream.fromFuture(loadGuestShoppingLists());
    }
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
    await _db.collection('shoppingLists').doc(listId).delete();
  }

  // Delete a household and all associated data
  Future<void> deleteHousehold(String householdId) async {
    // 1. Delete all pantry items for the household
    final pantryItemsQuery = await _db
        .collection('pantryItems')
        .where('householdId', isEqualTo: householdId)
        .get();
    for (final doc in pantryItemsQuery.docs) {
      await doc.reference.delete();
    }

    // 2. Delete all shopping lists for the household
    final shoppingListsQuery = await _db
        .collection('shoppingLists')
        .where('householdId', isEqualTo: householdId)
        .get();
    for (final doc in shoppingListsQuery.docs) {
      await doc.reference.delete();
    }

    // 3. Delete all shopping history items for the household
    final shoppingHistoryQuery = await _db
        .collection('shoppingHistory')
        .where('householdId', isEqualTo: householdId)
        .get();
    for (final doc in shoppingHistoryQuery.docs) {
      await doc.reference.delete();
    }

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

    // 5. Finally, delete the household document itself
    await _db.collection('households').doc(householdId).delete();

    // If the deleted household was the currently selected one, reset selectedHouseholdId
    if (_selectedHouseholdId == householdId) {
      _selectedHouseholdId = null; // Clear the selected household
      // Attempt to set an initial household (e.g., personal household)
      if (userId != null) {
        await setInitialHousehold(userId!);
      }
    }
    notifyListeners(); // Notify listeners after deletion
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
      await _db
          .collection('shoppingLists')
          .doc(doc.id)
          .update({'isActive': false});
    }

    // Activate the selected list
    await _db
        .collection('shoppingLists')
        .doc(listId)
        .update({'isActive': true});
  }

  // Get the currently active shopping list for a household
  Stream<ShoppingListModel?> streamActiveShoppingList(String householdId) {
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

  // Stream for suggestions (adapting from ShoppingListService)
  Stream<List<ShoppingListItemModel>> streamSuggestions(String householdId) {
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


      // 1. Out of Stock, Expired, Low Stock from pantry
      for (var item in pantryItems) {
        String? status;
        if (item.qty > 0 && item.qty <= 2) { // Example threshold for "low stock"
          status = 'Low on stock';
        } else if (item.qty <= 0 || item.status == 'Consumed' || (item.expirationDate != null && item.expirationDate!.isBefore(DateTime.now()))) {
          status = 'Out of stock';
        }

        if (status != null && !activeListItemNames.contains(item.name.toLowerCase())) {
          final scores = await openFoodFactsService.getNutriAndEcoScore(item.name);
          suggestions.add(ShoppingListItemModel(
            id: _uuid.v4(), // Assign unique ID
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
        if (!inPantry && !activeListItemNames.contains(item.productName.toLowerCase())) {
          final scores = await openFoodFactsService.getNutriAndEcoScore(item.productName);
          suggestions.add(ShoppingListItemModel(
            id: _uuid.v4(), // Assign unique ID
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
    });
  }

  // --- Notification Settings Methods ---

  // Save notification settings for a user
  Future<void> saveNotificationSettings(
      String userId, Map<String, dynamic> settings) async {
    await _db.collection('users').doc(userId).update({
      'notificationSettings': settings,
    });
  }

  // Get notification settings for a user
  Future<Map<String, dynamic>?> getNotificationSettings(String userId) async {
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
    await _db.collection('shoppingHistory').add(item.toFirestore());
  }

  // Get a stream of shopping history items for a specific household
  Stream<List<ShoppingHistoryItemModel>> getShoppingHistoryForHousehold(
      String householdId) {
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
      );
      await _db.collection('shoppingHistory').add(historyItem.toFirestore());
    }
  }

  // Record consumed items
  Future<void> recordConsumedItem(PantryItemModel item, int consumedQty) async {
    if (selectedHouseholdId == null) {
      throw Exception("No household selected.");
    }

    if (consumedQty <= 0) {
      return; // Nothing to consume
    }

    if (_auth.currentUser?.isAnonymous ?? false) {
      // For guest users, update in local storage
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
    } else {
      // First, update the original item's quantity in the pantry
      if (item.qty > consumedQty) {
        await _pantryCol(selectedHouseholdId!).doc(item.id).update({
          'qty': item.qty - consumedQty,
        });
      } else {
        // If all available quantity is consumed, delete the item from the pantry
        await _pantryCol(selectedHouseholdId!).doc(item.id).delete();
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
        quantity: consumedQty,
        purchaseDate: DateTime.now(), // Represents consumption date
        actionType: 'Consumed', // Set action type to 'Consumed'
      );
      await _db.collection('shoppingHistory').add(historyItem.toFirestore());
    }
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
      List<String> householdIds =
          List<String>.from(userDoc.data()!['householdIds']);
      if (householdIds.isEmpty) {
        return [];
      }
      final querySnapshot = await _db
          .collection('households')
          .where(FieldPath.documentId, whereIn: householdIds)
          .get();
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

  

  Future<void> consumePantryForRecipe({
  required String householdId,
  required List<Map<String, dynamic>> ingredients,
}) async {
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
      continue;
    }

    final newQty = (currentQty - reqQty).clamp(0, double.infinity);

    if (newQty == 0) {
      batch.delete(doc.reference);
    } else {
      batch.update(doc.reference, {
        'qty': newQty,
        'unit': currentUnit.isNotEmpty ? currentUnit : reqUnit,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  await batch.commit();
}

  // Join an existing household
  Future<void> joinHousehold(String joinCode) async {
    if (userId == null) {
      throw Exception("User not logged in.");
    }

    final querySnapshot = await _db
        .collection('households')
        .where('joinCode', isEqualTo: joinCode)
        .limit(1)
        .get();

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

  // Update a household's name
  Future<void> updateHouseholdName(String householdId, String newName) async {
    await _db.collection('households').doc(householdId).update({
      'name': newName,
    });
    notifyListeners(); // Notify listeners of the change
  }

  // Update a user's FCM token
  Future<void> updateUserFCMToken(String userId, String token) async {
    await _db.collection('users').doc(userId).set(
        {
          'fcmToken': token,
        },
        SetOptions(
            merge: true)); // Use merge to avoid overwriting other user data
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

  Future<void> markAsWasted(PantryItemModel item) async {
    if (selectedHouseholdId == null || item.id == null) {
      throw Exception("No household selected or item ID is missing.");
    }
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
    if (query.isEmpty) {
      return Stream.value([]);
    }
    return _db
        .collection('local_products_ph')
        .where('productName', isGreaterThanOrEqualTo: query)
        .where('productName', isLessThanOrEqualTo: '$query\uf8ff')
        .limit(10) // Limit to 10 suggestions
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList());
  }

  CollectionReference<Map<String, dynamic>> _pantryCol(String householdId) {
    return _db.collection('pantryItems');
  }

  // Get frequently consumed items for a household
  Future<List<Map<String, dynamic>>> getFrequentlyConsumedItems(
      String householdId,
      {int limit = 5,
      int days = 30}) async {
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

    return sortedItems.take(limit).toList();
  }

  // --- Batch Consumption Method ---
  Future<void> batchConsumePantryItems(
      String householdId, Map<String, int> itemsToConsume) async {
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
        } else {
          batch.delete(itemRef);
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
      }
    }
    await batch.commit();
  }

  // --- App Notification Methods ---

  // Add or update an app notification to prevent duplicates
  Future<void> addAppNotification(AppNotificationModel notification) async {
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
      });
    } else {
      // Add new notification
      await _db.collection('appNotifications').add(notification.toFirestore());
    }
  }

  // Get a stream of app notifications for a user
  Stream<List<AppNotificationModel>> getAppNotificationsStream(String userId) {
    return _db
        .collection('appNotifications')
        .where('userId', isEqualTo: userId) // Filter by userId
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AppNotificationModel.fromFirestore(doc))
            .toList());
  }

  // Mark a specific notification as read
  Future<void> markNotificationAsRead(
      String userId, String notificationId) async {
    await _db.collection('appNotifications').doc(notificationId).update({
      'isRead': true,
    });
  }

  // Get a stream of the count of unread notifications for a user
  Stream<int> getUnreadNotificationsCountStream(String userId) {
    return _db
        .collection('appNotifications')
        .where('userId', isEqualTo: userId) // Filter by userId
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }
}
