import 'dart:async';

import 'package:app/core/error/failures.dart';
import 'package:app/core/usecase/usecase.dart';
import 'package:app/features/auth/domain/entities/auth_identity.dart';
import 'package:app/features/auth/domain/entities/auth_session.dart';
import 'package:app/features/auth/domain/entities/user_role.dart';
import 'package:app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/fixtures.dart';
import '../../../../helpers/mocks.dart';

void main() {
  late MockWatchAuthIdentity watchIdentity;
  late MockEstablishSession establishSession;
  late MockGetProfile getProfile;
  late MockSignOut signOut;
  late StreamController<AuthIdentity?> identities;

  setUpAll(() => registerFallbackValue(const NoParams()));

  setUp(() {
    watchIdentity = MockWatchAuthIdentity();
    establishSession = MockEstablishSession();
    getProfile = MockGetProfile();
    signOut = MockSignOut();
    identities = StreamController<AuthIdentity?>();
    when(() => watchIdentity()).thenAnswer((_) => identities.stream);
  });

  // Not awaited: close() never completes on a stream nobody listened to.
  tearDown(() {
    identities.close();
  });

  AuthBloc build() =>
      AuthBloc(watchIdentity, establishSession, getProfile, signOut);

  void sessionReturns(Either<Failure, AuthSession> result) =>
      when(() => establishSession(any())).thenAnswer((_) async => result);

  const signedOut = AuthState.unauthenticated();

  blocTest<AuthBloc, AuthState>(
    'no Firebase user → unauthenticated',
    build: build,
    act: (bloc) {
      bloc.add(const AuthSubscriptionRequested());
      identities.add(null);
    },
    expect: () => [signedOut],
  );

  blocTest<AuthBloc, AuthState>(
    'profile_complete false → needsProfile (onboarding guard)',
    build: build,
    setUp: () => sessionReturns(
      const Right(AuthSession(userId: 'usr_1', profileComplete: false)),
    ),
    act: (bloc) {
      bloc.add(const AuthSubscriptionRequested());
      identities.add(tIdentity);
    },
    expect: () => [signedOut.toNeedsProfile(tIdentity)],
    verify: (_) => verifyNever(() => getProfile(any())),
  );

  blocTest<AuthBloc, AuthState>(
    'complete profile → loads /users/me → authenticated',
    build: build,
    setUp: () {
      sessionReturns(
        const Right(AuthSession(userId: 'usr_1', profileComplete: true)),
      );
      when(
        () => getProfile(any()),
      ).thenAnswer((_) async => const Right(tOwner));
    },
    act: (bloc) {
      bloc.add(const AuthSubscriptionRequested());
      identities.add(tIdentity);
    },
    expect: () => [signedOut.toAuthenticated(tIdentity, tOwner)],
  );

  blocTest<AuthBloc, AuthState>(
    'backend failure → sessionError, retry recovers',
    build: build,
    setUp: () => sessionReturns(const Left(NetworkFailure())),
    act: (bloc) async {
      bloc.add(const AuthSubscriptionRequested());
      identities.add(tIdentity);
      await Future<void>.delayed(Duration.zero);
      sessionReturns(
        const Right(AuthSession(userId: 'usr_1', profileComplete: false)),
      );
      bloc.add(const AuthRetryRequested());
    },
    expect: () => [
      signedOut.toSessionError(tIdentity, const NetworkFailure()),
      isA<AuthState>().having((s) => s.status, 'status', AuthStatus.unknown),
      isA<AuthState>().having(
        (s) => s.status,
        'status',
        AuthStatus.needsProfile,
      ),
    ],
  );

  blocTest<AuthBloc, AuthState>(
    'role hint survives into needsProfile',
    build: build,
    setUp: () => sessionReturns(
      const Right(AuthSession(userId: 'usr_1', profileComplete: false)),
    ),
    act: (bloc) async {
      bloc
        ..add(const AuthSubscriptionRequested())
        ..add(const AuthRoleHintSelected(UserRole.manager));
      await Future<void>.delayed(Duration.zero);
      identities.add(tIdentity);
    },
    skip: 1,
    expect: () => [
      isA<AuthState>()
          .having((s) => s.status, 'status', AuthStatus.needsProfile)
          .having((s) => s.roleHint, 'roleHint', UserRole.manager),
    ],
  );

  blocTest<AuthBloc, AuthState>(
    'AuthProfileCompleted → authenticated with the saved user',
    build: build,
    seed: () => signedOut.toNeedsProfile(tIdentity),
    act: (bloc) => bloc.add(const AuthProfileCompleted(tManager)),
    expect: () => [signedOut.toAuthenticated(tIdentity, tManager)],
  );

  blocTest<AuthBloc, AuthState>(
    'sign out delegates to the use case',
    build: build,
    setUp: () =>
        when(() => signOut(any())).thenAnswer((_) async => const Right(unit)),
    seed: () => signedOut.toAuthenticated(tIdentity, tOwner),
    act: (bloc) => bloc.add(const AuthSignOutRequested()),
    expect: () => <AuthState>[],
    verify: (_) => verify(() => signOut(any())).called(1),
  );
}
