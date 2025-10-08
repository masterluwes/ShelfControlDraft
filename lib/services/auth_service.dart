import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<UserCredential> signInWithEmailAndPassword(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<UserCredential> createUserWithEmailAndPassword(String email, String password) async {
    UserCredential userCredential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    // Send email verification
    if (userCredential.user != null && !userCredential.user!.emailVerified) {
      await userCredential.user!.sendEmailVerification();
    }
    return userCredential;
  }

  Future<void> sendVerificationEmail() async {
    User? user = _auth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  // Method to check if the current user is a guest
  bool isGuestUser() {
    // For simplicity, let's assume a guest user is someone not logged in via Firebase Auth.
    // In a real application, you might have a more sophisticated way to determine guest status,
    // e.g., a flag in a local storage or a specific user ID.
    return _auth.currentUser == null;
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
