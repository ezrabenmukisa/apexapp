import 'package:equatable/equatable.dart';

/// A recoverable error surfaced from the data layer to the domain and UI.
///
/// Repositories never throw; they return `Either<Failure, T>`.
sealed class Failure extends Equatable {
  const Failure(this.message);

  /// Human-readable message, safe to show in the UI.
  final String message;

  @override
  List<Object?> get props => [message];
}

/// The API responded with an error status.
final class ServerFailure extends Failure {
  const ServerFailure(super.message, {this.statusCode});

  final int? statusCode;

  @override
  List<Object?> get props => [message, statusCode];
}

/// The device is offline or the server could not be reached.
final class NetworkFailure extends Failure {
  const NetworkFailure([
    super.message = 'No connection. Check your signal and try again.',
  ]);
}

/// The request was rejected because the session is missing or expired.
final class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure([
    super.message = 'Your session has expired. Please sign in again.',
  ]);
}

/// Firebase Authentication rejected the sign-in attempt.
final class AuthFailure extends Failure {
  const AuthFailure(super.message, {this.code});

  final String? code;

  @override
  List<Object?> get props => [message, code];
}

/// Reading or writing local storage failed.
final class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Could not read saved data.']);
}

/// Anything not covered above.
final class UnexpectedFailure extends Failure {
  const UnexpectedFailure([
    super.message = 'Something went wrong. Please try again.',
  ]);
}
