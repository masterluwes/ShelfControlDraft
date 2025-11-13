import 'package:cloud_firestore/cloud_firestore.dart';

class PantryItemModel {
  String? id; // Firestore document ID
  String householdId; // New field for household ID
  String name;
  String category; // User's assigned category
  List<String>? apiCategories; // Categories detected from API
  String? imageUrl;
  int qty;
  String? expiresText; // This might be replaced by actual DateTime later
  String? barcode;
  String? quantityUnit; // e.g., "1L", "397g"
  Map<String, dynamic>? nutritionFacts; // New field for nutrition information
  String? nutrition; // New field for nutrition string
  String? ecoscore; // New field for ecoscore
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
  DateTime? timestamp; // New field for creation/update timestamp

  PantryItemModel({
    this.id,
    required this.householdId, // Add householdId to constructor
    required this.name,
    required this.category,
    this.apiCategories, // Add apiCategories to constructor
    this.imageUrl,
    required this.qty,
    this.expiresText,
    this.barcode,
    this.quantityUnit,
    this.nutritionFacts,
    this.nutrition, // Add nutrition to constructor
    this.ecoscore, // Add ecoscore to constructor
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
    this.price,
    this.timestamp,
  });

  factory PantryItemModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return PantryItemModel(
      id: doc.id,
      householdId: data['householdId'] ?? '',
      name: data['name'] ?? '',
      category: data['category'] ?? 'Uncategorized',
      apiCategories: (data['apiCategories'] as List?)?.map((e) => e.toString()).toList(), // Add apiCategories from Firestore
      imageUrl: data['imageUrl'],
      qty: data['qty'] ?? 1,
      expiresText: data['expiresText']?.toString(),
      barcode: data['barcode'],
      quantityUnit: data['quantityUnit'],
      nutritionFacts: data['nutritionFacts'] != null ? Map<String, dynamic>.from(data['nutritionFacts']) : null,
      nutrition: data['nutrition'],
      ecoscore: data['ecoscore'],
      shelfLifeDays: data['shelfLifeDays'],
      shelfLifeWeeks: data['shelfLifeWeeks'],
      shelfLifeMonths: data['shelfLifeMonths'],
      manufacturedDate: (data['manufacturedDate'] as Timestamp?)?.toDate(),
      expirationDate: (data['expirationDate'] as Timestamp?)?.toDate(),
      netWeight: data['netWeight'],
      selected: data['selected'] ?? false,
      status: data['status'] ?? 'Available',
      consumedAt: (data['consumedAt'] as Timestamp?)?.toDate(),
      wastedAt: (data['wastedAt'] as Timestamp?)?.toDate(),
      deletedAt: (data['deletedAt'] as Timestamp?)?.toDate(),
      notes: data['notes'],
      storageLocation: data['storageLocation'],
      price: (data['price'] as num?)?.toDouble(),
      timestamp: (data['timestamp'] as Timestamp?)?.toDate(),
    );
  }

  factory PantryItemModel.fromMap(Map<String, dynamic> data) {
    return PantryItemModel(
      id: data['id'],
      householdId: data['householdId'] ?? '',
      name: data['name'] ?? '',
      category: data['category'] ?? 'Uncategorized',
      apiCategories: (data['apiCategories'] as List?)?.map((e) => e.toString()).toList(), // Add apiCategories from map
      imageUrl: data['imageUrl'],
      qty: data['qty'] ?? 1,
      expiresText: data['expiresText'],
      barcode: data['barcode'],
      quantityUnit: data['quantityUnit'],
      nutritionFacts: data['nutritionFacts'] != null ? Map<String, dynamic>.from(data['nutritionFacts']) : null,
      nutrition: data['nutrition'],
      ecoscore: data['ecoscore'],
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
      timestamp: (data['timestamp'] is Timestamp) ? (data['timestamp'] as Timestamp).toDate() : (data['timestamp'] is String ? DateTime.tryParse(data['timestamp']) : null),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'householdId': householdId,
      'name': name,
      'category': category,
      'apiCategories': apiCategories, // Add apiCategories to Firestore
      'imageUrl': imageUrl,
      'qty': qty,
      'expiresText': expiresText,
      'barcode': barcode,
      'quantityUnit': quantityUnit,
      'nutritionFacts': nutritionFacts,
      'nutrition': nutrition,
      'ecoscore': ecoscore,
      'shelfLifeDays': shelfLifeDays,
      'shelfLifeWeeks': shelfLifeWeeks,
      'shelfLifeMonths': shelfLifeMonths,
      'manufacturedDate': manufacturedDate != null ? Timestamp.fromDate(manufacturedDate!) : null,
      'expirationDate': expirationDate != null ? Timestamp.fromDate(expirationDate!) : null,
      'netWeight': netWeight,
      'selected': selected,
      'status': status,
      'consumedAt': consumedAt != null ? Timestamp.fromDate(consumedAt!) : null,
      'wastedAt': wastedAt != null ? Timestamp.fromDate(wastedAt!) : null,
      'deletedAt': deletedAt != null ? Timestamp.fromDate(deletedAt!) : null,
      'notes': notes,
      'storageLocation': storageLocation,
      'price': price,
      'timestamp': timestamp != null ? Timestamp.fromDate(timestamp!) : FieldValue.serverTimestamp(),
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'householdId': householdId,
      'name': name,
      'category': category,
      'apiCategories': apiCategories, // Add apiCategories to JSON
      'imageUrl': imageUrl,
      'qty': qty,
      'expiresText': expiresText,
      'barcode': barcode,
      'quantityUnit': quantityUnit,
      'nutritionFacts': nutritionFacts,
      'nutrition': nutrition,
      'ecoscore': ecoscore,
      'shelfLifeDays': shelfLifeDays,
      'shelfLifeWeeks': shelfLifeWeeks,
      'shelfLifeMonths': shelfLifeMonths,
      'manufacturedDate': manufacturedDate?.toIso8601String(),
      'expirationDate': expirationDate?.toIso8601String(),
      'netWeight': netWeight,
      'selected': selected,
      'status': status,
      'consumedAt': consumedAt?.toIso8601String(),
      'wastedAt': wastedAt?.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
      'notes': notes,
      'storageLocation': storageLocation,
      'price': price,
      'timestamp': timestamp?.toIso8601String(),
    };
  }

  factory PantryItemModel.fromJson(Map<String, dynamic> json) {
    return PantryItemModel(
      id: json['id'],
      householdId: json['householdId'] ?? '',
      name: json['name'] ?? '',
      category: json['category'] ?? 'Uncategorized',
      apiCategories: (json['apiCategories'] as List?)?.map((e) => e.toString()).toList(), // Add apiCategories from JSON
      imageUrl: json['imageUrl'],
      qty: json['qty'] ?? 1,
      expiresText: json['expiresText']?.toString(),
      barcode: json['barcode'],
      quantityUnit: json['quantityUnit'],
      nutritionFacts: json['nutritionFacts'] != null ? Map<String, dynamic>.from(json['nutritionFacts']) : null,
      nutrition: json['nutrition'],
      ecoscore: json['ecoscore'],
      shelfLifeDays: json['shelfLifeDays'],
      shelfLifeWeeks: json['shelfLifeWeeks'],
      shelfLifeMonths: json['shelfLifeMonths'],
      manufacturedDate: (json['manufacturedDate'] is Timestamp) ? (json['manufacturedDate'] as Timestamp).toDate() : (json['manufacturedDate'] != null ? DateTime.tryParse(json['manufacturedDate']) : null),
      expirationDate: (json['expirationDate'] is Timestamp) ? (json['expirationDate'] as Timestamp).toDate() : (json['expirationDate'] != null ? DateTime.tryParse(json['expirationDate']) : null),
      netWeight: json['netWeight'],
      selected: json['selected'] ?? false,
      status: json['status'] ?? 'Available',
      consumedAt: (json['consumedAt'] is Timestamp) ? (json['consumedAt'] as Timestamp).toDate() : (json['consumedAt'] != null ? DateTime.tryParse(json['consumedAt']) : null),
      wastedAt: (json['wastedAt'] is Timestamp) ? (json['wastedAt'] as Timestamp).toDate() : (json['wastedAt'] != null ? DateTime.tryParse(json['wastedAt']) : null),
      deletedAt: (json['deletedAt'] is Timestamp) ? (json['deletedAt'] as Timestamp).toDate() : (json['deletedAt'] != null ? DateTime.tryParse(json['deletedAt']) : null),
      notes: json['notes'],
      storageLocation: json['storageLocation'],
      price: (json['price'] as num?)?.toDouble(),
      timestamp: (json['timestamp'] is Timestamp) ? (json['timestamp'] as Timestamp).toDate() : (json['timestamp'] != null ? DateTime.tryParse(json['timestamp']) : null),
    );
  }

  PantryItemModel copyWith({
    String? id,
    String? householdId,
    String? name,
    String? category,
    List<String>? apiCategories,
    String? imageUrl,
    int? qty,
    String? expiresText,
    String? barcode,
    String? quantityUnit,
    Map<String, dynamic>? nutritionFacts,
    String? nutrition,
    String? ecoscore,
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
    DateTime? timestamp,
  }) {
    return PantryItemModel(
      id: id ?? this.id,
      householdId: householdId ?? this.householdId,
      name: name ?? this.name,
      category: category ?? this.category,
      apiCategories: apiCategories ?? this.apiCategories,
      imageUrl: imageUrl ?? this.imageUrl,
      qty: qty ?? this.qty,
      expiresText: expiresText ?? this.expiresText,
      barcode: barcode ?? this.barcode,
      quantityUnit: quantityUnit ?? this.quantityUnit,
      nutritionFacts: nutritionFacts ?? this.nutritionFacts,
      nutrition: nutrition ?? this.nutrition,
      ecoscore: ecoscore ?? this.ecoscore,
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
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
