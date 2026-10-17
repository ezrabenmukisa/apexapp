import 'package:app/core/error/failures.dart';
import 'package:app/features/auth/domain/entities/phone_verification.dart';
import 'package:app/features/auth/presentation/bloc/phone_auth_cubit.dart';
import 'package:app/features/auth/presentation/utils/country.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/mocks.dart';

void main() {
  late MockSendPhoneCode sendCode;
  late MockConfirmPhoneCode confirmCode;

  setUpAll(() {
    registerFallbackValue((phoneNumber: '', resendToken: null));
    registerFallbackValue((verificationId: '', smsCode: ''));
  });

  setUp(() {
    sendCode = MockSendPhoneCode();
    confirmCode = MockConfirmPhoneCode();
  });

  PhoneAuthCubit build() => PhoneAuthCubit(sendCode, confirmCode);

  group('PhoneAuthState.e164', () {
    test('drops the trunk 0 and spaces', () {
      const state = PhoneAuthState(
        country: Country.uganda,
        nationalNumber: '0772 123 456',
      );
      expect(state.e164, '+256772123456');
    });

    test('rejects numbers that are too short', () {
      const state = PhoneAuthState(
        country: Country.uganda,
        nationalNumber: '12',
      );
      expect(state.canSendCode, isFalse);
    });
  });

  blocTest<PhoneAuthCubit, PhoneAuthState>(
    'sending a code stores the verification id and starts the resend timer',
    build: build,
    setUp: () => when(() => sendCode(any())).thenAnswer(
      (_) async =>
          const Right(SmsCodeSent(verificationId: 'v1', resendToken: 7)),
    ),
    act: (cubit) => cubit
      ..numberChanged('772 123 456')
      ..sendCode(),
    skip: 1,
    expect: () => [
      isA<PhoneAuthState>().having(
        (s) => s.status,
        'status',
        PhoneAuthStatus.sendingCode,
      ),
      isA<PhoneAuthState>()
          .having((s) => s.verificationId, 'verificationId', 'v1')
          .having((s) => s.sentTo, 'sentTo', '+256772123456'),
      isA<PhoneAuthState>().having(
        (s) => s.resendIn,
        'resendIn',
        PhoneAuthCubit.resendCooldown,
      ),
    ],
    verify: (_) => verify(
      () => sendCode((phoneNumber: '+256772123456', resendToken: null)),
    ).called(1),
  );

  blocTest<PhoneAuthCubit, PhoneAuthState>(
    'a send failure shows the message and returns to number entry',
    build: build,
    setUp: () => when(() => sendCode(any())).thenAnswer(
      (_) async =>
          const Left(AuthFailure('That phone number doesn\'t look right.')),
    ),
    act: (cubit) => cubit
      ..numberChanged('772 123 456')
      ..sendCode(),
    skip: 2,
    expect: () => [
      isA<PhoneAuthState>()
          .having((s) => s.status, 'status', PhoneAuthStatus.enteringNumber)
          .having((s) => s.error, 'error', contains('phone number')),
    ],
  );

  blocTest<PhoneAuthCubit, PhoneAuthState>(
    'a wrong code keeps the user on the code step with an error',
    build: build,
    seed: () => const PhoneAuthState(
      country: Country.uganda,
      nationalNumber: '772123456',
      status: PhoneAuthStatus.codeSent,
      verificationId: 'v1',
      sentTo: '+256772123456',
    ),
    setUp: () => when(() => confirmCode(any())).thenAnswer(
      (_) async => const Left(AuthFailure('That code is incorrect.')),
    ),
    act: (cubit) => cubit.verify('123456'),
    expect: () => [
      isA<PhoneAuthState>().having(
        (s) => s.status,
        'status',
        PhoneAuthStatus.verifying,
      ),
      isA<PhoneAuthState>()
          .having((s) => s.status, 'status', PhoneAuthStatus.codeSent)
          .having((s) => s.error, 'error', 'That code is incorrect.'),
    ],
  );

  blocTest<PhoneAuthCubit, PhoneAuthState>(
    'a correct code marks the flow verified',
    build: build,
    seed: () => const PhoneAuthState(
      country: Country.uganda,
      status: PhoneAuthStatus.codeSent,
      verificationId: 'v1',
    ),
    setUp: () => when(
      () => confirmCode(any()),
    ).thenAnswer((_) async => const Right(unit)),
    act: (cubit) => cubit.verify('123456'),
    expect: () => [
      isA<PhoneAuthState>().having(
        (s) => s.status,
        's',
        PhoneAuthStatus.verifying,
      ),
      isA<PhoneAuthState>().having(
        (s) => s.status,
        's',
        PhoneAuthStatus.verified,
      ),
    ],
    verify: (_) => verify(
      () => confirmCode((verificationId: 'v1', smsCode: '123456')),
    ).called(1),
  );
}
