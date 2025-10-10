import 'package:cloud_firestore/cloud_firestore.dart';

class ShoppingListItemModel {
  String? id; // Optional: For individual item if stored separately, or just for UI key
  String? productId; // Reference to a product in local_products_ph or a generic product ID
  String name;
  String? brand;
  String? netWeight;
  String? category;
  double unitPrice; // Price of a single unit of the product
  int quantity;
  bool isPurchased;
  bool isBookmarked; // Added isBookmarked field
  String? nutrition; // New: Optional nutrition information

  ShoppingListItemModel({
    this.id,
    this.productId,
    required this.name,
    this.brand,
    this.netWeight,
    this.category,
    required this.unitPrice,
    required this.quantity,
    this.isPurchased = false,
    this.isBookmarked = false, // Initialize isBookmarked
    this.nutrition, // Initialize nutrition
  });

  // Factory constructor to create a ShoppingListItemModel from a Firestore DocumentSnapshot
  factory ShoppingListItemModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ShoppingListItemModel(
      id: doc.id, // Use doc.id for the item's ID
      productId: data['productId'],
      name: data['name'] ?? '',
      brand: data['brand'],
      netWeight: data['netWeight'],
      category: data['category'],
      unitPrice: (data['unitPrice'] as num?)?.toDouble() ?? 0.0,
      quantity: data['quantity'] ?? 1,
      isPurchased: data['isPurchased'] ?? false,
      isBookmarked: data['isBookmarked'] ?? false,
      nutrition: data['nutrition'],
    );
  }

  // Factory constructor to create a ShoppingListItemModel from a map (for local use or array fields)
  factory ShoppingListItemModel.fromMap(Map<String, dynamic> data) {
    return ShoppingListItemModel(
      id: data['id'], // This ID might be null if it's an item within an array field
      productId: data['productId'],
      name: data['name'] ?? '',
      brand: data['brand'],
      netWeight: data['netWeight'],
      category: data['category'],
      unitPrice: (data['unitPrice'] as num?)?.toDouble() ?? 0.0,
      quantity: data['quantity'] ?? 1,
      isPurchased: data['isPurchased'] ?? false,
      isBookmarked: data['isBookmarked'] ?? false,
      nutrition: data['nutrition'],
    );
  }

  // Method to convert a ShoppingListItemModel to a Firestore map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productId': productId,
      'name': name,
      'brand': brand,
      'netWeight': netWeight,
      'category': category,
      'unitPrice': unitPrice,
      'quantity': quantity,
      'isPurchased': isPurchased,
      'isBookmarked': isBookmarked, // Serialize isBookmarked
      'nutrition': nutrition, // Serialize nutrition
    };
  }

  // Method to create a copy of the current object with updated fields
  ShoppingListItemModel copyWith({
    String? id,
    String? productId,
    String? name,
    String? brand,
    String? netWeight,
    String? category,
    double? unitPrice,
    int? quantity,
    bool? isPurchased,
    bool? isBookmarked, // Added to copyWith
    String? nutrition, // Added to copyWith
  }) {
    return ShoppingListItemModel(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      netWeight: netWeight ?? this.netWeight,
      category: category ?? this.category,
      unitPrice: unitPrice ?? this.unitPrice,
      quantity: quantity ?? this.quantity,
      isPurchased: isPurchased ?? this.isPurchased,
      isBookmarked: isBookmarked ?? this.isBookmarked, // Copy isBookmarked
      nutrition: nutrition ?? this.nutrition, // Copy nutrition
    );
  }
}
