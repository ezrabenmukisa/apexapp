import 'dart:async';
import 'dart:convert';

import 'package:app/app.dart';
import 'package:app/core/config/app_config.dart';
import 'package:app/core/device/connectivity_service.dart';
import 'package:app/core/di/injection.dart';
import 'package:app/core/network/auth_interceptor.dart';
import 'package:dio/dio.dart';
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

/// Stands in for the live Apex backend over HTTP: answers the endpoints that
/// exist today (`/auth/firebase`, `/users/me`) exactly as the real API does
/// — no `user_role` — so the app's real remote data sources run in tests.
class FakeApexBackend implements HttpClientAdapter {
  FakeApexBackend(this.profile);

  /// The user's row; `null` means the profile hasn't been completed.
  Map<String, dynamic>? profile;
  final requests = <String>[];

  static const userId = 'c0ffee00-0000-4000-8000-000000000001';

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final path = options.uri.path.replaceFirst('/api/v1', '');
    requests.add('${options.method} $path');
    if (options.headers['Authorization'] != 'Bearer token') {
      return _json(401, {'detail': 'Not authenticated'});
    }
    return switch ((options.method, path)) {
      ('POST', '/auth/firebase') => _json(200, {
        'user_id': userId,
        'profile_complete': profile != null,
      }),
      ('GET', '/users/me') => _json(200, {
        'user_id': userId,
        'first_name': '',
        'last_name': '',
        ...?profile,
      }),
      ('PATCH', '/users/me') => () {
        profile = {...?profile, ...options.data as Map<String, dynamic>};
        return _json(200, {'user_id': userId, ...profile!});
      }(),
      _ => _json(404, {'detail': 'Not Found'}),
    };
  }

  ResponseBody _json(int status, Object body) => ResponseBody.fromString(
    jsonEncode(body),
    status,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );

  @override
  void close({bool force = false}) {}
}

/// Boots the real app (DI, router, blocs) with a fake signed-in Firebase
/// user. Auth and profile go through the real remote data sources to
/// [FakeApexBackend]; other features use the in-app mock server.
class AppHarness {
  AppHarness({required this.role});

  /// `OWNER` or `MANAGER`.
  final String role;
  final connectivity = FakeConnectivity();
  late final FakeApexBackend backend;

  static const uid = 'test-uid';

  /// [profileExists]: the user already completed their profile on the
  /// server. [roleOnPhone]: this phone remembers their role.
  Future<void> start(
    WidgetTester tester, {
    bool profileExists = true,
    bool roleOnPhone = true,
  }) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final isOwner = role == 'OWNER';
    backend = FakeApexBackend(
      profileExists
          ? {
              'first_name': isOwner ? 'Sarah' : 'Kato',
              'middle_name': null,
              'last_name': isOwner ? 'Namuli' : 'Builders',
              'contact_email': isOwner
                  ? 'sarah@example.com'
                  : 'kato@example.com',
              'contact_phone': '+447700900123',
            }
          : null,
    );
    // The role chosen on Complete Profile, remembered on this phone.
    SharedPreferences.setMockInitialValues({
      if (roleOnPhone) 'apex.role.$uid': role,
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
      ..registerLazySingleton<Dio>(() {
        final dio = Dio(BaseOptions(baseUrl: AppConfig.apiBaseUrl))
          ..httpClientAdapter = backend;
        return dio..interceptors.add(AuthInterceptor(auth, dio));
      })
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
