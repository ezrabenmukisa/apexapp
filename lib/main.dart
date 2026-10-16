import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'core/di/injection.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _registerFontLicenses();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await configureDependencies();
  runApp(const ApexApp());
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
