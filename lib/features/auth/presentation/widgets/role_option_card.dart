import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';

/// One of the "I'm the…" choices on Complete Profile.
class RoleOptionCard extends StatelessWidget {
  const RoleOptionCard({
    super.key,
    required this.title,
    required this.description,
    required this.selected,
    required this.onTap,
    this.error = false,
  });

  final String title;
  final String description;
  final bool selected;
  final VoidCallback onTap;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final borderColor = selected
        ? AppColors.ink
        : error
        ? AppColors.flagged
        : AppColors.controlBorder;
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      button: true,
      child: Material(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusControl),
          side: BorderSide(color: borderColor, width: selected ? 2 : 1),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppDimensions.radiusControl),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    _RadioDot(selected: selected),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: AppTextStyles.small.copyWith(
                    color: AppColors.ink2,
                    height: 16 / 12,
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

class _RadioDot extends StatelessWidget {
  const _RadioDot({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) => Container(
    width: 20,
    height: 20,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(
        color: selected ? AppColors.ink : AppColors.controlBorder,
        width: 2,
      ),
    ),
    alignment: Alignment.center,
    child: selected
        ? Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.ink,
            ),
          )
        : null,
  );
}
