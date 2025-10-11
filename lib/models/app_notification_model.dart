import 'package:cloud_firestore/cloud_firestore.dart';

class AppNotificationModel {
  final String? id;
  final String userId;
  final String householdId;
  final String title;
  final String body;
  final String type; // e.g., 'expired', 'at_risk', 'update', 'recommendation'
  final String? payload; // Optional data to pass when notification is tapped
  final Timestamp createdAt;
  bool isRead;

  AppNotificationModel({
    this.id,
    required this.userId,
    required this.householdId,
    required this.title,
    required this.body,
    required this.type,
    this.payload,
    required this.createdAt,
    this.isRead = false,
  });

  // Factory constructor for creating a new AppNotificationModel object from a Firestore document
  factory AppNotificationModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return AppNotificationModel(
      id: doc.id,
      userId: data['userId'],
      householdId: data['householdId'],
      title: data['title'],
      body: data['body'],
      type: data['type'],
      payload: data['payload'],
      createdAt: data['createdAt'] as Timestamp,
      isRead: data['isRead'] ?? false,
    );
  }

  // Method to convert an AppNotificationModel object into a Firestore-compatible map
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'householdId': householdId,
      'title': title,
      'body': body,
      'type': type,
      'payload': payload,
      'createdAt': createdAt,
      'isRead': isRead,
    };
  }
}
