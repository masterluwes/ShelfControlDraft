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
  int? iconCodePoint; // New field for icon code point
  String? iconFontFamily; // New field for icon font family

  ShoppingListModel({
    this.id,
    required this.householdId,
    required this.name,
    required this.createdAt,
    required this.items,
    required this.type,
    this.isActive = false, // Default to false
    this.iconCodePoint,
    this.iconFontFamily,
  });

  // Factory constructor to create a ShoppingListModel from a Firestore document or a Map
  factory ShoppingListModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return ShoppingListModel(
      id: doc.id,
      householdId: data['householdId'] ?? '',
      name: data['name'] ?? '',
      // Handle both Timestamp and String for createdAt
      createdAt: (data['createdAt'] is Timestamp)
          ? (data['createdAt'] as Timestamp).toDate()
          : (data['createdAt'] is String ? DateTime.tryParse(data['createdAt']) ?? DateTime.now() : DateTime.now()),
      items: (data['items'] as List<dynamic>?)
              ?.map((itemMap) => ShoppingListItemModel.fromMap(itemMap as Map<String, dynamic>))
              .toList() ??
          [],
      type: data['type'] ?? 'Manual',
      isActive: data['isActive'] ?? false,
      iconCodePoint: data['iconCodePoint'],
      iconFontFamily: data['iconFontFamily'],
    );
  }

  // Method to convert a ShoppingListModel to a Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'householdId': householdId,
      'name': name,
      'createdAt': Timestamp.fromDate(createdAt),
      'items': items.map((item) => item.toMap()).toList(), // Include items here
      'type': type,
      'isActive': isActive,
      'iconCodePoint': iconCodePoint,
      'iconFontFamily': iconFontFamily,
    };
  }

  // Method to convert a ShoppingListModel to a JSON-encodable map for local storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'householdId': householdId,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
      'items': items.map((item) => item.toMap()).toList(),
      'type': type,
      'isActive': isActive,
      'iconCodePoint': iconCodePoint,
      'iconFontFamily': iconFontFamily,
    };
  }

  // Factory constructor to create a ShoppingListModel from a JSON-decoded map for local storage
  factory ShoppingListModel.fromJson(Map<String, dynamic> json) {
    return ShoppingListModel(
      id: json['id'],
      householdId: json['householdId'] ?? '',
      name: json['name'] ?? '',
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
      items: (json['items'] as List<dynamic>?)
              ?.map((itemMap) => ShoppingListItemModel.fromMap(itemMap as Map<String, dynamic>))
              .toList() ??
          [],
      type: json['type'] ?? 'Manual',
      isActive: json['isActive'] ?? false,
      iconCodePoint: json['iconCodePoint'],
      iconFontFamily: json['iconFontFamily'],
    );
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
    int? iconCodePoint,
    String? iconFontFamily,
  }) {
    return ShoppingListModel(
      id: id ?? this.id,
      householdId: householdId ?? this.householdId,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      items: items ?? this.items,
      type: type ?? this.type,
      isActive: isActive ?? this.isActive,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      iconFontFamily: iconFontFamily ?? this.iconFontFamily,
    );
  }
}
