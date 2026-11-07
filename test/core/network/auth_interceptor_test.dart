import 'dart:convert';

import 'package:app/core/network/auth_interceptor.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _FakeUser extends Mock implements User {}

class _FakeAuth extends Mock implements FirebaseAuth {}

/// Answers every request with [status].
class _StatusAdapter implements HttpClientAdapter {
  _StatusAdapter(this.status);

  final int status;
  var calls = 0;
  final authHeaders = <Object?>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    calls++;
    authHeaders.add(options.headers['Authorization']);
    return ResponseBody.fromString(
      jsonEncode({'detail': 'Invalid or expired Firebase sign-in token.'}),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late _FakeAuth auth;
  late _FakeUser user;

  setUp(() {
    user = _FakeUser();
    auth = _FakeAuth();
    when(() => auth.currentUser).thenReturn(user);
    when(() => user.getIdToken()).thenAnswer((_) async => 'old-token');
    when(() => user.getIdToken(true)).thenAnswer((_) async => 'fresh-token');
  });

  Dio dioWith(HttpClientAdapter adapter) {
    final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
      ..httpClientAdapter = adapter;
    return dio..interceptors.add(AuthInterceptor(auth, dio));
  }

  test(
    'a 401 that persists after the token refresh fails instead of hanging',
    () async {
      final adapter = _StatusAdapter(401);
      final dio = dioWith(adapter);

      await expectLater(
        dio.post<Object>('/auth/firebase').timeout(const Duration(seconds: 5)),
        throwsA(
          isA<DioException>().having(
            (e) => e.response?.statusCode,
            'status',
            401,
          ),
        ),
      );
      expect(adapter.calls, 2, reason: 'original + one retry');
      expect(adapter.authHeaders, ['Bearer old-token', 'Bearer fresh-token']);
    },
  );

  test(
    'a failing token lookup rejects the request instead of hanging',
    () async {
      when(
        () => user.getIdToken(),
      ).thenThrow(FirebaseAuthException(code: 'network-request-failed'));
      final dio = dioWith(_StatusAdapter(200));

      await expectLater(
        dio.get<Object>('/users/me').timeout(const Duration(seconds: 5)),
        throwsA(isA<DioException>()),
      );
    },
  );
}
