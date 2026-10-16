import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/device/device_services.dart';
import '../../domain/entities/app_settings.dart';
import '../../domain/repositories/settings_repository.dart';

/// Per-phone preferences (account screens, queue toggle).
@injectable
class SettingsCubit extends Cubit<AppSettings> {
  SettingsCubit(this._repository) : super(_repository.current) {
    _sub = _repository.watch().listen(emit);
  }

  final SettingsRepository _repository;
  late final StreamSubscription<AppSettings> _sub;

  Future<void> update(AppSettings Function(AppSettings) change) =>
      _repository.save(change(state));

  @override
  Future<void> close() async {
    await _sub.cancel();
    return super.close();
  }
}

/// Status of the phone permissions Siteproof needs.
@injectable
class PermissionsCubit extends Cubit<Map<DevicePermission, PermissionState>> {
  PermissionsCubit(this._service) : super(const {});

  final PermissionsService _service;

  Future<void> load() async {
    final entries = await Future.wait(
      DevicePermission.values.map(
        (p) async => MapEntry(p, await _service.status(p)),
      ),
    );
    if (!isClosed) emit(Map.fromEntries(entries));
  }

  Future<void> request(DevicePermission permission) async {
    final result = await _service.request(permission);
    if (!isClosed) emit({...state, permission: result});
  }
}
