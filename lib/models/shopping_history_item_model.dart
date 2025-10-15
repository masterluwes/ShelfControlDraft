import 'package:cloud_firestore/cloud_firestore.dart';

class ShoppingHistoryItemModel {
  String? id; // Firestore document ID
  String householdId;
  String? productId; // Reference to a product in local_products_ph or a generic product ID
  String productName;
  String? category;
  int quantity;
  DateTime purchaseDate;
  String actionType; // New field: 'Consumed' or 'Deleted'
  double? priceAtAction; // New field for price at the time of action

  ShoppingHistoryItemModel({
    this.id,
    required this.householdId,
    this.productId,
    required this.productName,
    this.category,
    required this.quantity,
    required this.purchaseDate,
    this.actionType = 'Consumed', // Default to 'Consumed'
    this.priceAtAction, // Initialize new field
  });

  // Factory constructor to create a ShoppingHistoryItemModel from a Firestore document
  factory ShoppingHistoryItemModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return ShoppingHistoryItemModel(
      id: doc.id,
      householdId: data['householdId'] ?? '',
      productId: data['productId'],
      productName: data['productName'] ?? '',
      category: data['category'],
      quantity: data['quantity'] ?? 1,
      purchaseDate: (data['purchaseDate'] as Timestamp).toDate(),
      actionType: data['actionType'] ?? 'Consumed', // Add actionType to fromFirestore
      priceAtAction: (data['priceAtAction'] as num?)?.toDouble(), // Add priceAtAction to fromFirestore
    );
  }

  // Factory constructor to create a ShoppingHistoryItemModel from a JSON map (for local storage)
  factory ShoppingHistoryItemModel.fromJson(Map<String, dynamic> json) {
    return ShoppingHistoryItemModel(
      id: json['id'],
      householdId: json['householdId'] ?? '',
      productId: json['productId'],
      productName: json['productName'] ?? '',
      category: json['category'],
      quantity: json['quantity'] ?? 1,
      purchaseDate: DateTime.parse(json['purchaseDate']),
      actionType: json['actionType'] ?? 'Consumed',
      priceAtAction: (json['priceAtAction'] as num?)?.toDouble(),
    );
  }

  // Method to convert a ShoppingHistoryItemModel to a JSON map (for local storage)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'householdId': householdId,
      'productId': productId,
      'productName': productName,
      'category': category,
      'quantity': quantity,
      'purchaseDate': purchaseDate.toIso8601String(),
      'actionType': actionType,
      'priceAtAction': priceAtAction,
    };
  }

  // Method to convert a ShoppingHistoryItemModel to a Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'householdId': householdId,
      'productId': productId,
      'productName': productName,
      'category': category,
      'quantity': quantity,
      'purchaseDate': Timestamp.fromDate(purchaseDate),
      'actionType': actionType, // Add actionType to toFirestore
      'priceAtAction': priceAtAction, // Add priceAtAction to toFirestore
      'timestamp': FieldValue.serverTimestamp(), // Add a timestamp for creation
    };
  }

  // Method to create a copy of the current object with updated fields
  ShoppingHistoryItemModel copyWith({
    String? id,
    String? householdId,
    String? productId,
    String? productName,
    String? category,
    int? quantity,
    DateTime? purchaseDate,
    String? actionType, // Add actionType to copyWith
    double? priceAtAction, // Add priceAtAction to copyWith
  }) {
    return ShoppingHistoryItemModel(
      id: id ?? this.id,
      householdId: householdId ?? this.householdId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      category: category ?? this.category,
      quantity: quantity ?? this.quantity,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      actionType: actionType ?? this.actionType, // Use provided actionType or current actionType
      priceAtAction: priceAtAction ?? this.priceAtAction, // Use provided priceAtAction or current priceAtAction
    );
  }
}
