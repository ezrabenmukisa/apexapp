import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:injectable/injectable.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../features/evidence/domain/entities/evidence.dart';
import 'device_services.dart';

// Real device implementations, chosen by `core/di/device_module.dart`
// unless `SIMULATE_DEVICE=true`.

/// Keeps captured and picked files somewhere that survives until upload.
/// The camera and picker hand back cache files the OS may delete, and a
/// submission can wait in the outbox for days.
abstract interface class MediaStore {
  /// Copies [file] into app storage as `<id>.<ext>` and returns the path.
  Future<String> keep(XFile file, String id);
}

@LazySingleton(as: MediaStore)
class AppMediaStore implements MediaStore {
  @override
  Future<String> keep(XFile file, String id) async {
    final root = await getApplicationSupportDirectory();
    final dir = Directory('${root.path}/evidence');
    await dir.create(recursive: true);
    final dest = '${dir.path}/$id${_extension(file)}';
    await file.saveTo(dest);
    return dest;
  }

  static String _extension(XFile file) {
    for (final name in [file.name, file.path]) {
      final base = name.split('/').last;
      final dot = base.lastIndexOf('.');
      if (dot > 0) return base.substring(dot).toLowerCase();
    }
    return '';
  }
}

/// A fresh GPS fix from the phone (never the last known position).
@lazySingleton
class GeolocatorLocationService implements LocationService {
  @override
  Future<GeoFix> currentFix() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const DeviceException(
        'Turn on location (GPS) so Apex can record where this was taken.',
      );
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    switch (permission) {
      case LocationPermission.denied:
        throw const DeviceException(
          'Apex needs your location to show where evidence was taken. '
          'Allow location and try again.',
        );
      case LocationPermission.deniedForever:
        throw const DeviceException(
          'Location is blocked for Apex. Allow it in your phone\'s '
          'Settings, under Apps → Apex → Permissions.',
        );
      default:
    }
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );
      return GeoFix(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracyMetres: position.accuracy,
        timestamp: DateTime.now(),
      );
    } on TimeoutException {
      throw const DeviceException(
        'Couldn\'t get a GPS fix. Step into the open and try again.',
      );
    }
  }
}

/// The phone's own camera app, camera only (no gallery). The location is
/// read before the camera opens (which also checks permission) and again
/// straight after the shot; if the second read fails the first is used.
@lazySingleton
class PickerCaptureService implements CaptureService {
  PickerCaptureService(this._location, this._picker, this._store);

  final LocationService _location;
  final ImagePicker _picker;
  final MediaStore _store;

  @override
  Future<CapturedMedia?> takePhoto() => _capture(
    MediaKind.photo,
    () => _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 2560,
      imageQuality: 85,
      requestFullMetadata: false,
    ),
  );

  @override
  Future<CapturedMedia?> recordVideo({required Duration maxDuration}) =>
      _capture(
        MediaKind.video,
        () => _picker.pickVideo(
          source: ImageSource.camera,
          maxDuration: maxDuration,
        ),
      );

  Future<CapturedMedia?> _capture(
    MediaKind kind,
    Future<XFile?> Function() open,
  ) async {
    final before = await _location.currentFix();
    final XFile? file;
    try {
      file = await open();
    } on PlatformException catch (e) {
      throw DeviceException(
        e.code == 'camera_access_denied'
            ? 'Apex needs the camera to capture evidence. Allow camera '
                  'access in your phone\'s Settings and try again.'
            : 'The camera couldn\'t open (${e.message ?? e.code}).',
      );
    }
    if (file == null) return null;
    GeoFix fix;
    try {
      fix = await _location.currentFix();
    } catch (_) {
      fix = before;
    }
    final id = 'cap_${DateTime.now().microsecondsSinceEpoch}';
    return CapturedMedia(
      id: id,
      kind: kind,
      fix: fix,
      localPath: await _store.keep(file, id),
    );
  }
}

/// Receipts and invoices: photos or PDFs from anywhere on the phone.
@lazySingleton
class FilePickerReceiptPicker implements ReceiptPicker {
  FilePickerReceiptPicker(this._store);

  final MediaStore _store;

  @override
  Future<ReceiptFile?> pick() async {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'heic', 'webp', 'pdf'],
    );
    if (files.isEmpty) return null;
    final picked = files.first;
    final id = 'rcp_${DateTime.now().microsecondsSinceEpoch}';
    return ReceiptFile(
      id: id,
      name: picked.name,
      localPath: await _store.keep(picked.xFile, id),
    );
  }
}

@lazySingleton
class HandlerPermissionsService implements PermissionsService {
  static Permission _of(DevicePermission p) => switch (p) {
    DevicePermission.location => Permission.locationWhenInUse,
    DevicePermission.camera => Permission.camera,
    DevicePermission.notifications => Permission.notification,
  };

  static PermissionState _state(PermissionStatus s) {
    if (s.isGranted || s.isLimited || s.isProvisional) {
      return PermissionState.granted;
    }
    if (s.isPermanentlyDenied || s.isRestricted) return PermissionState.denied;
    return PermissionState.notAsked;
  }

  @override
  Future<PermissionState> status(DevicePermission permission) async =>
      _state(await _of(permission).status);

  /// Once refused for good the OS won't ask again, so open Settings.
  @override
  Future<PermissionState> request(DevicePermission permission) async {
    final status = await _of(permission).request();
    if (status.isPermanentlyDenied) await openAppSettings();
    return _state(status);
  }
}
