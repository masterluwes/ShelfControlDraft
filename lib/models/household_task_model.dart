import 'package:cloud_firestore/cloud_firestore.dart';

class HouseholdTask {
  String id;
  String householdId;
  String assignedToUserId;
  String assignedByUserId; // The owner who assigned the task
  String taskType; // e.g., 'shopping_list', 'check_pantry', 'custom'
  String description;
  String status; // e.g., 'pending', 'done'
  DateTime createdAt;
  DateTime? completedAt;

  HouseholdTask({
    required this.id,
    required this.householdId,
    required this.assignedToUserId,
    required this.assignedByUserId,
    required this.taskType,
    required this.description,
    this.status = 'pending',
    required this.createdAt,
    this.completedAt,
  });

  factory HouseholdTask.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return HouseholdTask(
      id: doc.id,
      householdId: data['householdId'] ?? '',
      assignedToUserId: data['assignedToUserId'] ?? '',
      assignedByUserId: data['assignedByUserId'] ?? '',
      taskType: data['taskType'] ?? 'custom',
      description: data['description'] ?? '',
      status: data['status'] ?? 'pending',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'householdId': householdId,
      'assignedToUserId': assignedToUserId,
      'assignedByUserId': assignedByUserId,
      'taskType': taskType,
      'description': description,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
    };
  }

  HouseholdTask copyWith({
    String? id,
    String? householdId,
    String? assignedToUserId,
    String? assignedByUserId,
    String? taskType,
    String? description,
    String? status,
    DateTime? createdAt,
    DateTime? completedAt,
  }) {
    return HouseholdTask(
      id: id ?? this.id,
      householdId: householdId ?? this.householdId,
      assignedToUserId: assignedToUserId ?? this.assignedToUserId,
      assignedByUserId: assignedByUserId ?? this.assignedByUserId,
      taskType: taskType ?? this.taskType,
      description: description ?? this.description,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}
