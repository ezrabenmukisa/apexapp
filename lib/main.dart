import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'app.dart';
import 'core/config/app_config.dart';
import 'core/di/injection.dart';
import 'core/logging/app_bloc_observer.dart';
import 'core/logging/app_logger.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kDebugMode) _installDebugLogging();
  _registerFontLicenses();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await configureDependencies();
  appLogger.i(
    'Apex started · ${AppConfig.useMockApi ? 'MOCK API' : AppConfig.apiBaseUrl}',
  );
  runApp(const ApexApp());
}

/// Debug builds only: log bloc traffic and every uncaught error.
void _installDebugLogging() {
  Bloc.observer = const AppBlocObserver();

  final presentError = FlutterError.onError;
  FlutterError.onError = (details) {
    appLogger.e(
      'Flutter error',
      error: details.exception,
      stackTrace: details.stack,
    );
    presentError?.call(details);
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    appLogger.f('Uncaught async error', error: error, stackTrace: stack);
    return false; // Let the default handler run too.
  };
}

/// The bundled fonts are under the SIL Open Font License, which must ship
/// with them.
void _registerFontLicenses() {
  LicenseRegistry.addLicense(() async* {
    for (final family in const ['Newsreader', 'HankenGrotesk', 'IBMPlexMono']) {
      final license = await rootBundle.loadString(
        'assets/fonts/$family/OFL.txt',
      );
      yield LicenseEntryWithLineBreaks([family], license);
    }
  });
}
