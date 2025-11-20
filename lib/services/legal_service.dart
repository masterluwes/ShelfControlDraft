import 'package:cloud_firestore/cloud_firestore.dart';

class LegalService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String> getLegalDocument(String documentId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('legal_documents')
          .doc(documentId)
          .get();

      if (doc.exists) {
        return doc['content'] ?? 'Content not found.';
      } else {
        return 'Document "$documentId" not found in Firestore.';
      }
    } catch (e) {
      print('Error fetching legal document $documentId: $e');
      return 'Error fetching content: $e';
    }
  }
}
