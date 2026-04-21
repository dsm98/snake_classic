import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import 'analytics_service.dart';

class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._();
  factory AuthService() => _instance;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  User? _user;

  AuthService._() {
    _auth.authStateChanges().listen((User? user) {
      _user = user;
      notifyListeners();
    });
  }

  User? get currentUser => _user;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  bool get isSignedIn => _user != null;

  /// Signs in using Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // Player cancelled

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Once signed in, return the UserCredential
      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      AnalyticsService().logUserLogin('google');
      // No need to notifyListeners() here, authStateChanges listener handles it
      return userCredential;
    } on FirebaseAuthException catch (e) {
      debugPrint('FireBase Auth Error: ${e.code} - ${e.message}');
      return null;
    } catch (e) {
      debugPrint('Unexpected error signing in with Google: $e');
      return null;
    }
  }

  /// Signs out
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
    // No need to notifyListeners() here, authStateChanges listener handles it
  }

  /// Returns the current user's display name or 'Unnamed Snake'
  String get playerName => _user?.displayName ?? 'Guest Snake';
  
  /// Returns the current user's unique ID
  String get userId => _user?.uid ?? '';
}
