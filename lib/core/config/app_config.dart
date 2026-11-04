import 'package:flutter_dotenv/flutter_dotenv.dart';

/// App configuration, read from the `.env` asset at start-up.
///
/// Set up with `cp .env.example .env`. Nothing environment-specific is
/// hard-coded here; a missing or invalid value stops the app at launch
/// with an explanation.
abstract final class AppConfig {
  static const _envFile = '.env';

  /// Loads and validates `.env`. Call once, first thing in `main()`.
  static Future<void> load() async {
    try {
      await dotenv.load(fileName: _envFile);
    } catch (e) {
      throw ConfigError(
        'Could not read $_envFile ($e). '
        'Copy .env.example to .env in the apexapp folder.',
      );
    }
    validate();
  }

  /// Throws [ConfigError] if required values are missing or malformed.
  static void validate() {
    final url = Uri.tryParse(dotenv.maybeGet('API_BASE_URL') ?? '');
    if (url == null || !url.hasScheme || !url.scheme.startsWith('http')) {
      throw const ConfigError(
        'API_BASE_URL is missing or not an http(s) URL. '
        'Set it in .env, e.g. API_BASE_URL=https://apex.pntr.dev/api/v1',
      );
    }
  }

  /// Base URL of the Apex REST API, including the `/api/v1` prefix.
  static String get apiBaseUrl => dotenv.get('API_BASE_URL');

  /// Which features call the real API; the rest use the in-app mock server.
  static LiveFeatures get live => const LiveFeatures();

  static const Duration connectTimeout = Duration(seconds: 20);
  static const Duration receiveTimeout = Duration(seconds: 30);

  /// Simulated latency for mock data sources.
  static const Duration mockLatency = Duration(milliseconds: 600);
}

/// `LIVE_*` switches from `.env`. Auth and profile are always live.
final class LiveFeatures {
  const LiveFeatures();

  bool get projects => _flag('LIVE_PROJECTS');
  bool get milestones => _flag('LIVE_MILESTONES');
  bool get evidence => _flag('LIVE_EVIDENCE');
  bool get notifications => _flag('LIVE_NOTIFICATIONS');

  static bool _flag(String name) => dotenv.getBool(name, fallback: false);

  @override
  String toString() =>
      'projects=$projects milestones=$milestones '
      'evidence=$evidence notifications=$notifications';
}

/// Misconfigured `.env`; shown at launch so it is fixed before anything else.
class ConfigError implements Exception {
  const ConfigError(this.message);

  final String message;

  @override
  String toString() => 'ConfigError: $message';
}
