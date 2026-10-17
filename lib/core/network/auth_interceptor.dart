import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Attaches the Firebase ID token as `Authorization: Bearer <token>`.
///
/// The backend derives the user from this header, so no endpoint takes a
/// `user_id` for the current user. On a 401 the token is force-refreshed
/// and the request retried once.
class AuthInterceptor extends QueuedInterceptor {
  AuthInterceptor(this._firebaseAuth, this._dio);

  final FirebaseAuth _firebaseAuth;
  final Dio _dio;

  static const _retriedKey = 'auth_retried';

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _firebaseAuth.currentUser?.getIdToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final request = err.requestOptions;
    final user = _firebaseAuth.currentUser;
    if (err.response?.statusCode != 401 ||
        user == null ||
        request.extra[_retriedKey] == true) {
      return handler.next(err);
    }
    try {
      final token = await user.getIdToken(true);
      request
        ..headers['Authorization'] = 'Bearer $token'
        ..extra[_retriedKey] = true;
      handler.resolve(await _dio.fetch<dynamic>(request));
    } on DioException catch (e) {
      handler.next(e);
    } catch (_) {
      handler.next(err);
    }
  }
}
