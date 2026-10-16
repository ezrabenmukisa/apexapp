import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:injectable/injectable.dart';

import '../../domain/entities/auth_identity.dart';
import '../../domain/entities/phone_verification.dart';

/// Thin wrapper around [FirebaseAuth]. Always real, even in mock mode.
@lazySingleton
class FirebaseAuthDataSource {
  const FirebaseAuthDataSource(this._auth);

  final FirebaseAuth _auth;

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

  Future<void> signInWithEmail(String email, String password) =>
      _auth.signInWithEmailAndPassword(email: email, password: password);

  Future<void> signUpWithEmail(String email, String password) =>
      _auth.createUserWithEmailAndPassword(email: email, password: password);

  Future<void> sendPasswordReset(String email) =>
      _auth.sendPasswordResetEmail(email: email);

  Future<void> signOut() => _auth.signOut();

  static AuthIdentity? _toIdentity(User? user) => user == null
      ? null
      : AuthIdentity(
          uid: user.uid,
          phoneNumber: user.phoneNumber,
          email: user.email,
        );
}
