import 'package:cloud_firestore/cloud_firestore.dart';

class PantryItemModel {
  String? id; // Firestore document ID
  String householdId; // New field for household ID
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
  String status; // New field for item status (e.g., "Available", "Active", "At Risk", "Consumed")
  DateTime? consumedAt; // New field for when the item was consumed
  DateTime? wastedAt; // New field for when the item was wasted
  DateTime? deletedAt; // New field for when the item was deleted
  String? notes; // New field for notes
  String? storageLocation; // New field for storage location
  final double? price;

  PantryItemModel({
    this.id,
    required this.householdId, // Add householdId to constructor
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
    this.status = 'Available', // Default status to "Available"
    this.consumedAt, // Add consumedAt to constructor
    this.wastedAt, // Add wastedAt to constructor
    this.deletedAt, // Add deletedAt to constructor
    this.notes, // Add notes to constructor
    this.storageLocation, // Add storageLocation to constructor
    this.price
  });

  // Factory constructor to create a PantryItemModel from a Firestore document
  factory PantryItemModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return PantryItemModel(
      id: doc.id,
      householdId: data['householdId'] ?? '', // Add householdId to fromFirestore
      name: data['name'] ?? '',
      category: data['category'] ?? 'Uncategorized',
      imageUrl: data['imageUrl'],
      qty: data['qty'] ?? 1,
      expiresText: data['expiresText'],
      barcode: data['barcode'],
      brand: data['brand'],
      quantityUnit: data['quantityUnit'],
      nutritionFacts: data['nutritionFacts'] != null ? Map<String, dynamic>.from(data['nutritionFacts']) : null,
      shelfLifeDays: data['shelfLifeDays'],
      shelfLifeWeeks: data['shelfLifeWeeks'],
      shelfLifeMonths: data['shelfLifeMonths'],
      manufacturedDate: (data['manufacturedDate'] as Timestamp?)?.toDate(),
      expirationDate: (data['expirationDate'] as Timestamp?)?.toDate(),
      netWeight: data['netWeight'], // Add netWeight to fromFirestore
      selected: data['selected'] ?? false, // Add selected to fromFirestore
      status: data['status'] ?? 'Available', // Add status to fromFirestore
      consumedAt: (data['consumedAt'] as Timestamp?)?.toDate(), // Add consumedAt to fromFirestore
      wastedAt: (data['wastedAt'] as Timestamp?)?.toDate(), // Add wastedAt to fromFirestore
      deletedAt: (data['deletedAt'] as Timestamp?)?.toDate(), // Add deletedAt to fromFirestore
      notes: data['notes'], // Add notes to fromFirestore
      storageLocation: data['storageLocation'], // Add storageLocation to fromFirestore
      price: (data['price'] as num?)?.toDouble(),
    );
  }

  // Factory constructor to create a PantryItemModel from a Map
  factory PantryItemModel.fromMap(Map<String, dynamic> data) {
    return PantryItemModel(
      id: data['id'], // Assuming 'id' is present in the map if it's a full item
      householdId: data['householdId'] ?? '',
      name: data['name'] ?? '',
      category: data['category'] ?? 'Uncategorized',
      imageUrl: data['imageUrl'],
      qty: data['qty'] ?? 1,
      expiresText: data['expiresText'],
      barcode: data['barcode'],
      brand: data['brand'],
      quantityUnit: data['quantityUnit'],
      nutritionFacts: data['nutritionFacts'] != null ? Map<String, dynamic>.from(data['nutritionFacts']) : null,
      shelfLifeDays: data['shelfLifeDays'],
      shelfLifeWeeks: data['shelfLifeWeeks'],
      shelfLifeMonths: data['shelfLifeMonths'],
      manufacturedDate: (data['manufacturedDate'] is Timestamp) ? (data['manufacturedDate'] as Timestamp).toDate() : (data['manufacturedDate'] is String ? DateTime.tryParse(data['manufacturedDate']) : null),
      expirationDate: (data['expirationDate'] is Timestamp) ? (data['expirationDate'] as Timestamp).toDate() : (data['expirationDate'] is String ? DateTime.tryParse(data['expirationDate']) : null),
      netWeight: data['netWeight'],
      selected: data['selected'] ?? false,
      status: data['status'] ?? 'Available',
      consumedAt: (data['consumedAt'] is Timestamp) ? (data['consumedAt'] as Timestamp).toDate() : (data['consumedAt'] is String ? DateTime.tryParse(data['consumedAt']) : null),
      deletedAt: (data['deletedAt'] is Timestamp) ? (data['deletedAt'] as Timestamp).toDate() : (data['deletedAt'] is String ? DateTime.tryParse(data['deletedAt']) : null),
      notes: data['notes'],
      storageLocation: data['storageLocation'],
      price: (data['price'] as num?)?.toDouble(),
    );
  }

  // Method to convert a PantryItemModel to a Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'householdId': householdId, // Add householdId to toFirestore
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
      'status': status, // Add status to toFirestore
      'consumedAt': consumedAt != null ? Timestamp.fromDate(consumedAt!) : null, // Add consumedAt to toFirestore
      'wastedAt': wastedAt != null ? Timestamp.fromDate(wastedAt!) : null, // Add wastedAt to toFirestore
      'deletedAt': deletedAt != null ? Timestamp.fromDate(deletedAt!) : null, // Add deletedAt to toFirestore
      'notes': notes, // Add notes to toFirestore
      'storageLocation': storageLocation, // Add storageLocation to toFirestore
      'price': price,
      'timestamp': FieldValue.serverTimestamp(), // Add a timestamp for creation
    };
  }

  // Method to create a copy of the current object with updated fields
  PantryItemModel copyWith({
    String? id,
    String? householdId,
    String? name,
    String? category,
    String? imageUrl,
    int? qty,
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
    String? netWeight,
    bool? selected,
    String? status,
    DateTime? consumedAt,
    DateTime? wastedAt,
    DateTime? deletedAt,
    String? notes,
    String? storageLocation,
    double? price,
  }) {
    return PantryItemModel(
      id: id ?? this.id,
      householdId: householdId ?? this.householdId,
      name: name ?? this.name,
      category: category ?? this.category,
      imageUrl: imageUrl ?? this.imageUrl,
      qty: qty ?? this.qty,
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
      netWeight: netWeight ?? this.netWeight,
      selected: selected ?? this.selected,
      status: status ?? this.status,
      consumedAt: consumedAt ?? this.consumedAt,
      wastedAt: wastedAt ?? this.wastedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      notes: notes ?? this.notes,
      storageLocation: storageLocation ?? this.storageLocation,
      price: price ?? this.price,
    );
  }
}
