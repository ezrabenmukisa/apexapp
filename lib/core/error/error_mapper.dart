import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'exceptions.dart';
import 'failures.dart';

/// Converts anything thrown in the data layer into a [Failure].
Failure mapErrorToFailure(Object error) => switch (error) {
  Failure() => error,
  DioException() => _fromDio(error),
  FirebaseAuthException() => mapFirebaseAuthError(error),
  GoogleSignInException() => _fromGoogle(error),
  ServerException(:final message, :final statusCode) => ServerFailure(
    message,
    statusCode: statusCode,
  ),
  CacheException(:final message) => CacheFailure(message),
  _ => const UnexpectedFailure(),
};

Failure _fromDio(DioException e) {
  switch (e.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.connectionError:
      return const NetworkFailure();
    case DioExceptionType.badResponse:
      final status = e.response?.statusCode;
      if (status == 401) return const UnauthorizedFailure();
      return ServerFailure(
        _messageFromBody(e.response?.data) ??
            'The server could not complete the request.',
        statusCode: status,
      );
    default:
      return const UnexpectedFailure();
  }
}

/// FastAPI returns `{"detail": "..."}` or `{"detail": [{"msg": "..."}]}`;
/// our own endpoints use `{"message": "..."}`.
String? _messageFromBody(Object? data) {
  if (data is! Map) return null;
  final detail = data['detail'] ?? data['message'];
  return switch (detail) {
    String() => detail,
    [{'msg': final String msg}, ...] => msg,
    _ => null,
  };
}

/// Code of the [AuthFailure] returned when the user dismisses a sign-in UI.
const authCancelledCode = 'cancelled';

AuthFailure _fromGoogle(GoogleSignInException e) => switch (e.code) {
  GoogleSignInExceptionCode.canceled || GoogleSignInExceptionCode.interrupted =>
    const AuthFailure('Google sign-in was cancelled.', code: authCancelledCode),
  GoogleSignInExceptionCode.clientConfigurationError ||
  GoogleSignInExceptionCode.providerConfigurationError => const AuthFailure(
    'Google sign-in isn\'t set up for this app yet. Use phone or email.',
    code: 'google-not-configured',
  ),
  _ => AuthFailure(
    e.description ?? 'Google sign-in failed. Please try again.',
    code: 'google-${e.code.name}',
  ),
};

AuthFailure mapFirebaseAuthError(FirebaseAuthException e) {
  final message = switch (e.code) {
    'invalid-phone-number' => 'That phone number doesn\'t look right.',
    'invalid-verification-code' =>
      'That code is incorrect. Check the SMS and try again.',
    'session-expired' ||
    'code-expired' => 'That code has expired. Request a new one.',
    'too-many-requests' =>
      'Too many attempts. Wait a few minutes and try again.',
    'quota-exceeded' =>
      'SMS limit reached. Try again later or use email instead.',
    'invalid-email' => 'That email address doesn\'t look right.',
    'user-disabled' => 'This account has been disabled.',
    'user-not-found' ||
    'wrong-password' ||
    'invalid-credential' => 'Email or password is incorrect.',
    'email-already-in-use' =>
      'An account already exists for that email. Log in instead.',
    'weak-password' => 'Choose a password with at least 6 characters.',
    'account-exists-with-different-credential' =>
      'This email already signs in another way. Use that method instead.',
    'network-request-failed' =>
      'No connection. Check your signal and try again.',
    _ => e.message ?? 'Sign-in failed. Please try again.',
  };
  return AuthFailure(message, code: e.code);
}
