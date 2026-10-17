import 'dart:async';
import 'dart:convert';

import 'package:app/app.dart';
import 'package:app/core/device/connectivity_service.dart';
import 'package:app/core/di/injection.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeUser extends Mock implements User {}

class _FakeAuth extends Mock implements FirebaseAuth {}

class FakeConnectivity implements ConnectivityService {
  NetworkState state = const NetworkState(online: true, onWifi: true);
  final _controller = StreamController<NetworkState>.broadcast();

  void set(NetworkState next) {
    state = next;
    _controller.add(next);
  }

  @override
  Future<NetworkState> current() async => state;

  @override
  Stream<NetworkState> watch() => _controller.stream;
}

/// Boots the real app (DI, router, blocs, mock API server) with a fake
/// signed-in Firebase user whose profile is already complete.
class AppHarness {
  AppHarness({required this.role});

  /// `OWNER` or `MANAGER`.
  final String role;
  final connectivity = FakeConnectivity();

  static const uid = 'test-uid';

  Future<void> start(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final isOwner = role == 'OWNER';
    SharedPreferences.setMockInitialValues({
      'mock_api.users.$uid': jsonEncode({
        'user_id': 'usr_$uid',
        'first_name': isOwner ? 'Sarah' : 'Kato',
        'last_name': isOwner ? 'Namuli' : 'Builders',
        'contact_email': isOwner ? 'sarah@example.com' : 'kato@example.com',
        'contact_phone': '+447700900123',
        'user_role': role,
      }),
    });
    FlutterSecureStorage.setMockInitialValues({});

    final user = _FakeUser();
    when(() => user.uid).thenReturn(uid);
    when(() => user.phoneNumber).thenReturn('+447700900123');
    when(() => user.email).thenReturn(null);
    when(() => user.displayName).thenReturn(null);
    when(() => user.getIdToken(any())).thenAnswer((_) async => 'token');
    when(() => user.getIdToken()).thenAnswer((_) async => 'token');
    final auth = _FakeAuth();
    when(() => auth.currentUser).thenReturn(user);
    when(() => auth.authStateChanges()).thenAnswer((_) => Stream.value(user));

    await getIt.reset();
    await configureDependencies();
    getIt
      ..allowReassignment = true
      ..registerLazySingleton<FirebaseAuth>(() => auth)
      ..registerLazySingleton<ConnectivityService>(() => connectivity);

    await tester.pumpWidget(const ApexApp());
    await settle(tester);
  }

  /// Advances through mock latency and animations without waiting for
  /// indeterminate spinners to stop.
  static Future<void> settle(WidgetTester tester, {int frames = 12}) async {
    for (var i = 0; i < frames; i++) {
      await tester.pump(const Duration(milliseconds: 300));
    }
  }

  /// Scrolls the main list until [finder] is built (lazy lists only build
  /// what is near the viewport).
  static Future<void> reveal(WidgetTester tester, Finder finder) async {
    final scrollable = find.byWidgetPredicate(
      (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
    );
    // Try upwards first (e.g. a back button scrolled away), then down.
    for (final delta in [-300.0, 200.0]) {
      if (finder.evaluate().isNotEmpty) break;
      if (scrollable.evaluate().isEmpty) break;
      try {
        await tester.scrollUntilVisible(
          finder,
          delta,
          scrollable: scrollable.last,
          maxScrolls: 15,
        );
      } on StateError {
        // Reached the end in this direction.
      }
    }
    await tester.ensureVisible(finder.first);
    await tester.pump();
  }

  static Future<void> tap(WidgetTester tester, Finder finder) async {
    await reveal(tester, finder);
    await tester.pump();
    await tester.tap(finder.first);
    await settle(tester);
  }
}
