import 'package:injectable/injectable.dart';

import '../config/app_config.dart';
import '../device/device_services.dart';
import '../device/real_device_services.dart';

/// Real GPS, geocoding, camera, receipt picker and permissions, or the simulations
/// when `SIMULATE_DEVICE=true` (tests, desktop, quick UI demos).
@module
abstract class DeviceModule {
  @lazySingleton
  LocationService location(
    GeolocatorLocationService real,
    SimulatedLocationService simulated,
  ) => AppConfig.simulateDevice ? simulated : real;

  @lazySingleton
  CaptureService capture(
    PickerCaptureService real,
    SimulatedCaptureService simulated,
  ) => AppConfig.simulateDevice ? simulated : real;

  @lazySingleton
  ReceiptPicker receipts(
    FilePickerReceiptPicker real,
    SimulatedReceiptPicker simulated,
  ) => AppConfig.simulateDevice ? simulated : real;

  @lazySingleton
  GeocodingService geocoding(
    PlatformGeocodingService real,
    SimulatedGeocodingService simulated,
  ) => AppConfig.simulateDevice ? simulated : real;

  @lazySingleton
  PermissionsService permissions(
    HandlerPermissionsService real,
    SimulatedPermissionsService simulated,
  ) => AppConfig.simulateDevice ? simulated : real;
}
