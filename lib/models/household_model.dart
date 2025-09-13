import 'package:cloud_firestore/cloud_firestore.dart';

class Household {
  String id;
  String name;
  String ownerId;
  List<String> members;
  String joinCode;
  bool isPersonal;

  Household({
    required this.id,
    required this.name,
    required this.ownerId,
    required this.members,
    required this.joinCode,
    this.isPersonal = false,
  });

  factory Household.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return Household(
      id: doc.id,
      name: data['name'] ?? '',
      ownerId: data['ownerId'] ?? '',
      members: List<String>.from(data['members'] ?? []),
      joinCode: data['joinCode'] ?? '',
      isPersonal: data['isPersonal'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'ownerId': ownerId,
      'members': members,
      'joinCode': joinCode,
      'isPersonal': isPersonal,
      'timestamp': FieldValue.serverTimestamp(),
    };
  }
}
