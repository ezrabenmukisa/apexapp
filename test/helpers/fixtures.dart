import 'package:app/features/auth/domain/entities/app_user.dart';
import 'package:app/features/auth/domain/entities/auth_identity.dart';
import 'package:app/features/auth/domain/entities/user_role.dart';

const tIdentity = AuthIdentity(uid: 'fb-uid-1', phoneNumber: '+447700900123');

const tOwner = AppUser(
  userId: 'usr_1',
  firstName: 'Sarah',
  lastName: 'Namuli',
  contactEmail: 'sarah@example.com',
  contactPhone: '+447700900123',
  userRole: UserRole.owner,
);

const tManager = AppUser(
  userId: 'usr_2',
  firstName: 'Kato',
  lastName: 'Builders',
  contactEmail: 'kato@example.com',
  userRole: UserRole.manager,
);
