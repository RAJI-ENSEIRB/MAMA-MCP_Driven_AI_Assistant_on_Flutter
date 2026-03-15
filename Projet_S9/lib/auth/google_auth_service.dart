import 'package:google_sign_in/google_sign_in.dart';

class GoogleAuthService {
  static final GoogleSignIn googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'https://www.googleapis.com/auth/contacts.readonly',
      'https://www.googleapis.com/auth/userinfo.profile',
    ],
  );

  static Future<GoogleSignInAccount?> signIn() async {
    try {
      return await googleSignIn.signIn();
    } catch (e) {
      print("Google sign-in error: $e");
      return null;
    }
  }

  static Future<GoogleSignInAccount?> signInSilently() async {
    try {
      return await googleSignIn.signInSilently();
    } catch (e) {
      print("Silent sign-in error: $e");
      return null;
    }
  }

  static Future<void> signOut() async {
    await googleSignIn.signOut();
  }

  static GoogleSignInAccount? get currentUser => googleSignIn.currentUser;

  /// Récupère le token People API
  static Future<String?> getAccessToken() async {
    final user = googleSignIn.currentUser;
    if (user == null) return null;

    final auth = await user.authentication;
    return auth.accessToken;
  }
}
