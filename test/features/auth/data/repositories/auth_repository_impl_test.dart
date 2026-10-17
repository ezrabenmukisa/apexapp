import 'package:app/core/error/failures.dart';
import 'package:app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:app/features/auth/domain/entities/auth_session.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/fixtures.dart';
import '../../../../helpers/mocks.dart';

void main() {
  late MockFirebaseAuthDataSource firebase;
  late MockAuthApiDataSource api;
  late MockSessionLocalDataSource local;
  late AuthRepositoryImpl repository;

  setUp(() {
    firebase = MockFirebaseAuthDataSource();
    api = MockAuthApiDataSource();
    local = MockSessionLocalDataSource();
    repository = AuthRepositoryImpl(firebase, api, local);
    when(() => firebase.currentUid).thenReturn('fb-uid-1');
    when(() => firebase.idToken()).thenAnswer((_) async => 'id-token');
  });

  group('establishSession', () {
    test('exchanges the Firebase ID token with the backend', () async {
      const session = AuthSession(userId: 'usr_1', profileComplete: false);
      when(
        () => api.exchangeToken('id-token'),
      ).thenAnswer((_) async => session);

      expect(await repository.establishSession(), const Right(session));
    });

    test('is unauthorized without a Firebase user', () async {
      when(() => firebase.currentUid).thenReturn(null);

      final result = await repository.establishSession();

      expect(result.getLeft().toNullable(), isA<UnauthorizedFailure>());
      verifyNever(() => api.exchangeToken(any()));
    });

    test('offline with a cached profile reopens the session', () async {
      when(() => api.exchangeToken(any())).thenThrow(
        DioException(
          requestOptions: RequestOptions(),
          type: DioExceptionType.connectionError,
        ),
      );
      when(
        () => local.cachedUser(uid: 'fb-uid-1'),
      ).thenAnswer((_) async => tOwner);

      expect(
        await repository.establishSession(),
        const Right(AuthSession(userId: 'usr_1', profileComplete: true)),
      );
    });

    test('offline without a cache surfaces NetworkFailure', () async {
      when(() => api.exchangeToken(any())).thenThrow(
        DioException(
          requestOptions: RequestOptions(),
          type: DioExceptionType.connectionTimeout,
        ),
      );
      when(
        () => local.cachedUser(uid: any(named: 'uid')),
      ).thenAnswer((_) async => null);

      final result = await repository.establishSession();

      expect(result.getLeft().toNullable(), isA<NetworkFailure>());
    });
  });

  test('signOut clears the local cache and Firebase session', () async {
    when(() => local.clear()).thenAnswer((_) async {});
    when(() => firebase.signOut()).thenAnswer((_) async {});

    expect(await repository.signOut(), const Right(unit));
    verifyInOrder([() => local.clear(), () => firebase.signOut()]);
  });
}
