import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/bloc/load_view.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/common.dart';
import '../../../milestones/domain/entities/milestone.dart';
import '../../domain/entities/project.dart';
import '../../domain/entities/project_overview.dart';
import '../bloc/project_cubits.dart';
import '../widgets/project_widgets.dart';

/// Owner 04: ledger, site manager and the milestone list.
class ProjectDetailPage extends StatelessWidget {
  const ProjectDetailPage({super.key, required this.projectId});

  final String projectId;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => getIt<ProjectOverviewCubit>(param1: projectId)..load(),
    child: SafeArea(
      child: LoadView<ProjectOverviewCubit, ProjectOverview>(
        builder: (context, o, _) => RefreshIndicator(
          onRefresh: context.read<ProjectOverviewCubit>().load,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              BackHeader(
                onBack: () => context.canPop()
                    ? context.pop()
                    : context.go(AppRoutes.ownerProjects),
                actions: [
                  if (o.project.isOwner)
                    IconButton(
                      tooltip: 'Project settings',
                      icon: const Icon(Icons.more_horiz),
                      onPressed: () =>
                          context.push(AppRoutes.projectSettings(projectId)),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              PageTitle(o.project.projectName),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(
                    Icons.place_outlined,
                    size: 16,
                    color: AppColors.ink2,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${o.project.area} · started ${Formatters.date(o.project.createdAt)}',
                      style: AppTextStyles.body.copyWith(color: AppColors.ink2),
                    ),
                  ),
                ],
              ),
              if (o.project.status == ProjectStatus.paused) ...[
                const SizedBox(height: 12),
                const _PausedBanner(),
              ],
              const SizedBox(height: 20),
              _LedgerCard(overview: o),
              const SizedBox(height: 28),
              SectionLabel(
                'Milestones',
                action: o.project.isOwner ? 'Edit plan' : null,
                onAction: () => context.push(AppRoutes.projectPlan(projectId)),
              ),
              if (o.milestones.isEmpty)
                EmptyState(
                  title: 'No milestones yet',
                  message:
                      'Split the project into phases so evidence can be reviewed one stage at a time.',
                  actionLabel: o.project.isOwner ? 'Plan milestones' : null,
                  onAction: () =>
                      context.push(AppRoutes.projectPlan(projectId)),
                )
              else
                AppCardList(
                  children: [
                    for (final m in o.milestones)
                      MilestoneRow(
                        milestone: m,
                        highlight: m.status == MilestoneStatus.submitted,
                        onTap: () => context.push(
                          m.status == MilestoneStatus.notStarted ||
                                  m.status == MilestoneStatus.inProgress
                              ? AppRoutes.editMilestone(
                                  projectId,
                                  m.milestoneId,
                                )
                              : AppRoutes.review(projectId, m.milestoneId),
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _LedgerCard extends StatelessWidget {
  const _LedgerCard({required this.overview});

  final ProjectOverview overview;

  @override
  Widget build(BuildContext context) {
    final o = overview;
    final manager = o.siteManager;
    final pct = (o.approvedShare * 100).round();
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  '${o.project.currency} ${Formatters.compactMoney(o.totalAmount)}',
                  style: AppTextStyles.displayL,
                ),
              ),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '$pct%',
                      style: AppTextStyles.caption.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const TextSpan(text: ' approved'),
                  ],
                ),
                style: AppTextStyles.caption.copyWith(color: AppColors.ink2),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ledgerFor(o.milestones),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),
          if (manager == null)
            Row(
              children: [
                const InitialsAvatar(
                  '?',
                  background: AppColors.sunk,
                  foreground: AppColors.ink2,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'No site manager yet',
                    style: AppTextStyles.body.copyWith(color: AppColors.ink2),
                  ),
                ),
                if (o.project.isOwner)
                  LinkText(
                    'Add',
                    onTap: () => context.push(
                      AppRoutes.projectTeam(o.project.projectId),
                    ),
                  ),
              ],
            )
          else
            Row(
              children: [
                InitialsAvatar(
                  manager.initials,
                  background: AppColors.sunk,
                  foreground: AppColors.ink,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        manager.displayName,
                        style: AppTextStyles.label.copyWith(fontSize: 16),
                      ),
                      Text(
                        manager.role.label,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.ink2,
                        ),
                      ),
                    ],
                  ),
                ),
                _ContactButton(member: manager),
              ],
            ),
        ],
      ),
    );
  }
}

class _ContactButton extends StatelessWidget {
  const _ContactButton({required this.member});

  final ProjectMember member;

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.surface,
    shape: RoundedRectangleBorder(
      side: const BorderSide(color: AppColors.rule),
      borderRadius: BorderRadius.circular(AppDimensions.radiusControl),
    ),
    child: InkWell(
      borderRadius: BorderRadius.circular(AppDimensions.radiusControl),
      onTap: () => showModalBottomSheet<void>(
        context: context,
        builder: (_) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(member.displayName, style: AppTextStyles.title),
                const SizedBox(height: 12),
                Text(
                  'Email',
                  style: AppTextStyles.small.copyWith(color: AppColors.ink2),
                ),
                SelectableText(
                  member.contactEmail,
                  style: AppTextStyles.mono(size: 14, letterSpacing: 0),
                ),
              ],
            ),
          ),
        ),
      ),
      child: const SizedBox.square(
        dimension: 48,
        child: Icon(Icons.call_outlined, size: 22),
      ),
    ),
  );
}

class _PausedBanner extends StatelessWidget {
  const _PausedBanner();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.changesBg,
      borderRadius: BorderRadius.circular(AppDimensions.radiusControl),
    ),
    child: Row(
      children: [
        const Icon(Icons.pause_circle_outline, color: AppColors.changes),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Paused — your site manager has been told to stop work.',
            style: AppTextStyles.caption.copyWith(color: AppColors.changes),
          ),
        ),
      ],
    ),
  );
}
