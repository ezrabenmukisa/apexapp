import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import 'site_map_view.dart';

/// Site pin on the project form: a small map preview of the pin, or an
/// invitation to choose one. Tapping opens the full-screen map picker.
class SitePinMap extends StatelessWidget {
  const SitePinMap({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.onTap,
  });

  final double? latitude;
  final double? longitude;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasPin = latitude != null && longitude != null;
    return Semantics(
      button: true,
      label: hasPin
          ? 'Site pin at ${Formatters.coordinates(latitude!, longitude!)}. Tap to change it on the map.'
          : 'Choose the site location on a map',
      excludeSemantics: true,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppDimensions.radiusControl),
        child: Container(
          height: 140,
          decoration: BoxDecoration(
            color: const Color(0xFFEFE6D6),
            border: Border.all(color: AppColors.controlBorder),
            borderRadius: BorderRadius.circular(AppDimensions.radiusControl),
          ),
          child: Stack(
            children: [
              if (hasPin)
                Positioned.fill(
                  child: IgnorePointer(
                    child: SiteMapView(
                      initialTarget: (
                        latitude: latitude!,
                        longitude: longitude!,
                      ),
                      interactive: false,
                    ),
                  ),
                )
              else
                const Positioned.fill(
                  child: CustomPaint(painter: SimulatedMapPainter()),
                ),
              if (hasPin)
                const IgnorePointer(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.only(bottom: 32),
                      child: Icon(
                        Icons.location_on,
                        color: AppColors.laterite,
                        size: 32,
                      ),
                    ),
                  ),
                ),
              // Taps go to the picker, not the preview map.
              Positioned.fill(
                child: Material(
                  type: MaterialType.transparency,
                  child: InkWell(onTap: onTap),
                ),
              ),
              if (!hasPin)
                Center(
                  child: IgnorePointer(
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
                          const Icon(Icons.map_outlined, size: 16),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'Choose on map',
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.label,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else ...[
                Positioned(
                  left: 8,
                  bottom: 8,
                  child: IgnorePointer(
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
                ),
                Positioned(
                  right: 8,
                  bottom: 8,
                  child: IgnorePointer(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusChip,
                        ),
                        border: Border.all(color: AppColors.ink),
                      ),
                      child: Text(
                        'Change',
                        style: AppTextStyles.small.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
