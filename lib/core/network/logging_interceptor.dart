import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../logging/app_logger.dart';

/// One compact log entry per request/response, with timing. The bearer
/// token is never printed, nor are presigned S3 signatures or file bytes.
/// Added to Dio in debug builds only.
class LoggingInterceptor extends Interceptor {
  static const _startKey = 'log_started_at';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.extra[_startKey] = DateTime.now();
    appLogger.d(
      '→ ${options.method} ${url(options.uri)}'
      '${options.data == null ? '' : '\n${describe(options.data)}'}',
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
      '← ${response.statusCode} ${options.method} ${url(options.uri)} '
      '(${_elapsed(options)})\n${describe(response.data)}',
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final options = err.requestOptions;
    final response = err.response;
    final line =
        '✕ ${response?.statusCode ?? err.type.name} ${options.method} '
        '${url(options.uri)} (${_elapsed(options)})';
    if (response != null) {
      // The server answered (e.g. 404 "No evidence submitted for this
      // milestone"): often expected and handled by the caller, so one
      // compact line with the body, without Dio's long explanation.
      appLogger.i(
        '$line${response.data == null ? '' : '\n${describe(response.data)}'}',
      );
    } else {
      // No answer at all: timeout, offline, TLS.
      appLogger.w('$line\n${err.error ?? err.message}');
    }
    handler.next(err);
  }

  static String _elapsed(RequestOptions options) {
    final started = options.extra[_startKey];
    return started is DateTime
        ? '${DateTime.now().difference(started).inMilliseconds} ms'
        : '?';
  }

  /// The URL with a presigned query (S3 signature, credential) replaced.
  @visibleForTesting
  static String url(Uri uri) =>
      uri.query.contains('X-Amz-') || uri.query.contains('Signature=')
      ? '${uri.replace(query: '')}<signed>'
      : '$uri';

  @visibleForTesting
  static String describe(Object? data) => switch (data) {
    FormData(:final fields, :final files) =>
      'form-data fields=${fields.map((f) => f.key).toList()} '
          'files=${files.map((f) => f.value.filename).toList()}',
    List<int>() => '<${data.length} bytes>',
    Stream() => '<byte stream>',
    _ => '$data',
  };
}
