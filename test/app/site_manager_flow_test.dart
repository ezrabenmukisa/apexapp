import 'package:app/core/device/connectivity_service.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_harness.dart';

/// End-to-end: the site manager joins, captures, submits offline and the
/// outbox sends when the connection returns.
void main() {
  testWidgets('site manager: join → today → capture → submit → queue', (
    tester,
  ) async {
    final app = AppHarness(role: 'MANAGER');
    await app.start(tester);

    // 18 Joins (first visit)
    expect(find.text('Sarah added you to a project'), findsOneWidget);
    await AppHarness.tap(tester, find.text('Allow').first);
    await AppHarness.tap(tester, find.text('Open project'));

    // 07 Today
    expect(find.text('Walling'), findsOneWidget);
    expect(find.text('THE BRIEF, FROM SARAH'), findsOneWidget);
    expect(find.textContaining('Foundation approved'), findsOneWidget);

    // Go offline before submitting.
    app.connectivity.set(const NetworkState(online: false, onWifi: false));

    // 08 Capture: two photos and a video.
    await AppHarness.tap(tester, find.text('Capture evidence'));
    expect(find.text('[live camera]'), findsOneWidget);
    await AppHarness.tap(tester, find.bySemanticsLabel('Take'));
    await AppHarness.tap(tester, find.bySemanticsLabel('Take'));
    await AppHarness.tap(tester, find.text('Video'));
    await AppHarness.tap(tester, find.bySemanticsLabel('Take'));
    await tester.pump(const Duration(seconds: 3));
    await AppHarness.tap(tester, find.bySemanticsLabel('Stop recording'));
    await AppHarness.tap(
      tester,
      find.bySemanticsLabel('3 captured. Review and submit.'),
    );

    // 09 Submit
    expect(find.text('Submit evidence'), findsOneWidget);
    expect(find.text('SITE PHOTOS & VIDEO · 3'), findsOneWidget);
    expect(find.text('LOCKED AT SHUTTER'), findsOneWidget);
    await AppHarness.reveal(tester, find.text('What was done'));
    await tester.enterText(
      find.byType(TextFormField).first,
      'All four walls up to ring beam.',
    );
    await AppHarness.tap(tester, find.text('+ Camera, photos or PDF'));
    expect(find.textContaining('invoice-'), findsOneWidget);
    await AppHarness.reveal(tester, find.textContaining('No signal'));
    expect(find.textContaining('No signal'), findsOneWidget);
    await AppHarness.tap(tester, find.text('Submit to Sarah'));

    // 10 Queue: waiting while offline.
    expect(find.textContaining('Offline.', findRichText: true), findsOneWidget);
    expect(find.text('WAITING · 1'), findsOneWidget);
    expect(find.text('Pending sync'), findsOneWidget);
    expect(find.text('Queue · 1'), findsOneWidget);

    // Back online on Wi-Fi → sends automatically.
    app.connectivity.set(const NetworkState(online: true, onWifi: true));
    await AppHarness.settle(tester, frames: 20);
    expect(find.text('WAITING · 0'), findsOneWidget);
    expect(find.text('Walling evidence'), findsOneWidget);
    expect(find.text('Awaiting review'), findsOneWidget);

    // Today now waits for the owner's review.
    await AppHarness.tap(tester, find.text('Today'));
    expect(find.textContaining('waiting for Sarah to review'), findsOneWidget);

    // 21 Account & sync
    await AppHarness.tap(tester, find.bySemanticsLabel('Account'));
    expect(find.text('DATA & SYNC'), findsOneWidget);
    expect(find.text('0 PENDING'), findsOneWidget);
    expect(find.text('Sign out'), findsOneWidget);
  });

  testWidgets('video waits for Wi-Fi when "Wi-Fi only" is on', (tester) async {
    final app = AppHarness(role: 'MANAGER');
    await app.start(tester);
    await AppHarness.tap(tester, find.text('Open project'));
    app.connectivity.set(const NetworkState(online: true, onWifi: false));

    await AppHarness.tap(tester, find.text('Capture evidence'));
    await AppHarness.tap(tester, find.text('Video'));
    await AppHarness.tap(tester, find.bySemanticsLabel('Take'));
    await tester.pump(const Duration(seconds: 2));
    await AppHarness.tap(tester, find.bySemanticsLabel('Stop recording'));
    await AppHarness.tap(
      tester,
      find.bySemanticsLabel('1 captured. Review and submit.'),
    );
    await AppHarness.reveal(tester, find.text('What was done'));
    await tester.enterText(find.byType(TextFormField).first, 'Walk-through.');
    await AppHarness.tap(tester, find.text('Submit to Sarah'));

    expect(
      find.textContaining('Waiting for Wi-Fi.', findRichText: true),
      findsOneWidget,
    );
    expect(find.text('WAITING · 1'), findsOneWidget);

    // Turning the setting off releases it on mobile data.
    await AppHarness.tap(tester, find.text('Upload video on Wi-Fi only'));
    await AppHarness.settle(tester, frames: 20);
    expect(find.text('WAITING · 0'), findsOneWidget);
  });
}
