import 'package:equatable/equatable.dart';

import 'user_role.dart';

/// The signed-in user's Apex profile (`GET /users/me`).
class AppUser extends Equatable {
  const AppUser({
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.contactEmail,
    this.middleName,
    this.contactPhone,
    this.userRole,
  });

  final String userId;
  final String firstName;
  final String? middleName;
  final String lastName;
  final String contactEmail;
  final String? contactPhone;

  /// Null until chosen on Complete Profile.
  final UserRole? userRole;

  AppUser copyWith({UserRole? userRole}) => AppUser(
    userId: userId,
    firstName: firstName,
    middleName: middleName,
    lastName: lastName,
    contactEmail: contactEmail,
    contactPhone: contactPhone,
    userRole: userRole ?? this.userRole,
  );

  String get fullName => [
    firstName,
    if (middleName?.isNotEmpty ?? false) middleName,
    lastName,
  ].join(' ');

  String get initials =>
      '${firstName.isEmpty ? '' : firstName[0]}'
              '${lastName.isEmpty ? '' : lastName[0]}'
          .toUpperCase();

  @override
  List<Object?> get props => [
    userId,
    firstName,
    middleName,
    lastName,
    contactEmail,
    contactPhone,
    userRole,
  ];
}
