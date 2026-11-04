import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_harness.dart';

/// Sign-in against the live API's contract: `/auth/firebase` and
/// `/users/me`, which has no `user_role`.
void main() {
  testWidgets('returning user on this phone goes straight in', (tester) async {
    final app = AppHarness(role: 'OWNER');
    await app.start(tester);

    expect(
      app.backend.requests,
      containsAllInOrder(['POST /auth/firebase', 'GET /users/me']),
    );
    expect(find.text('NEEDS YOUR DECISION'), findsOneWidget);
  });

  testWidgets('new phone: profile prefilled, only the role is asked', (
    tester,
  ) async {
    final app = AppHarness(role: 'MANAGER');
    await app.start(tester, roleOnPhone: false);

    expect(find.text('Complete your profile'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Kato'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Builders'), findsOneWidget);
    expect(
      find.widgetWithText(TextFormField, 'kato@example.com'),
      findsOneWidget,
    );

    await AppHarness.tap(tester, find.text('Site manager'));
    await AppHarness.tap(tester, find.text('Continue'));

    expect(app.backend.requests, contains('PATCH /users/me'));
    expect(
      app.backend.profile,
      isNot(contains('user_role')),
      reason: 'user_role is not part of the live API',
    );
    expect(find.text('Sarah added you to a project'), findsOneWidget);
  });

  testWidgets('brand-new user completes the profile via PATCH /users/me', (
    tester,
  ) async {
    final app = AppHarness(role: 'OWNER');
    await app.start(tester, profileExists: false, roleOnPhone: false);

    expect(find.text('Complete your profile'), findsOneWidget);
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Sarah');
    await tester.enterText(fields.at(2), 'Namuli');
    await tester.enterText(fields.at(3), 'sarah@example.com');
    await AppHarness.tap(tester, find.text('Owner'));
    await AppHarness.tap(tester, find.text('Continue'));

    expect(app.backend.profile?['first_name'], 'Sarah');
    expect(app.backend.profile?['contact_email'], 'sarah@example.com');
    expect(find.textContaining('Sarah'), findsWidgets);
    expect(find.text('Your projects'.toUpperCase()), findsOneWidget);
  });
}
