import 'package:app/features/auth/data/datasources/role_local_data_source.dart';
import 'package:app/features/auth/data/repositories/profile_repository_impl.dart';
import 'package:app/features/auth/domain/entities/app_user.dart';
import 'package:app/features/auth/domain/entities/profile_update.dart';
import 'package:app/features/auth/domain/entities/user_role.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../helpers/mocks.dart';

void main() {
  late MockProfileApiDataSource api;
  late MockSessionLocalDataSource local;
  late MockFirebaseAuthDataSource firebase;
  late RoleLocalDataSource roles;
  late ProfileRepositoryImpl repository;

  /// What the live `/users/me` returns: no `user_role`.
  const fromApi = AppUser(
    userId: 'c0ffee00-0000-4000-8000-000000000001',
    firstName: 'Sarah',
    lastName: 'Namuli',
    contactEmail: 'sarah@example.com',
    contactPhone: '+447700900123',
  );

  setUpAll(() {
    registerFallbackValue(fromApi);
    registerFallbackValue(const ProfileUpdate());
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    roles = RoleLocalDataSource(await SharedPreferences.getInstance());
    api = MockProfileApiDataSource();
    local = MockSessionLocalDataSource();
    firebase = MockFirebaseAuthDataSource();
    repository = ProfileRepositoryImpl(api, local, roles, firebase);
    when(() => firebase.currentUid).thenReturn('fb-uid-1');
    when(
      () => local.cacheUser(any(), uid: any(named: 'uid')),
    ).thenAnswer((_) async {});
  });

  group('getProfile', () {
    test(
      'returns the API profile with the role remembered on this phone',
      () async {
        await roles.write('fb-uid-1', UserRole.owner);
        when(() => api.getMe()).thenAnswer((_) async => fromApi);

        final user = (await repository.getProfile()).toNullable()!;

        expect(user.userId, fromApi.userId);
        expect(user.userRole, UserRole.owner);
        verify(() => local.cacheUser(user, uid: 'fb-uid-1')).called(1);
      },
    );

    test(
      'role is unknown on a new phone (Complete Profile asks once)',
      () async {
        when(() => api.getMe()).thenAnswer((_) async => fromApi);

        final user = (await repository.getProfile()).toNullable()!;

        expect(user.userRole, isNull);
      },
    );

    test('roles are per Firebase account', () async {
      await roles.write('someone-else', UserRole.manager);
      when(() => api.getMe()).thenAnswer((_) async => fromApi);

      expect((await repository.getProfile()).toNullable()!.userRole, isNull);
    });

    test('falls back to the cached profile when offline', () async {
      await roles.write('fb-uid-1', UserRole.manager);
      when(() => api.getMe()).thenThrow(
        DioException(
          requestOptions: RequestOptions(),
          type: DioExceptionType.connectionError,
        ),
      );
      when(
        () => local.cachedUser(uid: 'fb-uid-1'),
      ).thenAnswer((_) async => fromApi);

      final user = (await repository.getProfile()).toNullable()!;

      expect(user.firstName, 'Sarah');
      expect(user.userRole, UserRole.manager);
    });
  });

  test('updateProfile remembers the chosen role for next sign-in', () async {
    const update = ProfileUpdate(
      firstName: 'Sarah',
      lastName: 'Namuli',
      contactEmail: 'sarah@example.com',
      userRole: UserRole.owner,
    );
    when(() => api.updateMe(update)).thenAnswer((_) async => fromApi);

    final result = await repository.updateProfile(update);

    expect(result.toNullable()?.userRole, UserRole.owner);
    // Survives sign-out: the role store isn't part of the session cache.
    expect(roles.read('fb-uid-1'), UserRole.owner);
  });

  test('API failure does not remember the role', () async {
    when(() => api.updateMe(any())).thenThrow(
      DioException(
        requestOptions: RequestOptions(),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(),
          statusCode: 422,
          data: {
            'detail': [
              {'msg': 'value is not a valid email address'},
            ],
          },
        ),
      ),
    );

    final result = await repository.updateProfile(
      const ProfileUpdate(contactEmail: 'nope', userRole: UserRole.owner),
    );

    expect(
      result.getLeft().toNullable()?.message,
      'value is not a valid email address',
    );
    expect(roles.read('fb-uid-1'), isNull);
  });
}
