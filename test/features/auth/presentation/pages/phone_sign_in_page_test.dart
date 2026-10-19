import 'package:app/core/di/injection.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/features/auth/domain/entities/phone_verification.dart';
import 'package:app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:app/features/auth/presentation/bloc/phone_auth_cubit.dart';
import 'package:app/features/auth/presentation/pages/phone_sign_in_page.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pinput/pinput.dart';

import '../../../../helpers/mocks.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

/// Regression: the SMS code boxes (Pinput) must render once a code is sent.
/// They crashed with "No Material widget found" while the app used
/// `package:material_ui/material_ui.dart` and Pinput used `material_ui`.
void main() {
  late MockSendPhoneCode sendCode;
  late MockConfirmPhoneCode confirmCode;
  late MockAuthBloc authBloc;

  setUpAll(() {
    registerFallbackValue((phoneNumber: '', resendToken: null));
    registerFallbackValue((verificationId: '', smsCode: ''));
  });

  setUp(() {
    sendCode = MockSendPhoneCode();
    confirmCode = MockConfirmPhoneCode();
    authBloc = MockAuthBloc();
    when(() => authBloc.state).thenReturn(const AuthState.unauthenticated());
    getIt.registerFactory(() => PhoneAuthCubit(sendCode, confirmCode));
  });

  tearDown(getIt.reset);

  testWidgets('sending a code shows the 6-digit field and verifies', (
    tester,
  ) async {
    when(
      () => sendCode(any()),
    ).thenAnswer((_) async => const Right(SmsCodeSent(verificationId: 'v1')));
    when(() => confirmCode(any())).thenAnswer((_) async => const Right(unit));

    await tester.pumpWidget(
      BlocProvider<AuthBloc>.value(
        value: authBloc,
        child: MaterialApp(
          theme: AppTheme.light,
          home: const PhoneSignInPage(),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), '700000001');
    await tester.pump(); // Rebuild so "Send code" is enabled.
    await tester.tap(find.text('Send code'));
    await tester.pump();
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byType(Pinput), findsOneWidget);
    expect(find.textContaining('Code sent to +'), findsOneWidget);

    await tester.enterText(find.byType(EditableText).last, '123456');
    await tester.pump();

    verify(
      () => confirmCode((verificationId: 'v1', smsCode: '123456')),
    ).called(1);
    // Stop the resend countdown timer.
    await tester.pumpWidget(const SizedBox());
  });
}
