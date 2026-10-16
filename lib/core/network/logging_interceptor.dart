import 'package:dio/dio.dart';

import '../logging/app_logger.dart';

/// One compact log entry per request/response, with timing. The bearer
/// token is never printed. Added to Dio in debug builds only.
class LoggingInterceptor extends Interceptor {
  static const _startKey = 'log_started_at';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.extra[_startKey] = DateTime.now();
    appLogger.d(
      '→ ${options.method} ${options.uri}'
      '${options.data == null ? '' : '\n${_describe(options.data)}'}',
    );
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    final options = response.requestOptions;
    appLogger.d(
      '← ${response.statusCode} ${options.method} ${options.uri} '
      '(${_elapsed(options)})\n${_describe(response.data)}',
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final options = err.requestOptions;
    appLogger.w(
      '✕ ${err.response?.statusCode ?? err.type.name} ${options.method} '
      '${options.uri} (${_elapsed(options)})'
      '${err.response?.data == null ? '' : '\n${_describe(err.response?.data)}'}',
      error: err.message,
    );
    handler.next(err);
  }

  static String _elapsed(RequestOptions options) {
    final started = options.extra[_startKey];
    return started is DateTime
        ? '${DateTime.now().difference(started).inMilliseconds} ms'
        : '?';
  }

  static String _describe(Object? data) => switch (data) {
    FormData(:final fields, :final files) =>
      'form-data fields=${fields.map((f) => f.key).toList()} '
          'files=${files.map((f) => f.value.filename).toList()}',
    _ => '$data',
  };
}
