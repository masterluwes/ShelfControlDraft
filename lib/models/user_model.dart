import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String? nickname; // Optional nickname

  UserModel({
    required this.uid,
    required this.email,
    this.nickname,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data();
    if (data == null || data is! Map<String, dynamic>) {
      // Log an error or throw an exception if data is not in the expected format
      // This will provide a more specific error if the Firestore document data is not a Map.
      throw StateError('User document data for UID ${doc.id} is null or not a Map<String, dynamic>: $data');
    }
    
    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      nickname: data['nickname'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'nickname': nickname,
    };
  }
}
