import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/device/device_services.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/common.dart';
import '../../../evidence/presentation/bloc/evidence_cubits.dart';
import '../../domain/entities/app_settings.dart';
import '../bloc/settings_cubit.dart';
import '../widgets/account_widgets.dart';

/// Onboarding 18: shown once to a site manager after they're added.
class SiteJoinPage extends StatelessWidget {
  const SiteJoinPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => getIt<PermissionsCubit>()..load(),
    child: const _SiteJoinView(),
  );
}

class _SiteJoinView extends StatelessWidget {
  const _SiteJoinView();

  void _open(BuildContext context) {
    context.read<SettingsCubit>().update(
      (s) => s.copyWith(seenJoinIntro: true),
    );
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.siteToday);
    }
  }

  @override
  Widget build(BuildContext context) {
    final assignment = context.select(
      (SiteCubit c) => c.state.data?.assignment,
    );
    final settings = context.watch<SettingsCubit>();
    final permissions = context.watch<PermissionsCubit>();
    bool granted(DevicePermission p) =>
        permissions.state[p] == PermissionState.granted;
    final owner = assignment?.ownerName ?? 'The owner';
    final firstDue = assignment?.overview.milestones.firstOrNull?.dueDate;

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                Container(
                  color: AppColors.ink,
                  padding: EdgeInsets.fromLTRB(
                    20,
                    MediaQuery.paddingOf(context).top + 8,
                    20,
                    24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IconButton(
                        tooltip: 'Back',
                        onPressed: () => _open(context),
                        icon: const Icon(
                          Icons.arrow_back,
                          color: AppColors.surface,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'SIGNED IN AS SITE MANAGER',
                        style: AppTextStyles.mono(
                          color: AppColors.rule,
                          size: 11,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$owner added you to a project',
                        style: AppTextStyles.displayL.copyWith(
                          color: AppColors.surface,
                        ),
                      ),
                      if (assignment != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.ink2),
                            borderRadius: BorderRadius.circular(
                              AppDimensions.radiusControl,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${assignment.project.projectName}, ${assignment.project.area}',
                                style: AppTextStyles.label.copyWith(
                                  color: AppColors.surface,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                '${assignment.overview.milestones.length} milestones'
                                '${firstDue == null ? '' : ' · first due ${Formatters.dayMonth(firstDue)}'}',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.rule,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SectionLabel('Apex needs'),
                      AppCardList(
                        children: [
                          _PermissionRow(
                            icon: Icons.my_location,
                            title: 'Location',
                            detail: 'Proves photos were taken on site',
                            granted: granted(DevicePermission.location),
                            filled: true,
                            onAllow: () =>
                                permissions.request(DevicePermission.location),
                          ),
                          _PermissionRow(
                            icon: Icons.photo_camera_outlined,
                            title: 'Camera',
                            detail: 'Photos, video and receipts',
                            granted: granted(DevicePermission.camera),
                            filled: true,
                            onAllow: () =>
                                permissions.request(DevicePermission.camera),
                          ),
                          _PermissionRow(
                            icon: Icons.notifications_none,
                            title: 'Notifications',
                            detail: 'Know when $owner approves',
                            granted: granted(DevicePermission.notifications),
                            onAllow: () => permissions.request(
                              DevicePermission.notifications,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Your location is only recorded when you capture evidence — never tracked in the background.',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.ink2,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text('App language', style: AppTextStyles.label),
                      const SizedBox(height: 8),
                      SegmentedChoice<AppLanguage>(
                        options: {
                          for (final l in AppLanguage.values) l: l.label,
                        },
                        selected: settings.state.language,
                        onChanged: (l) =>
                            settings.update((s) => s.copyWith(language: l)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: FilledButton(
                onPressed: () => _open(context),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.laterite,
                ),
                child: const Text('Open project'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PermissionRow extends StatelessWidget {
  const _PermissionRow({
    required this.icon,
    required this.title,
    required this.detail,
    required this.granted,
    required this.onAllow,
    this.filled = false,
  });

  final IconData icon;
  final String title;
  final String detail;
  final bool granted;
  final VoidCallback onAllow;
  final bool filled;

  @override
  Widget build(BuildContext context) => ListRow(
    leading: Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: granted ? AppColors.approvedBg : AppColors.sunk,
        borderRadius: BorderRadius.circular(AppDimensions.radiusControl),
      ),
      child: Icon(
        icon,
        size: 20,
        color: granted ? AppColors.approved : AppColors.ink,
      ),
    ),
    title: title,
    subtitle: detail,
    chevron: false,
    trailing: PermissionValue(
      granted: granted,
      onAllow: onAllow,
      filled: filled,
    ),
  );
}
