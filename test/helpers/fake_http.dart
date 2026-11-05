import 'dart:convert';

import 'package:dio/dio.dart';

/// One request as the server saw it, with any streamed body collected.
class SentRequest {
  SentRequest(this.options, this.bytes);

  final RequestOptions options;
  final List<int>? bytes;

  String get method => options.method;
  Uri get uri => options.uri;
  Object? get data => options.data;
}

/// A Dio adapter that answers by `METHOD path` (path without query) and
/// records every request in order. Unrouted requests answer 404.
class FakeHttp implements HttpClientAdapter {
  final _routes = <String, (int, Object?)>{};
  final requests = <SentRequest>[];

  void on(String method, String path, int status, [Object? body]) =>
      _routes['$method $path'] = (status, body);

  Iterable<SentRequest> where(String method, [String? path]) => requests.where(
    (r) => r.method == method && (path == null || r.uri.path == path),
  );

  Dio dio({String baseUrl = 'https://api.test/api/v1'}) =>
      Dio(BaseOptions(baseUrl: baseUrl))..httpClientAdapter = this;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    List<int>? bytes;
    if (requestStream != null) {
      bytes = [await for (final chunk in requestStream) ...chunk];
    }
    requests.add(SentRequest(options, bytes));
    final (status, body) =
        _routes['${options.method} ${options.uri.path}'] ??
        (404, {'detail': 'Not Found'});
    return ResponseBody.fromString(
      body == null ? '' : jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
