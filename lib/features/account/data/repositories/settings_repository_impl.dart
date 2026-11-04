import 'dart:async';

import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/app_settings.dart';
import '../../domain/repositories/settings_repository.dart';

@LazySingleton(as: SettingsRepository)
class SettingsRepositoryImpl implements SettingsRepository {
  SettingsRepositoryImpl(this._prefs);

  final SharedPreferences _prefs;
  final _controller = StreamController<AppSettings>.broadcast();

  static const _prefix = 'apex.settings.';

  @override
  AppSettings get current => AppSettings(
    videoOnWifiOnly: _prefs.getBool('${_prefix}video_wifi_only') ?? true,
    photoQuality:
        PhotoQuality.values.asNameMap()[_prefs.getString(
          '${_prefix}photo_quality',
        )] ??
        PhotoQuality.dataSaver,
    pushNotifications: _prefs.getBool('${_prefix}push') ?? true,
    requireBiometricToReview: _prefs.getBool('${_prefix}biometric') ?? false,
    language:
        AppLanguage.values.asNameMap()[_prefs.getString(
          '${_prefix}language',
        )] ??
        AppLanguage.english,
    seenJoinIntro: _prefs.getBool('${_prefix}seen_join_intro') ?? false,
  );

  @override
  Stream<AppSettings> watch() => _controller.stream;

  @override
  Future<void> save(AppSettings s) async {
    await Future.wait([
      _prefs.setBool('${_prefix}video_wifi_only', s.videoOnWifiOnly),
      _prefs.setString('${_prefix}photo_quality', s.photoQuality.name),
      _prefs.setBool('${_prefix}push', s.pushNotifications),
      _prefs.setBool('${_prefix}biometric', s.requireBiometricToReview),
      _prefs.setString('${_prefix}language', s.language.name),
      _prefs.setBool('${_prefix}seen_join_intro', s.seenJoinIntro),
    ]);
    _controller.add(s);
  }

  @override
  Future<void> clear() async {
    for (final key in _prefs.getKeys().where((k) => k.startsWith(_prefix))) {
      await _prefs.remove(key);
    }
    _controller.add(current);
  }
}
