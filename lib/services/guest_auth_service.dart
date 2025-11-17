import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GuestAuthService {
  static const String _guestUidKey = 'guest_uid';

  static Future<void> saveGuestUid(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_guestUidKey, uid);
  }

  static Future<String?> getGuestUid() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_guestUidKey);
  }

  static Future<void> clearGuestUid() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_guestUidKey);
  }

  static Future<User?> reauthenticateGuest() async {
    String? guestUid = await getGuestUid();
    if (guestUid != null) {
      try {
        // Attempt to sign in anonymously. Firebase will re-use the existing anonymous user if available.
        UserCredential userCredential = await FirebaseAuth.instance.signInAnonymously();
        if (userCredential.user?.uid == guestUid) {
          return userCredential.user;
        } else {
          // This might happen if the anonymous user was deleted or a new one was created.
          // In this case, clear the stored UID and return null.
          await clearGuestUid();
          return null;
        }
      } catch (e) {
        print("Error reauthenticating guest: $e");
        await clearGuestUid(); // Clear on error to avoid infinite loops
        return null;
      }
    }
    return null;
  }
}
