import '../../domain/entities/app_user.dart';
import '../../domain/entities/profile_update.dart';
import '../../domain/entities/user_role.dart';

/// JSON mapping for the `/users/me` profile.
abstract final class AppUserModel {
  static AppUser fromJson(Map<String, dynamic> json) => AppUser(
    userId: json['user_id'] as String,
    firstName: json['first_name'] as String? ?? '',
    middleName: _blankToNull(json['middle_name']),
    lastName: json['last_name'] as String? ?? '',
    contactEmail: json['contact_email'] as String? ?? '',
    contactPhone: _blankToNull(json['contact_phone']),
    userRole: UserRole.fromApi(json['user_role']),
  );

  static Map<String, dynamic> toJson(AppUser user) => {
    'user_id': user.userId,
    'first_name': user.firstName,
    'middle_name': user.middleName,
    'last_name': user.lastName,
    'contact_email': user.contactEmail,
    'contact_phone': user.contactPhone,
    'user_role': user.userRole?.apiValue,
  };

  static String? _blankToNull(Object? value) =>
      value is String && value.trim().isNotEmpty ? value : null;
}

/// Request body for `PATCH /users/me`; only fields that are set are sent.
///
/// `user_role` is not part of the live API, so it is never sent; the role is
/// kept on the phone (`RoleLocalDataSource`).
Map<String, dynamic> profileUpdateToJson(ProfileUpdate update) => {
  'first_name': ?update.firstName,
  'middle_name': ?update.middleName,
  'last_name': ?update.lastName,
  'contact_email': ?update.contactEmail,
  'contact_phone': ?update.contactPhone,
};
