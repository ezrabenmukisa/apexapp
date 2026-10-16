import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';

/// Site pin preview. A stand-in for the Google Maps pin-drop (issue #2):
/// shows the pin and its coordinates; tapping drops it at the phone's
/// position.
class SitePinMap extends StatelessWidget {
  const SitePinMap({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.onDropPin,
    this.locating = false,
  });

  final double? latitude;
  final double? longitude;
  final VoidCallback onDropPin;
  final bool locating;

  @override
  Widget build(BuildContext context) {
    final hasPin = latitude != null && longitude != null;
    return Semantics(
      button: true,
      label: hasPin
          ? 'Site pin at ${Formatters.coordinates(latitude!, longitude!)}. Tap to move it to your location.'
          : 'Drop the site pin at your location',
      excludeSemantics: true,
      child: Material(
        color: const Color(0xFFEFE6D6),
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: AppColors.controlBorder),
          borderRadius: BorderRadius.circular(AppDimensions.radiusControl),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: locating ? null : onDropPin,
          child: SizedBox(
            height: 96,
            child: Stack(
              children: [
                const Positioned.fill(
                  child: CustomPaint(painter: _RoadsPainter()),
                ),
                if (locating)
                  const Center(
                    child: SizedBox.square(
                      dimension: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                else if (hasPin)
                  const Center(
                    child: Icon(
                      Icons.location_on,
                      color: AppColors.laterite,
                      size: 32,
                    ),
                  )
                else
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusControl,
                        ),
                        border: Border.all(color: AppColors.ink),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.my_location, size: 16),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'Drop pin at my location',
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.label,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (hasPin)
                  Positioned(
                    left: 8,
                    bottom: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      color: AppColors.ink,
                      child: Text(
                        Formatters.coordinates(latitude!, longitude!),
                        style: AppTextStyles.mono(
                          size: 11,
                          color: AppColors.surface,
                          letterSpacing: 0.02,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoadsPainter extends CustomPainter {
  const _RoadsPainter();

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
  bool shouldRepaint(_RoadsPainter oldDelegate) => false;
}
