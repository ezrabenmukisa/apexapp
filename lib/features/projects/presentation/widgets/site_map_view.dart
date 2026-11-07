import 'dart:async';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/device/device_services.dart';

/// Kampala: where the map opens when there is no pin and no GPS fix.
const kampala = (latitude: 0.3476, longitude: 32.5825);

/// A Google map for the project site, or a drawn stand-in when
/// `SIMULATE_DEVICE=true` (tests, desktop) where native maps can't render.
///
/// The site pin itself is drawn by the caller on top of the map's centre, so
/// moving the map moves the pin: the usual "pan to place" picker pattern,
/// which is easier with a thumb than dragging a small marker.
class SiteMapView extends StatefulWidget {
  const SiteMapView({
    super.key,
    required this.initialTarget,
    this.zoom = 16,
    this.interactive = true,
    this.myLocationEnabled = false,
    this.onCameraIdle,
    this.onMapCreated,
  });

  final LatLngPoint initialTarget;
  final double zoom;

  /// false = static preview (lite mode on Android, no gestures).
  final bool interactive;
  final bool myLocationEnabled;

  /// Called with the map centre whenever the user stops moving the map.
  final ValueChanged<LatLngPoint>? onCameraIdle;
  final ValueChanged<SiteMapController>? onMapCreated;

  @override
  State<SiteMapView> createState() => _SiteMapViewState();
}

/// Moves the map from outside (search result, "my location").
abstract interface class SiteMapController {
  Future<void> moveTo(LatLngPoint target, {double? zoom});
}

class _SiteMapViewState extends State<SiteMapView>
    implements SiteMapController {
  GoogleMapController? _map;
  late LatLngPoint _centre = widget.initialTarget;

  @override
  Future<void> moveTo(LatLngPoint target, {double? zoom}) async {
    final map = _map;
    if (map == null) {
      // Simulated map: jump straight there.
      _centre = target;
      widget.onCameraIdle?.call(target);
      return;
    }
    await map.animateCamera(
      zoom == null
          ? CameraUpdate.newLatLng(LatLng(target.latitude, target.longitude))
          : CameraUpdate.newLatLngZoom(
              LatLng(target.latitude, target.longitude),
              zoom,
            ),
    );
  }

  @override
  void initState() {
    super.initState();
    if (AppConfig.simulateDevice) {
      scheduleMicrotask(() {
        if (!mounted) return;
        widget.onMapCreated?.call(this);
        widget.onCameraIdle?.call(_centre);
      });
    }
  }

  @override
  void didUpdateWidget(SiteMapView old) {
    super.didUpdateWidget(old);
    // A preview follows its pin when the pin changes.
    if (!widget.interactive && old.initialTarget != widget.initialTarget) {
      _centre = widget.initialTarget;
      _map?.moveCamera(
        CameraUpdate.newLatLng(
          LatLng(widget.initialTarget.latitude, widget.initialTarget.longitude),
        ),
      );
    }
  }

  @override
  void dispose() {
    _map?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (AppConfig.simulateDevice) {
      return const ColoredBox(
        color: Color(0xFFEFE6D6),
        child: CustomPaint(painter: SimulatedMapPainter(), size: Size.infinite),
      );
    }
    final interactive = widget.interactive;
    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: LatLng(
          widget.initialTarget.latitude,
          widget.initialTarget.longitude,
        ),
        zoom: widget.zoom,
      ),
      liteModeEnabled:
          !interactive && Theme.of(context).platform == TargetPlatform.android,
      scrollGesturesEnabled: interactive,
      zoomGesturesEnabled: interactive,
      rotateGesturesEnabled: false,
      tiltGesturesEnabled: false,
      zoomControlsEnabled: interactive,
      mapToolbarEnabled: false,
      myLocationEnabled: widget.myLocationEnabled,
      // Our own "my location" button sits clear of the bottom sheet.
      myLocationButtonEnabled: false,
      compassEnabled: false,
      onMapCreated: (controller) {
        _map = controller;
        widget.onMapCreated?.call(this);
      },
      onCameraMove: (position) => _centre = (
        latitude: position.target.latitude,
        longitude: position.target.longitude,
      ),
      onCameraIdle: () => widget.onCameraIdle?.call(_centre),
      // Tapping a spot moves the pin there.
      onTap: interactive
          ? (point) =>
                moveTo((latitude: point.latitude, longitude: point.longitude))
          : null,
    );
  }
}

/// Stand-in map drawing for simulated mode.
class SimulatedMapPainter extends CustomPainter {
  const SimulatedMapPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final road = Paint()
      ..color = const Color(0xFFDCCFB9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    canvas
      ..drawPath(
        Path()
          ..moveTo(0, size.height * 0.75)
          ..quadraticBezierTo(
            size.width * 0.4,
            size.height * 0.45,
            size.width,
            size.height * 0.62,
          ),
        road,
      )
      ..drawLine(
        Offset(size.width * 0.2, 0),
        Offset(size.width * 0.32, size.height),
        road..strokeWidth = 4,
      );
  }

  @override
  bool shouldRepaint(SimulatedMapPainter oldDelegate) => false;
}
