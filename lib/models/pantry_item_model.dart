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
  Map<String, dynamic>? nutritionFacts; // New field for nutrition information
  int? shelfLifeDays;
  int? shelfLifeWeeks;
  int? shelfLifeMonths;
  DateTime? manufacturedDate;
  DateTime? expirationDate;
  String? netWeight; // New field for net weight
  bool selected; // New field for selection in UI

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
    this.nutritionFacts,
    this.shelfLifeDays,
    this.shelfLifeWeeks,
    this.shelfLifeMonths,
    this.manufacturedDate,
    this.expirationDate,
    this.netWeight, // Add netWeight to constructor
    this.selected = false, // Default to false
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
      nutritionFacts: data['nutritionFacts'] is Map ? Map<String, dynamic>.from(data['nutritionFacts']) : null,
      shelfLifeDays: data['shelfLifeDays'],
      shelfLifeWeeks: data['shelfLifeWeeks'],
      shelfLifeMonths: data['shelfLifeMonths'],
      manufacturedDate: (data['manufacturedDate'] as Timestamp?)?.toDate(),
      expirationDate: (data['expirationDate'] as Timestamp?)?.toDate(),
      netWeight: data['netWeight'], // Add netWeight to fromFirestore
      selected: data['selected'] ?? false, // Add selected to fromFirestore
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
      'nutritionFacts': nutritionFacts,
      'shelfLifeDays': shelfLifeDays,
      'shelfLifeWeeks': shelfLifeWeeks,
      'shelfLifeMonths': shelfLifeMonths,
      'manufacturedDate': manufacturedDate != null ? Timestamp.fromDate(manufacturedDate!) : null,
      'expirationDate': expirationDate != null ? Timestamp.fromDate(expirationDate!) : null,
      'netWeight': netWeight, // Add netWeight to toFirestore
      'selected': selected, // Add selected to toFirestore
      'timestamp': FieldValue.serverTimestamp(), // Add a timestamp for creation
    };
  }
}
