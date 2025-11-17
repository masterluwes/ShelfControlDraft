import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String? id; // Firestore document ID
  final String productName;
  final String? category;
  final String? brand; // Added brand field
  final String? netWeight;
  final double? price;
  final String? nutriScore;
  final DateTime? manufacturedDate;
  final DateTime? expirationDate;
  final List<String>? allowedDiets; // New field for allowed diets

  Product({
    this.id,
    required this.productName,
    this.category,
    this.brand, // Added brand to constructor
    this.netWeight,
    this.price,
    this.nutriScore,
    this.manufacturedDate,
    this.expirationDate,
    this.allowedDiets, // Added allowedDiets to constructor
  });

  factory Product.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return Product(
      id: doc.id,
      productName: data['productName'] ?? '',
      category: data['category'],
      brand: data['brand'], // Added brand to fromFirestore
      netWeight: data['netWeight'],
      price: (data['price'] as num?)?.toDouble(),
      nutriScore: data['nutriScore'],
      manufacturedDate: (data['manufacturedDate'] as Timestamp?)?.toDate(),
      expirationDate: (data['expirationDate'] as Timestamp?)?.toDate(),
      allowedDiets: (data['allowedDiets'] as List<dynamic>?)?.map((e) => e.toString()).toList(), // Added allowedDiets to fromFirestore
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'productName': productName,
      'category': category,
      'brand': brand, // Added brand to toFirestore
      'netWeight': netWeight,
      'price': price,
      'nutriScore': nutriScore,
      'manufacturedDate': manufacturedDate != null ? Timestamp.fromDate(manufacturedDate!) : null,
      'expirationDate': expirationDate != null ? Timestamp.fromDate(expirationDate!) : null,
      'allowedDiets': allowedDiets, // Added allowedDiets to toFirestore
    };
  }

  // Method to create a copy of the current object with updated fields
  Product copyWith({
    String? id,
    String? productName,
    String? category,
    String? brand, // Added brand to copyWith
    String? netWeight,
    double? price,
    String? nutriScore,
    DateTime? manufacturedDate,
    DateTime? expirationDate,
    List<String>? allowedDiets, // Added allowedDiets to copyWith
  }) {
    return Product(
      id: id ?? this.id,
      productName: productName ?? this.productName,
      category: category ?? this.category,
      brand: brand ?? this.brand, // Used provided brand or current brand
      netWeight: netWeight ?? this.netWeight,
      price: price ?? this.price,
      nutriScore: nutriScore ?? this.nutriScore,
      manufacturedDate: manufacturedDate ?? this.manufacturedDate,
      expirationDate: expirationDate ?? this.expirationDate,
      allowedDiets: allowedDiets ?? this.allowedDiets, // Used provided allowedDiets or current allowedDiets
    );
  }
}
