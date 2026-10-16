import 'package:app/core/di/injection.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/features/auth/domain/entities/profile_update.dart';
import 'package:app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:app/features/auth/presentation/bloc/complete_profile_cubit.dart';
import 'package:app/features/auth/presentation/pages/complete_profile_page.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/fixtures.dart';
import '../../../../helpers/mocks.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

void main() {
  late MockAuthBloc authBloc;
  late MockUpdateProfile updateProfile;

  setUpAll(() {
    registerFallbackValue(const ProfileUpdate());
    registerFallbackValue(const AuthSignOutRequested());
  });

  setUp(() {
    authBloc = MockAuthBloc();
    updateProfile = MockUpdateProfile();
    when(
      () => authBloc.state,
    ).thenReturn(const AuthState.unauthenticated().toNeedsProfile(tIdentity));
    getIt.registerFactory(() => CompleteProfileCubit(updateProfile));
  });

  tearDown(getIt.reset);

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      BlocProvider<AuthBloc>.value(
        value: authBloc,
        child: MaterialApp(
          theme: AppTheme.light,
          home: const CompleteProfilePage(),
        ),
      ),
    );
  }

  testWidgets('prefills the SMS-verified phone as read-only', (tester) async {
    await pump(tester);

    final phone = tester.widget<EditableText>(
      find.descendant(
        of: find.widgetWithText(TextFormField, '+447700900123'),
        matching: find.byType(EditableText),
      ),
    );
    expect(phone.readOnly, isTrue);
  });

  testWidgets('shows field and role errors and does not submit', (
    tester,
  ) async {
    await pump(tester);

    await tester.tap(find.text('Continue'));
    await tester.pump();

    expect(find.text('Enter your first name'), findsOneWidget);
    expect(find.text('Enter your last name'), findsOneWidget);
    expect(find.text('Enter your email'), findsOneWidget);
    expect(find.text('Choose how you\'ll use Siteproof'), findsOneWidget);
    verifyNever(() => updateProfile(any()));
  });

  testWidgets('valid form saves and notifies AuthBloc', (tester) async {
    when(
      () => updateProfile(any()),
    ).thenAnswer((_) async => const Right(tOwner));
    await pump(tester);

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Sarah');
    await tester.enterText(fields.at(2), 'Namuli');
    await tester.enterText(fields.at(3), 'sarah@example.com');
    await tester.tap(find.text('Owner'));
    await tester.pump();
    await tester.tap(find.text('Continue'));
    // The button keeps spinning after save until the router navigates away,
    // so pump instead of pumpAndSettle.
    await tester.pump();
    await tester.pump();

    verify(() => updateProfile(any())).called(1);
    verify(() => authBloc.add(const AuthProfileCompleted(tOwner))).called(1);
  });
}
