import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';
import '../theme/app_text_styles.dart';
import 'app_card.dart';
import 'hatched_box.dart';

/// Visual status family from Foundations. Status is never colour alone:
/// every chip carries a label and an icon.
enum StatusTone {
  approved(AppColors.approved, AppColors.approvedBg, Icons.check),
  awaiting(AppColors.awaiting, AppColors.awaitingBg, Icons.hourglass_top),
  changes(AppColors.changes, AppColors.changesBg, Icons.edit_note),
  flagged(AppColors.flagged, AppColors.flaggedBg, Icons.flag_outlined),
  notStarted(AppColors.notStarted, AppColors.notStartedBg, null),
  inProgress(AppColors.ink, AppColors.sunk, Icons.construction),
  pendingSync(AppColors.ink2, AppColors.surface, Icons.cloud_upload_outlined);

  const StatusTone(this.foreground, this.background, this.icon);

  final Color foreground;
  final Color background;
  final IconData? icon;
}

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.label, required this.tone});

  final String label;
  final StatusTone tone;

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (tone.icon != null) ...[
            Icon(tone.icon, size: 13, color: tone.foreground),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: AppTextStyles.small.copyWith(
              fontWeight: FontWeight.w700,
              color: tone.foreground,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
    final radius = BorderRadius.circular(AppDimensions.radiusChip);
    return switch (tone) {
      StatusTone.pendingSync => DashedBorder(
        radius: AppDimensions.radiusChip,
        child: content,
      ),
      StatusTone.awaiting => HatchedBox(
        background: tone.background,
        stripe: const Color(0x1F234E78),
        stripeWidth: 3,
        gap: 6,
        borderRadius: radius,
        child: content,
      ),
      _ => DecoratedBox(
        decoration: BoxDecoration(color: tone.background, borderRadius: radius),
        child: content,
      ),
    };
  }
}
