import 'package:app/features/auth/data/repositories/profile_repository_impl.dart';
import 'package:app/features/auth/domain/entities/app_user.dart';
import 'package:app/features/auth/domain/entities/profile_update.dart';
import 'package:app/features/auth/domain/entities/user_role.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/fixtures.dart';
import '../../../../helpers/mocks.dart';

void main() {
  late MockProfileApiDataSource api;
  late MockSessionLocalDataSource local;
  late MockFirebaseAuthDataSource firebase;
  late ProfileRepositoryImpl repository;

  const ownerWithoutRole = AppUser(
    userId: 'usr_1',
    firstName: 'Sarah',
    lastName: 'Namuli',
    contactEmail: 'sarah@example.com',
    contactPhone: '+447700900123',
  );

  setUpAll(() {
    registerFallbackValue(tOwner);
    registerFallbackValue(const ProfileUpdate());
  });

  setUp(() {
    api = MockProfileApiDataSource();
    local = MockSessionLocalDataSource();
    firebase = MockFirebaseAuthDataSource();
    repository = ProfileRepositoryImpl(api, local, firebase);
    when(() => firebase.currentUid).thenReturn('fb-uid-1');
    when(
      () => local.cacheUser(any(), uid: any(named: 'uid')),
    ).thenAnswer((_) async {});
  });

  group('getProfile', () {
    test('returns and caches the API profile', () async {
      when(() => api.getMe()).thenAnswer((_) async => tOwner);
      when(
        () => local.cachedUser(uid: 'fb-uid-1'),
      ).thenAnswer((_) async => null);

      expect(await repository.getProfile(), const Right(tOwner));
      verify(() => local.cacheUser(tOwner, uid: 'fb-uid-1')).called(1);
    });

    test('keeps the locally chosen role when the API omits it', () async {
      when(() => api.getMe()).thenAnswer((_) async => ownerWithoutRole);
      when(
        () => local.cachedUser(uid: 'fb-uid-1'),
      ).thenAnswer((_) async => tOwner);

      final result = await repository.getProfile();

      expect(result.toNullable()?.userRole, UserRole.owner);
    });

    test('falls back to the cached profile when offline', () async {
      when(() => api.getMe()).thenThrow(
        DioException(
          requestOptions: RequestOptions(),
          type: DioExceptionType.connectionError,
        ),
      );
      when(
        () => local.cachedUser(uid: 'fb-uid-1'),
      ).thenAnswer((_) async => tOwner);

      expect(await repository.getProfile(), const Right(tOwner));
    });
  });

  test('updateProfile sends the role and caches the result', () async {
    const update = ProfileUpdate(
      firstName: 'Sarah',
      lastName: 'Namuli',
      contactEmail: 'sarah@example.com',
      userRole: UserRole.owner,
    );
    when(() => api.updateMe(update)).thenAnswer((_) async => ownerWithoutRole);

    final result = await repository.updateProfile(update);

    expect(result.toNullable()?.userRole, UserRole.owner);
    verify(
      () => local.cacheUser(
        any(
          that: isA<AppUser>().having(
            (u) => u.userRole,
            'role',
            UserRole.owner,
          ),
        ),
        uid: 'fb-uid-1',
      ),
    ).called(1);
  });
}
