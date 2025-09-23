import 'package:cloud_firestore/cloud_firestore.dart';
import 'shopping_list_item_model.dart'; // Import the new item model

class ShoppingListModel {
  String? id; // Firestore document ID
  String householdId;
  String name;
  DateTime createdAt;
  List<ShoppingListItemModel> items;
  String type; // e.g., 'Budget Friendly', 'Most Recommended', 'Healthy Option', 'Manual'
  bool isActive; // New field for active shopping list

  ShoppingListModel({
    this.id,
    required this.householdId,
    required this.name,
    required this.createdAt,
    required this.items,
    required this.type,
    this.isActive = false, // Default to false
  });

  // Factory constructor to create a ShoppingListModel from a Firestore document
  factory ShoppingListModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return ShoppingListModel(
      id: doc.id,
      householdId: data['householdId'] ?? '',
      name: data['name'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      items: (data['items'] as List<dynamic>?)
              ?.map((itemMap) => ShoppingListItemModel.fromMap(itemMap as Map<String, dynamic>))
              .toList() ??
          [],
      type: data['type'] ?? 'Manual',
      isActive: data['isActive'] ?? false,
    );
  }

  // Method to convert a ShoppingListModel to a Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'householdId': householdId,
      'name': name,
      'createdAt': Timestamp.fromDate(createdAt),
      'items': items.map((item) => item.toMap()).toList(),
      'type': type,
      'isActive': isActive,
      'timestamp': FieldValue.serverTimestamp(), // Add a timestamp for creation/last update
    };
  }

  // Method to create a copy of the current object with updated fields
  ShoppingListModel copyWith({
    String? id,
    String? householdId,
    String? name,
    DateTime? createdAt,
    List<ShoppingListItemModel>? items,
    String? type,
    bool? isActive,
  }) {
    return ShoppingListModel(
      id: id ?? this.id,
      householdId: householdId ?? this.householdId,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      items: items ?? this.items,
      type: type ?? this.type,
      isActive: isActive ?? this.isActive,
    );
  }
}
