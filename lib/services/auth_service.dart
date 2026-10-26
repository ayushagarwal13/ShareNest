import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  
  Future<UserCredential> signUpWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final user = credential.user;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-not-created',
        message: 'Account creation failed. Please try again.',
      );
    }

    final trimmedName = name.trim();
    if (trimmedName.isNotEmpty) {
      await user.updateDisplayName(trimmedName);
    }

    await user.sendEmailVerification();

    return credential;
  }


  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> sendPasswordResetEmail(String email) {
    return _auth.sendPasswordResetEmail(email: email.trim());
  }

  
Future<UserCredential> signInWithGoogle() async {
    if (kIsWeb) {
      final provider = GoogleAuthProvider();
      return await _auth.signInWithPopup(provider);
    }

    await _googleSignIn.initialize();

    final googleUser = await _googleSignIn.authenticate();
    final googleAuth = googleUser.authentication;
    final idToken = googleAuth.idToken;

    if (idToken == null) {
      throw FirebaseAuthException(
        code: 'google-sign-in-no-id-token',
        message: 'Google Sign-In did not return an ID token.',
      );
    }

    final credential = GoogleAuthProvider.credential(idToken: idToken);

    return _auth.signInWithCredential(credential);
  }


    Future<void> reauthenticateCurrentUser({String? password}) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message: 'No signed-in user was found.',
      );
    }

    final providers = user.providerData.map((p) => p.providerId).toSet();

    
if (providers.contains('google.com')) {
      
      if (kIsWeb) {
        final provider = GoogleAuthProvider();
        final googleCredential = await _auth.signInWithPopup(provider);

        final credential = googleCredential.credential;

        if (credential == null) {
          throw FirebaseAuthException(
            code: 'google-reauthentication-failed',
            message: 'Google reauthentication failed. Please try again.',
          );
        }

        await user.reauthenticateWithCredential(credential);
        return;
      }


      await _googleSignIn.initialize();

      final googleUser = await _googleSignIn.authenticate();
      final googleAuth = googleUser.authentication;
      final idToken = googleAuth.idToken;

      if (idToken == null) {
        throw FirebaseAuthException(
          code: 'google-sign-in-no-id-token',
          message: 'Google reauthentication failed. Please try again.',
        );
      }

      final googleCredential = GoogleAuthProvider.credential(idToken: idToken);

      await user.reauthenticateWithCredential(googleCredential);
      return;
    }


    if (providers.contains('password')) {
      if (password == null || password.isEmpty) {
        throw FirebaseAuthException(
          code: 'password-required',
          message: 'Enter your password to continue.',
        );
      }

      final email = user.email;
      if (email == null || email.isEmpty) {
        throw FirebaseAuthException(
          code: 'email-unavailable',
          message: 'The account email address is unavailable.',
        );
      }

      final credential = EmailAuthProvider.credential(
        email: email,
        password: password,
      );

      await user.reauthenticateWithCredential(credential);
      return;
    }

    throw FirebaseAuthException(
      code: 'unsupported-provider',
      message: 'Please sign in again before deleting this account.',
    );
  }

  Future<void> deleteCurrentUser() async {
    final user = _auth.currentUser;

    if (user == null) {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message: 'No signed-in user was found.',
      );
    }

    await user.delete();

    try {
      await _googleSignIn.signOut();
    } catch (_) {
      // Firebase account deletion has already completed.
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();

    try {
      await _googleSignIn.signOut();
    } catch (_) {
      // Firebase sign-out has already completed.
    }
  }
}
