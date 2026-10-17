import 'package:equatable/equatable.dart';

import 'user_role.dart';

/// Editable profile fields for `PATCH /users/me`. Null means "leave as is".
class ProfileUpdate extends Equatable {
  const ProfileUpdate({
    this.firstName,
    this.middleName,
    this.lastName,
    this.contactEmail,
    this.contactPhone,
    this.userRole,
  });

  final String? firstName;
  final String? middleName;
  final String? lastName;
  final String? contactEmail;
  final String? contactPhone;
  final UserRole? userRole;

  @override
  List<Object?> get props => [
    firstName,
    middleName,
    lastName,
    contactEmail,
    contactPhone,
    userRole,
  ];
}
