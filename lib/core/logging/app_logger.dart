import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// App-wide logger. Prints in debug builds only; profile and release builds
/// are silent, so nothing (tokens, personal data) reaches device logs.
///
/// ```dart
/// appLogger.d('Session established');
/// appLogger.w('Profile fetch failed', error: e, stackTrace: st);
/// ```
final Logger appLogger = Logger(
  filter: _DebugOnlyFilter(),
  level: Level.trace,
  printer: PrettyPrinter(
    methodCount: 0,
    errorMethodCount: 8,
    lineLength: 100,
    dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
  ),
);

class _DebugOnlyFilter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) =>
      kDebugMode && event.level.value >= (level ?? Level.trace).value;
}
