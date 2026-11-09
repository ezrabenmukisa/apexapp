import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_harness.dart';

/// End-to-end: the owner walks every screen against the mock API.
void main() {
  testWidgets('owner: projects → review → approve → inbox → account', (
    tester,
  ) async {
    final app = AppHarness(role: 'OWNER');
    await app.start(tester);

    // 03 Projects
    expect(find.textContaining('Sarah'), findsWidgets);
    expect(find.text('NEEDS YOUR DECISION'), findsOneWidget);
    expect(find.text('Four-bedroom house'), findsWidgets);
    expect(find.text('Review · 1'), findsOneWidget);
    expect(find.text('Inbox · 2'), findsOneWidget);

    // 05 Review evidence → approve
    await AppHarness.tap(tester, find.widgetWithText(FilledButton, 'Review'));
    expect(find.text('Walling'), findsWidgets);
    expect(find.text('Awaiting your review'), findsOneWidget);
    await AppHarness.reveal(tester, find.textContaining('M FROM PIN'));
    expect(find.textContaining('M FROM PIN'), findsOneWidget);

    await AppHarness.tap(tester, find.text('Approve Walling'));
    expect(
      find.text('Add a comment before deciding'),
      findsOneWidget,
      reason: 'a comment is required for any decision',
    );
    await AppHarness.reveal(tester, find.text('Add a comment before deciding'));
    await tester.enterText(find.byType(TextField).last, 'Walls look good.');
    await AppHarness.tap(tester, find.text('Approve Walling'));

    // Back on Projects: nothing left to decide, badge cleared.
    expect(find.text('NEEDS YOUR DECISION'), findsNothing);
    expect(find.text('Review · 1'), findsNothing);

    // 04 Project detail
    await AppHarness.tap(tester, find.text('Four-bedroom house').first);
    expect(find.text('MILESTONES'), findsOneWidget);
    expect(find.text('Roofing'), findsOneWidget);

    // 20 Project settings
    await AppHarness.tap(tester, find.byTooltip('Project settings'));
    expect(find.text('Project settings'), findsOneWidget);
    expect(find.text('Kato Builders'), findsOneWidget);

    // 15 Milestone plan → 16 edit
    await AppHarness.tap(tester, find.text('Milestones'));
    expect(find.text('Split it into milestones'), findsOneWidget);
    expect(find.text('Balanced'), findsOneWidget);
    await AppHarness.tap(tester, find.text('Roofing'));
    expect(find.text('Save milestone'), findsOneWidget);
    await AppHarness.tap(tester, find.text('Save milestone'));
    expect(find.text('Split it into milestones'), findsOneWidget);
    await AppHarness.tap(tester, find.byTooltip('Back'));
    await AppHarness.tap(tester, find.byTooltip('Back'));
    await AppHarness.tap(tester, find.byTooltip('Back'));

    // 06 Inbox shows the new decision.
    await AppHarness.tap(tester, find.textContaining('Inbox'));
    expect(find.text('Walling approved'), findsOneWidget);
    await AppHarness.tap(tester, find.text('Walling approved'));
    expect(find.textContaining('Walls look good.'), findsWidgets);
    await tester.tapAt(const Offset(10, 10));
    await AppHarness.settle(tester);

    // 19 Account
    await AppHarness.tap(tester, find.text('Account'));
    expect(find.text('Sarah Namuli'), findsOneWidget);
    expect(find.text('Sign out'), findsOneWidget);

    // Signing out leaves the shell (still animating out) without a
    // missing-provider crash and lands on Welcome.
    await AppHarness.tap(tester, find.text('Sign out'));
    expect(find.text('Get started'), findsOneWidget);
  });

  testWidgets('owner: create project → milestones → add site manager', (
    tester,
  ) async {
    final app = AppHarness(role: 'OWNER');
    await app.start(tester);

    await AppHarness.tap(tester, find.text('+ New project'));
    expect(find.text('STEP 3 OF 5'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).first, 'Rental units');
    // Site pin: open the map picker, which centres on the phone's position
    // and looks up the address under the pin.
    await AppHarness.tap(tester, find.text('Choose on map'));
    expect(find.text('Project location'), findsOneWidget);
    expect(find.text('Wakiso, near Nansana trading centre'), findsOneWidget);

    // Search moves the pin and re-reads the address.
    await tester.enterText(find.byType(TextField).first, 'Nansana');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await AppHarness.settle(tester);
    expect(find.textContaining('0.40541 N'), findsOneWidget);

    await AppHarness.tap(tester, find.text('Confirm location'));
    expect(find.text('STEP 3 OF 5'), findsOneWidget);
    expect(
      find.widgetWithText(TextFormField, 'Wakiso, near Nansana trading centre'),
      findsOneWidget,
      reason: 'the picked address fills the Address field',
    );
    expect(find.text('Change'), findsOneWidget);
    await AppHarness.tap(tester, find.text('Create project'));

    // 15 (step 4): empty plan → template.
    expect(find.text('STEP 4 OF 5'), findsOneWidget);
    await AppHarness.tap(tester, find.text('Use a template'));
    expect(find.text('Foundation'), findsOneWidget);
    expect(find.text('Finishing'), findsOneWidget);

    // 17 (step 5): invite.
    await AppHarness.tap(tester, find.text('Next: add your site manager'));
    expect(find.text('STEP 5 OF 5'), findsOneWidget);
    await tester.enterText(
      find.byType(TextFormField).first,
      'john.okello@example.com',
    );
    await AppHarness.tap(tester, find.text('Add to project'));
    // Like the API, they're invited, not a member until they accept.
    expect(find.text('john.okello@example.com'), findsOneWidget);
    expect(find.text('Invited'), findsWidgets);
    expect(find.text('John Okello'), findsNothing);

    await AppHarness.tap(tester, find.text('Finish setup'));
    expect(find.text('Rental units'), findsWidgets);
  });

  testWidgets('owner: tapping a receipt opens it in the app', (tester) async {
    final app = AppHarness(role: 'OWNER');
    await app.start(tester);

    await AppHarness.tap(tester, find.widgetWithText(FilledButton, 'Review'));
    await AppHarness.tap(tester, find.text('bricks-invoice.pdf'));

    // The viewer opens with its share/save actions. The mock server's
    // receipts are sample data, so it explains there's no real file.
    expect(find.byTooltip('Share'), findsOneWidget);
    expect(find.byTooltip('Save to device'), findsOneWidget);
    expect(find.textContaining('sample data'), findsOneWidget);

    await AppHarness.tap(tester, find.byTooltip('Close'));
    expect(find.text('Approve Walling'), findsOneWidget);
  });
}
