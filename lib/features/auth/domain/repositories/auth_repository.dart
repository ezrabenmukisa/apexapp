import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/auth_identity.dart';
import '../entities/auth_session.dart';
import '../entities/phone_verification.dart';

abstract interface class AuthRepository {
  /// Emits the Firebase identity on start-up and whenever it changes;
  /// `null` when signed out.
  Stream<AuthIdentity?> identityChanges();

  AuthIdentity? get currentIdentity;

  /// Sends an SMS code to [phoneNumber] (E.164). Pass [resendToken] from a
  /// previous [SmsCodeSent] to resend.
  Future<Either<Failure, PhoneVerification>> sendPhoneCode(
    String phoneNumber, {
    int? resendToken,
  });

  Future<Either<Failure, Unit>> confirmPhoneCode({
    required String verificationId,
    required String smsCode,
  });

  /// Native Google account picker, then Firebase sign-in with the ID token.
  /// Fails with an [AuthFailure] whose code is `cancelled` if the user
  /// dismisses the picker.
  Future<Either<Failure, Unit>> signInWithGoogle();

  Future<Either<Failure, Unit>> signInWithEmail({
    required String email,
    required String password,
  });

  Future<Either<Failure, Unit>> signUpWithEmail({
    required String email,
    required String password,
  });

  Future<Either<Failure, Unit>> sendPasswordReset(String email);

  /// Exchanges the Firebase ID token with the backend (`POST /auth/firebase`).
  /// Falls back to the cached session when the device is offline.
  Future<Either<Failure, AuthSession>> establishSession();

  /// Signs out of Firebase and wipes locally cached user data.
  /// There is no backend call.
  Future<Either<Failure, Unit>> signOut();
}
