import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:injectable/injectable.dart';

import '../../domain/entities/auth_identity.dart';
import '../../domain/entities/phone_verification.dart';

/// Thin wrapper around [FirebaseAuth] and [GoogleSignIn]. Always real, even
/// in mock mode.
@lazySingleton
class FirebaseAuthDataSource {
  FirebaseAuthDataSource(this._auth, this._google);

  final FirebaseAuth _auth;
  final GoogleSignIn _google;
  Future<void>? _googleInit;

  static const _codeTimeout = Duration(seconds: 60);

  Stream<AuthIdentity?> identityChanges() =>
      _auth.authStateChanges().map(_toIdentity);

  AuthIdentity? get currentIdentity => _toIdentity(_auth.currentUser);

  String? get currentUid => _auth.currentUser?.uid;

  Future<String?> idToken({bool forceRefresh = false}) async =>
      _auth.currentUser?.getIdToken(forceRefresh);

  /// Wraps the callback-based [FirebaseAuth.verifyPhoneNumber] in a Future
  /// that completes once the code is sent, auto-verified or rejected.
  Future<PhoneVerification> sendPhoneCode(
    String phoneNumber, {
    int? resendToken,
  }) {
    final completer = Completer<PhoneVerification>();
    _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      forceResendingToken: resendToken,
      timeout: _codeTimeout,
      verificationCompleted: (credential) async {
        // Android instant verification / SMS auto-retrieval.
        try {
          await _auth.signInWithCredential(credential);
          if (!completer.isCompleted) {
            completer.complete(const PhoneAutoVerified());
          }
        } catch (e) {
          if (!completer.isCompleted) completer.completeError(e);
        }
      },
      verificationFailed: (e) {
        if (!completer.isCompleted) completer.completeError(e);
      },
      codeSent: (verificationId, token) {
        if (!completer.isCompleted) {
          completer.complete(
            SmsCodeSent(verificationId: verificationId, resendToken: token),
          );
        }
      },
      codeAutoRetrievalTimeout: (_) {},
    );
    return completer.future;
  }

  Future<void> confirmPhoneCode({
    required String verificationId,
    required String smsCode,
  }) => _auth.signInWithCredential(
    PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    ),
  );

  /// Client IDs come from the Firebase config: `default_web_client_id` from
  /// google-services.json on Android, GIDClientID in Info.plist on iOS.
  Future<void> signInWithGoogle() async {
    await (_googleInit ??= _google.initialize());
    final account = await _google.authenticate();
    final idToken = account.authentication.idToken;
    if (idToken == null) {
      throw FirebaseAuthException(
        code: 'missing-id-token',
        message: 'Google did not return an ID token.',
      );
    }
    await _auth.signInWithCredential(
      GoogleAuthProvider.credential(idToken: idToken),
    );
  }

  Future<void> signInWithEmail(String email, String password) =>
      _auth.signInWithEmailAndPassword(email: email, password: password);

  Future<void> signUpWithEmail(String email, String password) =>
      _auth.createUserWithEmailAndPassword(email: email, password: password);

  Future<void> sendPasswordReset(String email) =>
      _auth.sendPasswordResetEmail(email: email);

  Future<void> signOut() async {
    // Forget the Google account so the picker shows again next time.
    if (_googleInit != null) {
      try {
        await _google.signOut();
      } catch (_) {}
    }
    await _auth.signOut();
  }

  static AuthIdentity? _toIdentity(User? user) => user == null
      ? null
      : AuthIdentity(
          uid: user.uid,
          phoneNumber: user.phoneNumber,
          email: user.email,
          displayName: user.displayName,
        );
}
