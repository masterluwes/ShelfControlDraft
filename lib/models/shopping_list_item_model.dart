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
  String? ecoscore; // New: Optional ecoscore information
  String? suggestionStatus; // New: To indicate suggestion source ('Low on stock', 'Out of stock')
  String? originalPantryItemId; // New: To link back to the original pantry item for suggestions
  DateTime? expirationDate; // New: Expiration date for the item

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
    this.isBookmarked = false,
    this.nutrition,
    this.ecoscore,
    this.suggestionStatus,
    this.originalPantryItemId,
    this.expirationDate,
  });

  factory ShoppingListItemModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ShoppingListItemModel(
      id: doc.id,
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
      ecoscore: data['ecoscore'],
      suggestionStatus: data['suggestionStatus'],
      originalPantryItemId: data['originalPantryItemId'],
      expirationDate: (data['expirationDate'] as Timestamp?)?.toDate(),
    );
  }

  factory ShoppingListItemModel.fromMap(Map<String, dynamic> data) {
    return ShoppingListItemModel(
      id: data['id'],
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
      ecoscore: data['ecoscore'],
      suggestionStatus: data['suggestionStatus'],
      originalPantryItemId: data['originalPantryItemId'],
      expirationDate: (data['expirationDate'] is Timestamp)
          ? (data['expirationDate'] as Timestamp).toDate()
          : (data['expirationDate'] is String)
              ? DateTime.tryParse(data['expirationDate'])
              : null,
    );
  }

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
      'isBookmarked': isBookmarked,
      'nutrition': nutrition,
      'ecoscore': ecoscore,
      'suggestionStatus': suggestionStatus,
      'originalPantryItemId': originalPantryItemId,
      'expirationDate': expirationDate?.toIso8601String(),
    };
  }

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
    bool? isBookmarked,
    String? nutrition,
    String? ecoscore,
    String? suggestionStatus,
    String? originalPantryItemId,
    DateTime? expirationDate,
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
      isBookmarked: isBookmarked ?? this.isBookmarked,
      nutrition: nutrition ?? this.nutrition,
      ecoscore: ecoscore ?? this.ecoscore,
      suggestionStatus: suggestionStatus ?? this.suggestionStatus,
      originalPantryItemId: originalPantryItemId ?? this.originalPantryItemId,
      expirationDate: expirationDate ?? this.expirationDate,
    );
  }
}
