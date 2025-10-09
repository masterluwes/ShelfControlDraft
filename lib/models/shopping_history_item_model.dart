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

  ShoppingHistoryItemModel({
    this.id,
    required this.householdId,
    this.productId,
    required this.productName,
    this.category,
    required this.quantity,
    required this.purchaseDate,
    this.actionType = 'Consumed', // Default to 'Consumed'
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
    );
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
    );
  }
}
