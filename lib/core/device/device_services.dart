import 'dart:math';

import 'package:injectable/injectable.dart';

import '../../features/evidence/domain/entities/evidence.dart';

// Device capabilities behind interfaces. Every implementation below is a
// SIMULATION so the screens work end to end; real ones (camera, geolocator,
// geocoding, file_picker, permission_handler, firebase_messaging) replace
// them in their feature issues without touching the UI.

/// GPS from device sensors.
abstract interface class LocationService {
  /// Current fix. Implementations must read sensors, never a cached value,
  /// because evidence location is frozen at the shutter.
  Future<GeoFix> currentFix();
}

/// In-app camera only: site media can never come from the gallery.
abstract interface class CaptureService {
  Future<CapturedMedia> takePhoto({required String label});
  Future<CapturedMedia> recordVideo({
    required String label,
    required int seconds,
  });
}

/// Receipts and invoices: gallery and PDFs are allowed.
abstract interface class ReceiptPicker {
  /// Null when the user cancels.
  Future<ReceiptFile?> pick();
}

/// Pin coordinates → human-readable address for `location_name`.
abstract interface class GeocodingService {
  Future<String> reverseGeocode(double latitude, double longitude);
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

@LazySingleton(as: LocationService)
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

@LazySingleton(as: CaptureService)
class SimulatedCaptureService implements CaptureService {
  SimulatedCaptureService(this._location);

  final LocationService _location;

  @override
  Future<CapturedMedia> takePhoto({required String label}) async {
    final fix = await _location.currentFix();
    return CapturedMedia(
      id: 'cap_${DateTime.now().microsecondsSinceEpoch}',
      kind: MediaKind.photo,
      fix: fix,
      label: label,
    );
  }

  @override
  Future<CapturedMedia> recordVideo({
    required String label,
    required int seconds,
  }) async {
    final fix = await _location.currentFix();
    return CapturedMedia(
      id: 'cap_${DateTime.now().microsecondsSinceEpoch}',
      kind: MediaKind.video,
      fix: fix,
      label: label,
      durationSeconds: seconds,
    );
  }
}

@LazySingleton(as: ReceiptPicker)
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

@LazySingleton(as: GeocodingService)
class SimulatedGeocodingService implements GeocodingService {
  @override
  Future<String> reverseGeocode(double latitude, double longitude) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return 'Wakiso, near Nansana trading centre';
  }
}

@LazySingleton(as: PermissionsService)
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
