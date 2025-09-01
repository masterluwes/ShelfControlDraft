import 'package:cloud_firestore/cloud_firestore.dart';

class PantryItemModel {
  String? id; // Firestore document ID
  String name;
  String category;
  String? imageUrl;
  int qty;
  String? expiresText; // This might be replaced by actual DateTime later
  String? barcode;
  String? brand;
  String? quantityUnit; // e.g., "1L", "397g"

  PantryItemModel({
    this.id,
    required this.name,
    required this.category,
    this.imageUrl,
    required this.qty,
    this.expiresText,
    this.barcode,
    this.brand,
    this.quantityUnit,
  });

  // Factory constructor to create a PantryItemModel from a Firestore document
  factory PantryItemModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return PantryItemModel(
      id: doc.id,
      name: data['name'] ?? '',
      category: data['category'] ?? 'Uncategorized',
      imageUrl: data['imageUrl'],
      qty: data['qty'] ?? 1,
      expiresText: data['expiresText'],
      barcode: data['barcode'],
      brand: data['brand'],
      quantityUnit: data['quantityUnit'],
    );
  }

  // Method to convert a PantryItemModel to a Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'category': category,
      'imageUrl': imageUrl,
      'qty': qty,
      'expiresText': expiresText,
      'barcode': barcode,
      'brand': brand,
      'quantityUnit': quantityUnit,
      'timestamp': FieldValue.serverTimestamp(), // Add a timestamp for creation
    };
  }
}
