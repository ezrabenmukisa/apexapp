import 'package:app/core/error/error_mapper.dart';
import 'package:app/core/error/exceptions.dart';
import 'package:app/core/error/failures.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final request = RequestOptions(path: '/users/me');

  DioException badResponse(int status, Object? data) => DioException(
    requestOptions: request,
    type: DioExceptionType.badResponse,
    response: Response(requestOptions: request, statusCode: status, data: data),
  );

  group('mapErrorToFailure', () {
    test('connection problems become NetworkFailure', () {
      expect(
        mapErrorToFailure(
          DioException(
            requestOptions: request,
            type: DioExceptionType.connectionError,
          ),
        ),
        isA<NetworkFailure>(),
      );
    });

    test('401 becomes UnauthorizedFailure', () {
      expect(
        mapErrorToFailure(badResponse(401, null)),
        isA<UnauthorizedFailure>(),
      );
    });

    test('reads FastAPI string detail', () {
      expect(
        mapErrorToFailure(badResponse(403, {'detail': 'Owners only'})),
        const ServerFailure('Owners only', statusCode: 403),
      );
    });

    test('reads FastAPI validation detail list', () {
      expect(
        mapErrorToFailure(
          badResponse(422, {
            'detail': [
              {
                'msg': 'field required',
                'loc': ['body', 'first_name'],
              },
            ],
          }),
        ),
        const ServerFailure('field required', statusCode: 422),
      );
    });

    test('ServerException keeps message and status', () {
      expect(
        mapErrorToFailure(const ServerException('Nope', statusCode: 404)),
        const ServerFailure('Nope', statusCode: 404),
      );
    });

    test('Firebase codes become friendly AuthFailures', () {
      final failure = mapErrorToFailure(
        FirebaseAuthException(code: 'invalid-verification-code'),
      );
      expect(failure, isA<AuthFailure>());
      expect(failure.message, contains('incorrect'));
    });
  });
}
