import 'package:cloud_firestore/cloud_firestore.dart';

class PantryItemModel {
  String? id; // Firestore document ID
  String name;
  String category;
  String? imageUrl;
  int qty;
  
  // 🚀 FIX: Add price and notes fields
  double price; 
  String? notes; 
  
  // 🚀 FIX: Refine net weight into value (double) and unit (string)
  double netWeight; 
  String? netWeightUnit; 

  String? expiresText; 
  String? barcode;
  String? brand;
  String? quantityUnit; 
  Map<String, dynamic>? nutritionFacts; 
  int? shelfLifeDays;
  int? shelfLifeWeeks;
  int? shelfLifeMonths;
  DateTime? manufacturedDate;
  DateTime? expirationDate;
  
  bool selected;

  PantryItemModel({
    this.id,
    required this.name,
    required this.category,
    this.imageUrl,
    required this.qty,
    
    // 🚀 FIX: Add to constructor
    this.price = 0.0,
    this.notes,
    this.netWeight = 0.0,
    this.netWeightUnit,
    // End of fixes
    
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
    this.selected = false,
  });

  // Factory constructor to create a PantryItemModel from a Firestore document
  factory PantryItemModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    
    // Helper to safely parse numbers
    double _parseDouble(dynamic value) {
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    return PantryItemModel(
      id: doc.id,
      name: data['name'] ?? '',
      category: data['category'] ?? 'Uncategorized',
      imageUrl: data['imageUrl'],
      qty: data['qty'] ?? 1,
      
      // 🚀 FIX: Read new fields from Firestore
      price: _parseDouble(data['price']),
      notes: data['notes'],
      netWeight: _parseDouble(data['netWeight']),
      netWeightUnit: data['netWeightUnit'],
      // End of fixes
      
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
      selected: data['selected'] ?? false,
    );
  }

  // Method to convert a PantryItemModel to a Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'category': category,
      'imageUrl': imageUrl,
      'qty': qty,
      
      // 🚀 FIX: Write new fields to Firestore
      'price': price,
      'notes': notes,
      'netWeight': netWeight,
      'netWeightUnit': netWeightUnit,
      // End of fixes
      
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
      'selected': selected,
      'timestamp': FieldValue.serverTimestamp(), // Add a timestamp for creation
    };
  }
  
  // 🚀 FIX: Add the copyWith method
  PantryItemModel copyWith({
    String? id,
    String? name,
    String? category,
    String? imageUrl,
    int? qty,
    double? price,
    String? notes,
    double? netWeight,
    String? netWeightUnit,
    String? expiresText,
    String? barcode,
    String? brand,
    String? quantityUnit,
    Map<String, dynamic>? nutritionFacts,
    int? shelfLifeDays,
    int? shelfLifeWeeks,
    int? shelfLifeMonths,
    DateTime? manufacturedDate,
    DateTime? expirationDate,
    bool? selected,
  }) {
    return PantryItemModel(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      imageUrl: imageUrl ?? this.imageUrl,
      qty: qty ?? this.qty,
      
      // Update new fields
      price: price ?? this.price,
      notes: notes ?? this.notes,
      netWeight: netWeight ?? this.netWeight,
      netWeightUnit: netWeightUnit ?? this.netWeightUnit,
      
      expiresText: expiresText ?? this.expiresText,
      barcode: barcode ?? this.barcode,
      brand: brand ?? this.brand,
      quantityUnit: quantityUnit ?? this.quantityUnit,
      nutritionFacts: nutritionFacts ?? this.nutritionFacts,
      shelfLifeDays: shelfLifeDays ?? this.shelfLifeDays,
      shelfLifeWeeks: shelfLifeWeeks ?? this.shelfLifeWeeks,
      shelfLifeMonths: shelfLifeMonths ?? this.shelfLifeMonths,
      manufacturedDate: manufacturedDate ?? this.manufacturedDate,
      expirationDate: expirationDate ?? this.expirationDate,
      selected: selected ?? this.selected,
    );
  }
}