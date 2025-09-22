import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String productName;
  final String? netWeight;
  final double? price;

  Product({
    required this.productName,
    this.netWeight,
    this.price,
  });

  factory Product.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return Product(
      productName: data['productName'] ?? '',
      netWeight: data['netWeight'],
      price: (data['price'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'productName': productName,
      'netWeight': netWeight,
      'price': price,
    };
  }
}
