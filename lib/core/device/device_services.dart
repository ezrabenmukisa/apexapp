import 'dart:math';

import 'package:injectable/injectable.dart';

import '../../features/evidence/domain/entities/evidence.dart';

// Device capabilities behind interfaces. The implementations below are
// SIMULATIONS, used by tests and when `SIMULATE_DEVICE=true` in `.env`.
// Real GPS, camera, receipt picker and permissions are in
// `real_device_services.dart`; `core/di/device_module.dart` picks one or
// the other. Geocoding and the FCM token are still simulated.

/// A device problem the user can fix (location off, camera refused…).
/// [message] is shown as is.
class DeviceException implements Exception {
  const DeviceException(this.message);

  final String message;

  @override
  String toString() => 'DeviceException: $message';
}

/// GPS from device sensors.
abstract interface class LocationService {
  /// Current fix. Implementations must read sensors, never a cached value,
  /// because evidence location is frozen at the shutter.
  Future<GeoFix> currentFix();
}

/// Camera only: site media can never come from the gallery. Each call
/// opens the camera once; null when the user closes it without a shot.
/// Throws [DeviceException] for problems the user can fix.
abstract interface class CaptureService {
  Future<CapturedMedia?> takePhoto();
  Future<CapturedMedia?> recordVideo({required Duration maxDuration});
}

/// Receipts and invoices: gallery and PDFs are allowed.
abstract interface class ReceiptPicker {
  /// Null when the user cancels.
  Future<ReceiptFile?> pick();
}

/// A point on the map.
typedef LatLngPoint = ({double latitude, double longitude});

/// Pin coordinates ↔ human-readable addresses (`location_name`).
abstract interface class GeocodingService {
  /// Best address for a point; throws [DeviceException] if none.
  Future<String> reverseGeocode(double latitude, double longitude);

  /// Best match for a typed address or place name, or null if none.
  Future<LatLngPoint?> forwardGeocode(String query);
}

enum DevicePermission { location, camera, notifications }

enum PermissionState { granted, denied, notAsked }

abstract interface class PermissionsService {
  Future<PermissionState> status(DevicePermission permission);
  Future<PermissionState> request(DevicePermission permission);
}

/// FCM device token for `PUT /devices/push-token`.
abstract interface class PushTokenProvider {
  Future<String?> token();
}

/// Default site pin for simulated fixes (sample project, Wakiso).
const _siteLat = 0.40441;
const _siteLng = 32.45940;

@lazySingleton
class SimulatedLocationService implements LocationService {
  final _random = Random();

  @override
  Future<GeoFix> currentFix() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    // ~10–20 m from the pin, like a phone standing on site.
    double jitter() =>
        (0.00009 + _random.nextDouble() * 0.00006) *
        (_random.nextBool() ? 1 : -1);
    return GeoFix(
      latitude: _siteLat + jitter(),
      longitude: _siteLng + jitter(),
      accuracyMetres: 4 + _random.nextInt(5).toDouble(),
      timestamp: DateTime.now(),
    );
  }
}

@lazySingleton
class SimulatedCaptureService implements CaptureService {
  SimulatedCaptureService(this._location);

  final SimulatedLocationService _location;
  int _shots = 0;

  static const _labels = [
    'east wall',
    'north wall',
    'west wall',
    'south wall',
    'ring beam close-up',
    'site overview',
    'materials on site',
    'detail',
  ];

  @override
  Future<CapturedMedia?> takePhoto() async {
    final fix = await _location.currentFix();
    return CapturedMedia(
      id: 'cap_${DateTime.now().microsecondsSinceEpoch}',
      kind: MediaKind.photo,
      fix: fix,
      label: _labels[_shots++ % _labels.length],
    );
  }

  @override
  Future<CapturedMedia?> recordVideo({required Duration maxDuration}) async {
    final fix = await _location.currentFix();
    return CapturedMedia(
      id: 'cap_${DateTime.now().microsecondsSinceEpoch}',
      kind: MediaKind.video,
      fix: fix,
      label: 'walk-through',
      durationSeconds: 20,
    );
  }
}

@lazySingleton
class SimulatedReceiptPicker implements ReceiptPicker {
  var _count = 0;

  @override
  Future<ReceiptFile?> pick() async {
    _count++;
    final pdf = _count.isOdd;
    return ReceiptFile(
      id: 'rcp_${DateTime.now().microsecondsSinceEpoch}',
      name: pdf ? 'invoice-$_count.pdf' : 'receipt-$_count.jpg',
    );
  }
}

@lazySingleton
class SimulatedGeocodingService implements GeocodingService {
  @override
  Future<String> reverseGeocode(double latitude, double longitude) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return 'Wakiso, near Nansana trading centre';
  }

  @override
  Future<LatLngPoint?> forwardGeocode(String query) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return query.trim().isEmpty
        ? null
        : (latitude: _siteLat + 0.001, longitude: _siteLng + 0.001);
  }
}

@lazySingleton
class SimulatedPermissionsService implements PermissionsService {
  final _granted = <DevicePermission>{DevicePermission.location};

  @override
  Future<PermissionState> status(DevicePermission permission) async =>
      _granted.contains(permission)
      ? PermissionState.granted
      : PermissionState.notAsked;

  @override
  Future<PermissionState> request(DevicePermission permission) async {
    _granted.add(permission);
    return PermissionState.granted;
  }
}

@LazySingleton(as: PushTokenProvider)
class SimulatedPushTokenProvider implements PushTokenProvider {
  @override
  Future<String?> token() async => 'simulated-fcm-token';
}
