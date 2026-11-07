import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../logging/app_logger.dart';

/// Attaches the Firebase ID token as `Authorization: Bearer <token>`.
///
/// The backend derives the user from this header, so no endpoint takes a
/// `user_id` for the current user. On a 401 the token is force-refreshed
/// and the request retried once.
///
/// Requests with `extra[skipAuthKey] == true` (presigned S3 uploads) go
/// out without the token: S3 rejects a second auth scheme, and the token
/// must never leave the Apex API.
///
/// Deliberately a plain [Interceptor], not a `QueuedInterceptor`: the retry
/// goes back through this interceptor, and a queued error handler waiting
/// on its own retry deadlocks when the retry gets a 401 too (sign-in then
/// spins forever with nothing logged). Every path below ends in exactly one
/// handler call so a request can never hang.
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._firebaseAuth, this._dio);

  final FirebaseAuth _firebaseAuth;
  final Dio _dio;

  static const _retriedKey = 'auth_retried';

  /// Set in `Options.extra` to send a request without the Firebase token.
  static const skipAuthKey = 'skip_auth';

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Presigned uploads go without a token; a retry already carries the
    // freshly refreshed one.
    if (options.extra[skipAuthKey] == true ||
        options.extra[_retriedKey] == true) {
      return handler.next(options);
    }
    try {
      final token = await _firebaseAuth.currentUser?.getIdToken();
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      handler.next(options);
    } catch (e, st) {
      appLogger.w(
        'Could not get a Firebase ID token',
        error: e,
        stackTrace: st,
      );
      handler.reject(
        DioException(requestOptions: options, error: e, stackTrace: st),
      );
    }
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
        request.extra[skipAuthKey] == true ||
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
