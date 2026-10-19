import 'package:material_ui/material_ui.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';
import '../../widgets/apex_logo.dart';

/// Home header: Apex logo with a notifications bell (dot when unread).
class ApexAppBar extends StatelessWidget {
  const ApexAppBar({super.key, this.hasUnread = false, this.onBell});

  final bool hasUnread;
  final VoidCallback? onBell;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      const ApexLogo(),
      const Spacer(),
      if (onBell != null)
        Semantics(
          button: true,
          label: hasUnread ? 'Notifications, unread' : 'Notifications',
          excludeSemantics: true,
          child: Material(
            color: AppColors.surface,
            shape: RoundedRectangleBorder(
              side: const BorderSide(color: AppColors.rule),
              borderRadius: BorderRadius.circular(AppDimensions.radiusControl),
            ),
            child: InkWell(
              onTap: onBell,
              borderRadius: BorderRadius.circular(AppDimensions.radiusControl),
              child: SizedBox.square(
                dimension: 48,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Icon(Icons.notifications_none, size: 24),
                    if (hasUnread)
                      Positioned(
                        top: 10,
                        right: 11,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.laterite,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
    ],
  );
}
