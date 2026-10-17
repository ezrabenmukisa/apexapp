/// Thrown by data sources; repositories convert these into `Failure`s.
class ServerException implements Exception {
  const ServerException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => 'ServerException($statusCode): $message';
}

class CacheException implements Exception {
  const CacheException([this.message = 'Cache error']);

  final String message;

  @override
  String toString() => 'CacheException: $message';
}
