import 'package:cloud_firestore/cloud_firestore.dart';

class WasteReportModel {
  final String id;
  final String userId;
  final String householdId;
  final DateTime weekStart;
  final DateTime weekEnd;
  final DateTime generatedAt;
  final int totalWastedItems;
  final double totalWasteCost;
  final String mostWastedCategory;
  final String pdfStoragePath; // URL or path to the PDF in Firebase Storage

  WasteReportModel({
    required this.id,
    required this.userId,
    required this.householdId,
    required this.weekStart,
    required this.weekEnd,
    required this.generatedAt,
    required this.totalWastedItems,
    required this.totalWasteCost,
    required this.mostWastedCategory,
    required this.pdfStoragePath,
  });

  // Factory constructor for creating a new WasteReportModel from a Firestore document
  factory WasteReportModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return WasteReportModel(
      id: doc.id,
      userId: data['userId'] as String,
      householdId: data['householdId'] as String,
      weekStart: (data['weekStart'] as Timestamp).toDate(),
      weekEnd: (data['weekEnd'] as Timestamp).toDate(),
      generatedAt: (data['generatedAt'] as Timestamp).toDate(),
      totalWastedItems: data['totalWastedItems'] as int,
      totalWasteCost: (data['totalWasteCost'] as num).toDouble(),
      mostWastedCategory: data['mostWastedCategory'] as String,
      pdfStoragePath: data['pdfStoragePath'] as String,
    );
  }

  // Method for converting a WasteReportModel to a Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'householdId': householdId,
      'weekStart': Timestamp.fromDate(weekStart),
      'weekEnd': Timestamp.fromDate(weekEnd),
      'generatedAt': Timestamp.fromDate(generatedAt),
      'totalWastedItems': totalWastedItems,
      'totalWasteCost': totalWasteCost,
      'mostWastedCategory': mostWastedCategory,
      'pdfStoragePath': pdfStoragePath,
    };
  }

  // Method for creating a copy of the WasteReportModel with updated values
  WasteReportModel copyWith({
    String? id,
    String? userId,
    String? householdId,
    DateTime? weekStart,
    DateTime? weekEnd,
    DateTime? generatedAt,
    int? totalWastedItems,
    double? totalWasteCost,
    String? mostWastedCategory,
    String? pdfStoragePath,
  }) {
    return WasteReportModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      householdId: householdId ?? this.householdId,
      weekStart: weekStart ?? this.weekStart,
      weekEnd: weekEnd ?? this.weekEnd,
      generatedAt: generatedAt ?? this.generatedAt,
      totalWastedItems: totalWastedItems ?? this.totalWastedItems,
      totalWasteCost: totalWasteCost ?? this.totalWasteCost,
      mostWastedCategory: mostWastedCategory ?? this.mostWastedCategory,
      pdfStoragePath: pdfStoragePath ?? this.pdfStoragePath,
    );
  }
}
