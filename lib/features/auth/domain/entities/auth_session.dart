import 'package:equatable/equatable.dart';

/// Result of `POST /auth/firebase`, which serves both sign-up and sign-in.
class AuthSession extends Equatable {
  const AuthSession({required this.userId, required this.profileComplete});

  final String userId;

  /// When false the app must force-route to Complete Profile.
  final bool profileComplete;

  @override
  List<Object?> get props => [userId, profileComplete];
}
