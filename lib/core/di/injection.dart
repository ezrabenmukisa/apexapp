import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

import '../config/app_config.dart';
import 'injection.config.dart';

final getIt = GetIt.instance;

/// Environment for data sources backed by in-memory mocks.
const mock = Environment(Env.mock);

/// Environment for data sources that call the real API over Dio.
const remote = Environment(Env.remote);

abstract final class Env {
  static const mock = 'mock';
  static const remote = 'remote';
}

/// Wires every `@injectable` class. Data sources annotated with [mock] or
/// [remote] are registered according to `AppConfig.useMockApi`; everything
/// else is shared by both.
@InjectableInit()
Future<void> configureDependencies() =>
    getIt.init(environment: AppConfig.useMockApi ? Env.mock : Env.remote);
