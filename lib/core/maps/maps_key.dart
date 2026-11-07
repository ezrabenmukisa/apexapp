import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../config/app_config.dart';
import '../logging/app_logger.dart';

/// Hands the Google Maps key from `.env` to the native iOS SDK, which (unlike
/// Android) can't read it from the build. See `ios/Runner/AppDelegate.swift`.
abstract final class MapsKey {
  static const _channel = MethodChannel('apex/maps');

  static Future<void> register() async {
    final key = AppConfig.googleMapsApiKey;
    if (key.isEmpty) {
      appLogger.w('GOOGLE_MAPS_API_KEY is not set in .env: maps will be blank');
      return;
    }
    if (defaultTargetPlatform != TargetPlatform.iOS || kIsWeb) return;
    try {
      await _channel.invokeMethod<void>('setApiKey', key);
    } catch (e) {
      appLogger.w('Could not pass the Maps key to iOS', error: e);
    }
  }
}
