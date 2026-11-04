import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/common.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../projects/presentation/bloc/project_cubits.dart';
import '../bloc/settings_cubit.dart';
import '../widgets/account_widgets.dart';

/// Owner 19.
class OwnerAccountPage extends StatelessWidget {
  const OwnerAccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.select((AuthBloc b) => b.state.user);
    final settings = context.watch<SettingsCubit>();
    final firstProject = context.select(
      (DashboardCubit c) =>
          c.state.data?.projects.firstOrNull?.project.projectId,
    );
    if (user == null) return const SizedBox.shrink();
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        children: [
          const PageTitle('Account'),
          const SizedBox(height: 20),
          AppCardList(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    InitialsAvatar(user.initials, size: 52),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.fullName,
                            style: AppTextStyles.title.copyWith(fontSize: 17),
                          ),
                          Text(
                            'Owner',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.ink2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    LinkText(
                      'Edit',
                      onTap: () => context.push(AppRoutes.editProfile),
                    ),
                  ],
                ),
              ),
              KeyValueRow('Email', user.contactEmail),
              if (user.contactPhone != null)
                KeyValueRow('Phone', user.contactPhone!, mono: true),
            ],
          ),
          const SizedBox(height: 24),
          const SectionLabel('On this phone'),
          AppCardList(
            children: [
              SwitchRow(
                title: 'Push notifications',
                value: settings.state.pushNotifications,
                onChanged: (v) =>
                    settings.update((s) => s.copyWith(pushNotifications: v)),
              ),
              SwitchRow(
                title: 'Require Face ID to review',
                value: settings.state.requireBiometricToReview,
                onChanged: (v) => settings.update(
                  (s) => s.copyWith(requireBiometricToReview: v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const SectionLabel('Projects & help'),
          AppCardList(
            children: [
              ListRow(
                title: 'Project settings & team',
                onTap: () => firstProject == null
                    ? context.go(AppRoutes.ownerProjects)
                    : context.push(AppRoutes.projectSettings(firstProject)),
              ),
              ListRow(
                title: 'Help',
                onTap: () => showInfoSheet(context, 'Help', helpText),
              ),
              ListRow(
                title: 'Privacy',
                onTap: () => showInfoSheet(context, 'Privacy', privacyText),
              ),
            ],
          ),
          const SizedBox(height: 28),
          const SignOutLink(),
        ],
      ),
    );
  }
}
