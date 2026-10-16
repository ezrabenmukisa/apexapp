import 'package:flutter_bloc/flutter_bloc.dart';

import 'app_logger.dart';

/// Logs every bloc/cubit state change and error. Installed in debug only.
class AppBlocObserver extends BlocObserver {
  const AppBlocObserver();

  @override
  void onChange(BlocBase<dynamic> bloc, Change<dynamic> change) {
    super.onChange(bloc, change);
    appLogger.t(
      '${bloc.runtimeType}\n'
      '  from: ${change.currentState}\n'
      '  to:   ${change.nextState}',
    );
  }

  @override
  void onEvent(Bloc<dynamic, dynamic> bloc, Object? event) {
    super.onEvent(bloc, event);
    appLogger.d('${bloc.runtimeType} ← $event');
  }

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    appLogger.e(
      '${bloc.runtimeType} threw',
      error: error,
      stackTrace: stackTrace,
    );
    super.onError(bloc, error, stackTrace);
  }
}
