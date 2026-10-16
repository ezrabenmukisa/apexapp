import '../../domain/entities/auth_session.dart';

/// JSON mapping for the `POST /auth/firebase` response.
abstract final class AuthSessionModel {
  static AuthSession fromJson(Map<String, dynamic> json) => AuthSession(
    userId: json['user_id'] as String,
    profileComplete: json['profile_complete'] as bool? ?? false,
  );

  static Map<String, dynamic> toJson(AuthSession session) => {
    'user_id': session.userId,
    'profile_complete': session.profileComplete,
  };
}
