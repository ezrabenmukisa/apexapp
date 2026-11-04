import 'package:app/features/auth/data/models/app_user_model.dart';
import 'package:app/features/auth/data/models/auth_session_model.dart';
import 'package:app/features/auth/domain/entities/auth_session.dart';
import 'package:app/features/auth/domain/entities/profile_update.dart';
import 'package:app/features/auth/domain/entities/user_role.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/fixtures.dart';

void main() {
  group('AppUserModel', () {
    test('parses GET /users/me', () {
      final user = AppUserModel.fromJson({
        'user_id': 'usr_1',
        'first_name': 'Sarah',
        'middle_name': '',
        'last_name': 'Namuli',
        'contact_email': 'sarah@example.com',
        'contact_phone': '+447700900123',
        'user_role': 'OWNER',
      });
      expect(user, tOwner);
      expect(user.middleName, isNull, reason: 'blank optional → null');
    });

    test('tolerates a missing user_role (field not yet in the API)', () {
      final user = AppUserModel.fromJson({
        'user_id': 'usr_1',
        'first_name': 'Sarah',
        'last_name': 'Namuli',
        'contact_email': 'sarah@example.com',
      });
      expect(user.userRole, isNull);
    });

    test('round-trips through toJson', () {
      expect(AppUserModel.fromJson(AppUserModel.toJson(tManager)), tManager);
    });
  });

  test('UserRole accepts PROJECT_MANAGER as manager', () {
    expect(UserRole.fromApi('PROJECT_MANAGER'), UserRole.manager);
    expect(UserRole.fromApi('MANAGER'), UserRole.manager);
    expect(UserRole.fromApi('OWNER'), UserRole.owner);
    expect(UserRole.fromApi(null), isNull);
  });

  test('profileUpdateToJson only sends fields that are set', () {
    expect(
      profileUpdateToJson(
        const ProfileUpdate(firstName: 'Sarah', contactPhone: '+256700000001'),
      ),
      {'first_name': 'Sarah', 'contact_phone': '+256700000001'},
    );
  });

  test('profileUpdateToJson never sends user_role (not in the live API)', () {
    expect(
      profileUpdateToJson(
        const ProfileUpdate(firstName: 'Sarah', userRole: UserRole.owner),
      ),
      {'first_name': 'Sarah'},
    );
  });

  test('parses the live API profile (uuid, null email, no role)', () {
    final user = AppUserModel.fromJson({
      'user_id': 'c0ffee00-0000-4000-8000-000000000001',
      'first_name': 'Kato',
      'middle_name': null,
      'last_name': 'Builders',
      'contact_email': null,
      'contact_phone': '+256700000001',
    });
    expect(user.contactEmail, '');
    expect(user.middleName, isNull);
    expect(user.userRole, isNull);
  });

  test('AuthSessionModel parses POST /auth/firebase', () {
    expect(
      AuthSessionModel.fromJson({
        'user_id': 'usr_1',
        'profile_complete': false,
      }),
      const AuthSession(userId: 'usr_1', profileComplete: false),
    );
  });
}
