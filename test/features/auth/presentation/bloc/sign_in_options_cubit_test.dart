import 'package:app/core/error/error_mapper.dart';
import 'package:app/core/error/failures.dart';
import 'package:app/core/usecase/usecase.dart';
import 'package:app/features/auth/presentation/bloc/sign_in_options_cubit.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/mocks.dart';

void main() {
  late MockSignInWithGoogle signInWithGoogle;

  setUpAll(() => registerFallbackValue(const NoParams()));
  setUp(() => signInWithGoogle = MockSignInWithGoogle());

  SignInOptionsCubit build() => SignInOptionsCubit(signInWithGoogle);

  const busy = SignInOptionsState(
    status: SignInOptionsStatus.signingInWithGoogle,
  );

  blocTest<SignInOptionsCubit, SignInOptionsState>(
    'Google success → signedIn (AuthBloc navigates)',
    build: build,
    setUp: () => when(
      () => signInWithGoogle(any()),
    ).thenAnswer((_) async => const Right(unit)),
    act: (cubit) => cubit.continueWithGoogle(),
    expect: () => [
      busy,
      const SignInOptionsState(status: SignInOptionsStatus.signedIn),
    ],
  );

  blocTest<SignInOptionsCubit, SignInOptionsState>(
    'dismissing the account picker returns to idle without an error',
    build: build,
    setUp: () => when(() => signInWithGoogle(any())).thenAnswer(
      (_) async =>
          const Left(AuthFailure('cancelled', code: authCancelledCode)),
    ),
    act: (cubit) => cubit.continueWithGoogle(),
    expect: () => [busy, const SignInOptionsState()],
  );

  blocTest<SignInOptionsCubit, SignInOptionsState>(
    'other failures surface their message',
    build: build,
    setUp: () => when(
      () => signInWithGoogle(any()),
    ).thenAnswer((_) async => const Left(NetworkFailure())),
    act: (cubit) => cubit.continueWithGoogle(),
    expect: () => [
      busy,
      SignInOptionsState(error: const NetworkFailure().message),
    ],
  );
}
