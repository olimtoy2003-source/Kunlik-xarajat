import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn();

  static User? getCurrentUser() {
    return _auth.currentUser;
  }

  static String? getUserId() {
    return _auth.currentUser?.uid;
  }

  static Future<UserCredential?> signInSilently() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signInSilently();
      
      if (googleUser != null) {
        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        return await _auth.signInWithCredential(credential);
      }
      return null;
    } catch (e) {
      print('Silent sign-in xatolik: $e');
      return null;
    }
  }

  static Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        return null;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      return await _auth.signInWithCredential(credential);
    } catch (e) {
      print('Google orqali kirishda xatolik: $e');
      return null;
    }
  }

  static Future<void> signOut() async {
    try {
      // Faqat Firebase va Google Sign-In'dan chiqamiz
      await _auth.signOut();
      await _googleSignIn.signOut();
      // disconnect() ISHLATMAYMIZ - xatolik beradi!
    } catch (e) {
      // Xatolikni e'tiborsiz qoldiramiz - ilova ishlashda davom etadi
      print('Chiqishda xatolik: $e');
    }
  }

  static Stream<User?> authStateChanges() {
    return _auth.authStateChanges();
  }
}