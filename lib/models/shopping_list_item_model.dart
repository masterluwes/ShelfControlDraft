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
  String? notes;

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
    this.notes,
  });

  // Factory constructor to create a ShoppingListItemModel from a Firestore map
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
      isBookmarked: data['isBookmarked'] ?? false, // Deserialize isBookmarked
      notes: data['notes'],
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
      'notes': notes,
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
    String? notes,
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
      notes: notes ?? this.notes,
    );
  }
}
