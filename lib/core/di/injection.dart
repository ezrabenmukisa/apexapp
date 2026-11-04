import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

import 'injection.config.dart';

final getIt = GetIt.instance;

/// Wires every `@injectable` class. Which data sources hit the real API is
/// decided per feature in `data_source_module.dart` from `.env`.
@InjectableInit()
Future<void> configureDependencies() => getIt.init();
