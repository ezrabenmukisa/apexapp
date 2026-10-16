import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/device/device_services.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/common.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../evidence/presentation/bloc/evidence_cubits.dart';
import '../../domain/entities/app_settings.dart';
import '../bloc/settings_cubit.dart';
import '../widgets/account_widgets.dart';

/// Site manager 21: data & sync, phone access, language.
class SiteAccountPage extends StatelessWidget {
  const SiteAccountPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => getIt<PermissionsCubit>()..load(),
    child: const _SiteAccountView(),
  );
}

class _SiteAccountView extends StatelessWidget {
  const _SiteAccountView();

  Future<void> _pickLanguage(BuildContext context, SettingsCubit settings) =>
      showModalBottomSheet<void>(
        context: context,
        builder: (sheet) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final lang in AppLanguage.values)
                ListRow(
                  title: lang.label,
                  chevron: false,
                  trailing: settings.state.language == lang
                      ? const Icon(Icons.check)
                      : null,
                  onTap: () {
                    settings.update((s) => s.copyWith(language: lang));
                    Navigator.pop(sheet);
                  },
                ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final user = context.select((AuthBloc b) => b.state.user);
    final settings = context.watch<SettingsCubit>();
    final permissions = context.watch<PermissionsCubit>();
    final pending = context.select((OutboxCubit c) => c.state.pending.length);
    final activeProjects = context.select(
      (SiteCubit c) => c.state.data?.assignment == null ? 0 : 1,
    );
    bool granted(DevicePermission p) =>
        permissions.state[p] == PermissionState.granted;
    if (user == null) return const SizedBox.shrink();

    return Scaffold(
      body: ListView(
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
                  onPressed: () => context.canPop()
                      ? context.pop()
                      : context.go(AppRoutes.siteToday),
                  icon: const Icon(Icons.arrow_back, color: AppColors.surface),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    InitialsAvatar(
                      user.initials,
                      size: 56,
                      background: AppColors.laterite,
                      foreground: AppColors.surface,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.fullName,
                            style: AppTextStyles.displayM.copyWith(
                              color: AppColors.surface,
                            ),
                          ),
                          Text(
                            '${user.contactPhone ?? user.contactEmail} · $activeProjects active project${activeProjects == 1 ? '' : 's'}',
                            style: AppTextStyles.mono(
                              color: AppColors.rule,
                              size: 11,
                              letterSpacing: 0.02,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Edit profile',
                      onPressed: () => context.push(AppRoutes.editProfile),
                      icon: const Icon(
                        Icons.edit_outlined,
                        color: AppColors.surface,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SectionLabel('Data & sync'),
                AppCardList(
                  children: [
                    SwitchRow(
                      title: 'Video on Wi-Fi only',
                      value: settings.state.videoOnWifiOnly,
                      onChanged: (v) => settings.update(
                        (s) => s.copyWith(videoOnWifiOnly: v),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Photo quality', style: AppTextStyles.bodyLarge),
                          const SizedBox(height: 10),
                          SegmentedChoice<PhotoQuality>(
                            options: const {
                              PhotoQuality.dataSaver: 'Data saver',
                              PhotoQuality.fullDetail: 'Full detail',
                            },
                            selected: settings.state.photoQuality,
                            onChanged: (q) => settings.update(
                              (s) => s.copyWith(photoQuality: q),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Stored on this phone',
                                  style: AppTextStyles.bodyLarge,
                                ),
                              ),
                              Text(
                                '$pending PENDING',
                                style: AppTextStyles.mono(
                                  size: 12,
                                  color: AppColors.ink2,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Sent items are cleared automatically. Pending items are never deleted.',
                            style: AppTextStyles.small.copyWith(
                              color: AppColors.ink2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const SectionLabel('Phone access'),
                AppCardList(
                  children: [
                    ListRow(
                      title: 'Location',
                      chevron: false,
                      trailing: PermissionValue(
                        granted: granted(DevicePermission.location),
                        onAllow: () =>
                            permissions.request(DevicePermission.location),
                      ),
                    ),
                    ListRow(
                      title: 'Camera',
                      chevron: false,
                      trailing: PermissionValue(
                        granted: granted(DevicePermission.camera),
                        onAllow: () =>
                            permissions.request(DevicePermission.camera),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                AppCardList(
                  children: [
                    ListRow(
                      title: 'Language',
                      trailing: Text(
                        settings.state.language.label,
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.ink2,
                        ),
                      ),
                      onTap: () => _pickLanguage(context, settings),
                    ),
                    ListRow(
                      title: 'Help',
                      onTap: () => showInfoSheet(context, 'Help', helpText),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                const SignOutLink(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
