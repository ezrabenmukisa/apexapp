import 'package:app/core/network/auth_interceptor.dart';
import 'package:app/core/network/logging_interceptor.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/fake_http.dart';

class _MockFirebaseAuth extends Mock implements FirebaseAuth {}

class _MockUser extends Mock implements User {}

void main() {
  group('AuthInterceptor', () {
    late FakeHttp http;
    late Dio dio;

    setUp(() {
      final auth = _MockFirebaseAuth();
      final user = _MockUser();
      when(() => auth.currentUser).thenReturn(user);
      when(() => user.getIdToken()).thenAnswer((_) async => 'id-token');
      http = FakeHttp()
        ..on('GET', '/api/v1/projects', 200, [])
        ..on('PUT', '/k1', 200);
      dio = http.dio();
      dio.interceptors.add(AuthInterceptor(auth, dio));
    });

    test('adds the Firebase token to API calls', () async {
      await dio.get<Object>('/projects');
      expect(
        http.requests.single.options.headers['Authorization'],
        'Bearer id-token',
      );
    });

    test('leaves it off requests marked skip-auth (S3 uploads)', () async {
      await dio.put<Object>(
        'https://bucket.s3.test/k1?sig=1',
        data: 'x',
        options: Options(extra: {AuthInterceptor.skipAuthKey: true}),
      );
      expect(
        http.requests.single.options.headers.containsKey('Authorization'),
        isFalse,
      );
    });
  });

  group('LoggingInterceptor.describe', () {
    test('summarises byte bodies instead of dumping them', () {
      expect(
        LoggingInterceptor.describe(List<int>.filled(2048, 1)),
        '<2048 bytes>',
      );
      expect(
        LoggingInterceptor.describe(Stream<List<int>>.empty()),
        '<byte stream>',
      );
    });

    test('hides presigned query strings', () {
      expect(
        LoggingInterceptor.url(
          Uri.parse(
            'https://b.s3.test/k1.jpg?X-Amz-Signature=abc&X-Amz-Credential=x',
          ),
        ),
        'https://b.s3.test/k1.jpg?<signed>',
      );
      expect(
        LoggingInterceptor.url(
          Uri.parse('https://api.test/notifications?unread_only=true'),
        ),
        'https://api.test/notifications?unread_only=true',
      );
    });
  });
}
