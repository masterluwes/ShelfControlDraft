import 'package:cloud_firestore/cloud_firestore.dart';

class PantryItemModel {
  String? id; // Firestore document ID
  String householdId; // New field for household ID
  String name;
  String category;
  double? price;
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
  String status; // New field for item status (e.g., "Available", "Active", "At Risk", "Consumed")
  DateTime? consumedAt; // New field for when the item was consumed
  DateTime? deletedAt; // New field for when the item was deleted
  String? notes; // New field for notes
  String? storageLocation; // New field for storage location

  PantryItemModel({
    this.id,
    required this.householdId, // Add householdId to constructor
    required this.name,
    required this.category,
    this.price,
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
    this.status = 'Available', // Default status to "Available"
    this.consumedAt, // Add consumedAt to constructor
    this.deletedAt, // Add deletedAt to constructor
    this.notes, // Add notes to constructor
    this.storageLocation, // Add storageLocation to constructor
  });

  // Factory constructor to create a PantryItemModel from a Firestore document
  factory PantryItemModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return PantryItemModel(
      id: doc.id,
      householdId: data['householdId'] ?? '', // Add householdId to fromFirestore
      name: data['name'] ?? '',
      category: data['category'] ?? 'Uncategorized',
      price: (data['price'] as num?)?.toDouble(),
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
      status: data['status'] ?? 'Available', // Add status to fromFirestore
      consumedAt: (data['consumedAt'] as Timestamp?)?.toDate(), // Add consumedAt to fromFirestore
      deletedAt: (data['deletedAt'] as Timestamp?)?.toDate(), // Add deletedAt to fromFirestore
      notes: data['notes'], // Add notes to fromFirestore
      storageLocation: data['storageLocation'], // Add storageLocation to fromFirestore
    );
  }

  // Method to convert a PantryItemModel to a Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'householdId': householdId, // Add householdId to toFirestore
      'name': name,
      'category': category,
      'price': price,
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
      'status': status, // Add status to toFirestore
      'consumedAt': consumedAt != null ? Timestamp.fromDate(consumedAt!) : null, // Add consumedAt to toFirestore
      'deletedAt': deletedAt != null ? Timestamp.fromDate(deletedAt!) : null, // Add deletedAt to toFirestore
      'notes': notes, // Add notes to toFirestore
      'storageLocation': storageLocation, // Add storageLocation to toFirestore
      'timestamp': FieldValue.serverTimestamp(), // Add a timestamp for creation
    };
  }

  // Method to create a copy of the current object with updated fields
  PantryItemModel copyWith({
    String? id,
    String? status,
    int? qty,
    double? price,
    DateTime? consumedAt,
    DateTime? deletedAt,
    String? notes, // Add notes to copyWith
    String? storageLocation, String? householdId, // Add storageLocation to copyWith
  }) {
    return PantryItemModel(
      id: id ?? this.id, // Use provided id or current id
      householdId: householdId ?? this.householdId,
      name: name,
      category: category,
      price: price ?? this.price,
      imageUrl: imageUrl,
      qty: qty ?? this.qty, // Use provided qty or current qty
      expiresText: expiresText,
      barcode: barcode,
      brand: brand,
      quantityUnit: quantityUnit,
      nutritionFacts: nutritionFacts,
      shelfLifeDays: shelfLifeDays,
      shelfLifeWeeks: shelfLifeWeeks,
      shelfLifeMonths: shelfLifeMonths,
      manufacturedDate: manufacturedDate,
      expirationDate: expirationDate,
      netWeight: netWeight,
      selected: selected,
      status: status ?? this.status, // Use provided status or current status
      consumedAt: consumedAt ?? this.consumedAt, // Use provided consumedAt or current consumedAt
      deletedAt: deletedAt ?? this.deletedAt, // Use provided deletedAt or current deletedAt
      notes: notes ?? this.notes, // Use provided notes or current notes
      storageLocation: storageLocation ?? this.storageLocation, // Use provided storageLocation or current storageLocation
    );
  }
}
