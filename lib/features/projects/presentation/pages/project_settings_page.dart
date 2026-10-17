import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/bloc/load_view.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/common.dart';
import '../../domain/entities/project.dart';
import '../../domain/entities/project_overview.dart';
import '../bloc/project_cubits.dart';

/// Owner 20: plan, team and status.
class ProjectSettingsPage extends StatelessWidget {
  const ProjectSettingsPage({super.key, required this.projectId});

  final String projectId;

  Future<bool> _confirm(
    BuildContext context, {
    required String title,
    required String message,
    required String action,
  }) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text(title, style: AppTextStyles.title),
          content: Text(message, style: AppTextStyles.body),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: AppColors.flagged),
              child: Text(action),
            ),
          ],
        ),
      ) ??
      false;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => getIt<ProjectOverviewCubit>(param1: projectId)..load(),
    child: Scaffold(
      body: SafeArea(
        child: LoadView<ProjectOverviewCubit, ProjectOverview>(
          builder: (context, o, state) {
            final cubit = context.read<ProjectOverviewCubit>();
            final paused = o.project.status == ProjectStatus.paused;
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                BackHeader(breadcrumb: o.project.projectName),
                const SizedBox(height: 8),
                const PageTitle('Project settings'),
                const SizedBox(height: 24),
                const SectionLabel('Plan'),
                AppCardList(
                  children: [
                    ListRow(
                      title: 'Name, site & budget',
                      onTap: () =>
                          context.push(AppRoutes.projectEdit(projectId)),
                    ),
                    ListRow(
                      title: 'Milestones',
                      trailing: Text(
                        '${o.milestones.length} · ${Formatters.compactMoney(o.allocatedAmount)}',
                        style: AppTextStyles.mono(
                          size: 13,
                          color: AppColors.ink2,
                          letterSpacing: 0,
                        ),
                      ),
                      onTap: () =>
                          context.push(AppRoutes.projectPlan(projectId)),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const SectionLabel('Team'),
                AppCardList(
                  children: [
                    for (final m in o.members)
                      ListRow(
                        leading: InitialsAvatar(
                          m.initials,
                          size: 32,
                          background: m.role == ProjectRole.owner
                              ? AppColors.lateriteTint
                              : AppColors.sunk,
                          foreground: m.role == ProjectRole.owner
                              ? AppColors.lateriteDeep
                              : AppColors.ink,
                        ),
                        title: m.role == ProjectRole.owner
                            ? '${m.displayName} (you)'
                            : m.displayName,
                        subtitle: m.role == ProjectRole.owner
                            ? null
                            : m.role.label,
                        chevron: false,
                        trailing: m.role == ProjectRole.owner
                            ? Text(
                                'Owner',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.ink2,
                                ),
                              )
                            : OutlinedButton(
                                onPressed: state.busy
                                    ? null
                                    : () async {
                                        if (await _confirm(
                                          context,
                                          title: 'Remove ${m.displayName}?',
                                          message:
                                              'Their access to this project ends now. Evidence they submitted stays on the record.',
                                          action: 'Remove',
                                        )) {
                                          await cubit.removeMember(m);
                                        }
                                      },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.flagged,
                                  side: const BorderSide(
                                    color: AppColors.flagged,
                                  ),
                                  minimumSize: const Size(0, 44),
                                ),
                                child: const Text('Remove'),
                              ),
                      ),
                    InkWell(
                      onTap: () =>
                          context.push(AppRoutes.projectTeam(projectId)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          '+ Add site manager by email',
                          style: AppTextStyles.label.copyWith(
                            color: AppColors.laterite,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Removing someone ends their access. Evidence they submitted stays on the record.',
                  style: AppTextStyles.small.copyWith(color: AppColors.ink2),
                ),
                const SizedBox(height: 24),
                const SectionLabel('Status'),
                AppCard(
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              paused ? 'Paused' : 'Active',
                              style: AppTextStyles.title.copyWith(fontSize: 17),
                            ),
                            Text(
                              paused
                                  ? 'Resume to let your site manager continue'
                                  : 'Pausing tells your site manager to stop work',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.ink2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      OutlinedButton(
                        onPressed: state.busy
                            ? null
                            : () async {
                                if (paused ||
                                    await _confirm(
                                      context,
                                      title: 'Pause this project?',
                                      message:
                                          'Your site manager will be told to stop work until you resume.',
                                      action: 'Pause',
                                    )) {
                                  await cubit.setStatus(
                                    paused
                                        ? ProjectStatus.active
                                        : ProjectStatus.paused,
                                  );
                                }
                              },
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 44),
                        ),
                        child: Text(paused ? 'Resume' : 'Pause'),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    ),
  );
}
