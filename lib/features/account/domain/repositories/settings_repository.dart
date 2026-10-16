import '../entities/app_settings.dart';

/// Per-phone preferences, stored locally.
abstract interface class SettingsRepository {
  AppSettings get current;

  Stream<AppSettings> watch();

  Future<void> save(AppSettings settings);

  /// Reset on sign-out.
  Future<void> clear();
}
