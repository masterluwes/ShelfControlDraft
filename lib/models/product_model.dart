import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String? id; // Firestore document ID
  final String productName;
  final String? brand; // New field
  final String? category; // New field
  final String? netWeight;
  final double? price;
  final String? nutriScore; // New field for healthy options

  Product({
    this.id,
    required this.productName,
    this.brand,
    this.category,
    this.netWeight,
    this.price,
    this.nutriScore,
  });

  factory Product.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return Product(
      id: doc.id,
      productName: data['productName'] ?? '',
      brand: data['brand'],
      category: data['category'],
      netWeight: data['netWeight'],
      price: (data['price'] as num?)?.toDouble(),
      nutriScore: data['nutriScore'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'productName': productName,
      'brand': brand,
      'category': category,
      'netWeight': netWeight,
      'price': price,
      'nutriScore': nutriScore,
    };
  }

  // Method to create a copy of the current object with updated fields
  Product copyWith({
    String? id,
    String? productName,
    String? brand,
    String? category,
    String? netWeight,
    double? price,
    String? nutriScore,
  }) {
    return Product(
      id: id ?? this.id,
      productName: productName ?? this.productName,
      brand: brand ?? this.brand,
      category: category ?? this.category,
      netWeight: netWeight ?? this.netWeight,
      price: price ?? this.price,
      nutriScore: nutriScore ?? this.nutriScore,
    );
  }
}
