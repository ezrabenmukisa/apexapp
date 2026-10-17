/// Build-time configuration, supplied with `--dart-define`.
///
/// ```sh
/// flutter run --dart-define=USE_MOCK_API=false \
///   --dart-define=API_BASE_URL=https://api.example.com/api/v1
/// ```
abstract final class AppConfig {
  /// When true, backend data sources are served by in-memory mocks so the
  /// app runs end to end before the FastAPI backend is available.
  /// Firebase Authentication is always real.
  static const bool useMockApi = bool.fromEnvironment(
    'USE_MOCK_API',
    defaultValue: true,
  );

  /// Base URL of the Apex REST API, including the `/api/v1` prefix.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000/api/v1',
  );

  static const Duration connectTimeout = Duration(seconds: 20);
  static const Duration receiveTimeout = Duration(seconds: 30);

  /// Simulated latency for mock data sources.
  static const Duration mockLatency = Duration(milliseconds: 600);
}
