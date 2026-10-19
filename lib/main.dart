import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
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
  try {
    await AppConfig.load();
  } on ConfigError catch (e) {
    appLogger.e(e.message);
    return runApp(_ConfigErrorApp(e.message));
  }
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await configureDependencies();
  appLogger.i(
    'Apex started · API ${AppConfig.apiBaseUrl} · live: ${AppConfig.live}',
  );
  runApp(const ApexApp());
}

/// Shown instead of the app when `.env` is missing or invalid.
class _ConfigErrorApp extends StatelessWidget {
  const _ConfigErrorApp(this.message);

  final String message;

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'App configuration error',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Text(message),
            ],
          ),
        ),
      ),
    ),
  );
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
