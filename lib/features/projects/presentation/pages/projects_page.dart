import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/bloc/load_cubit.dart';
import '../../../../core/bloc/load_view.dart';
import '../../../../core/navigation/widgets/apex_app_bar.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/common.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../milestones/domain/entities/milestone.dart';
import '../../../notifications/presentation/bloc/inbox_cubit.dart';
import '../../domain/entities/project_overview.dart';
import '../../domain/usecases/project_usecases.dart';
import '../bloc/project_cubits.dart';
import '../widgets/project_widgets.dart';

/// Owner 03: greeting, the decision waiting, and every project.
class ProjectsPage extends StatelessWidget {
  const ProjectsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final name = context.select((AuthBloc b) => b.state.user?.firstName ?? '');
    final unread = context.select((InboxCubit c) => c.unreadCount > 0);
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: context.read<DashboardCubit>().load,
        child: LoadView<DashboardCubit, OwnerDashboard>(
          builder: (context, dashboard, _) => ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            children: [
              ApexAppBar(
                hasUnread: unread,
                onBell: () => context.go(AppRoutes.ownerInbox),
              ),
              const SizedBox(height: 24),
              Text(
                '${Formatters.greeting(DateTime.now())}, $name',
                style: AppTextStyles.displayL.copyWith(fontSize: 34),
              ),
              const SizedBox(height: 20),
              if (dashboard.pendingReviews.isNotEmpty) ...[
                _DecisionCard(
                  overview: dashboard.pendingReviews.first.$1,
                  milestone: dashboard.pendingReviews.first.$2,
                ),
                const SizedBox(height: 28),
              ],
              SectionLabel(
                'Your projects',
                action: '+ New project',
                onAction: () => context.push(AppRoutes.newProject),
              ),
              if (dashboard.projects.isEmpty)
                EmptyState(
                  icon: Icons.foundation,
                  title: 'No projects yet',
                  message:
                      'Create your first project, split it into milestones and add the site manager who will send evidence.',
                  actionLabel: 'Create project',
                  onAction: () => context.push(AppRoutes.newProject),
                ),
              for (final overview in dashboard.projects) ...[
                ProjectCard(
                  overview: overview,
                  onTap: () =>
                      context.go(AppRoutes.project(overview.project.projectId)),
                ),
                const SizedBox(height: 12),
              ],
              if (dashboard.projects.isNotEmpty)
                if (dashboard.projects.first.current
                    case final Milestone current when current.dueDate != null)
                  DueCard(milestone: current),
            ],
          ),
        ),
      ),
    );
  }
}

/// Dark "Needs your decision" card.
class _DecisionCard extends StatelessWidget {
  const _DecisionCard({required this.overview, required this.milestone});

  final ProjectOverview overview;
  final Milestone milestone;

  @override
  Widget build(BuildContext context) {
    final submittedBy =
        overview.siteManager?.displayName ?? 'Your site manager';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'NEEDS YOUR DECISION',
            style: AppTextStyles.mono(color: AppColors.rule, size: 11),
          ),
          const SizedBox(height: 8),
          Text(
            '${milestone.title} evidence is in — from $submittedBy',
            style: AppTextStyles.title.copyWith(color: AppColors.surface),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  overview.project.projectName.toUpperCase(),
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.mono(color: AppColors.rule, size: 11),
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: () => context.push(
                  AppRoutes.review(
                    overview.project.projectId,
                    milestone.milestoneId,
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.surface,
                  foregroundColor: AppColors.ink,
                  minimumSize: const Size(0, 48),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                icon: const Icon(Icons.arrow_forward, size: 18),
                iconAlignment: IconAlignment.end,
                label: const Text('Review'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Owner Review tab: every submission awaiting a decision.
class ReviewQueuePage extends StatelessWidget {
  const ReviewQueuePage({super.key});

  @override
  Widget build(BuildContext context) => SafeArea(
    child: RefreshIndicator(
      onRefresh: context.read<DashboardCubit>().load,
      child: LoadView<DashboardCubit, OwnerDashboard>(
        builder: (context, dashboard, LoadState<OwnerDashboard> _) {
          final pending = dashboard.pendingReviews;
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
            children: [
              const PageTitle(
                'Review',
                subtitle: 'Evidence waiting for your decision',
              ),
              const SizedBox(height: 20),
              if (pending.isEmpty)
                const EmptyState(
                  icon: Icons.task_alt,
                  title: 'Nothing to review',
                  message:
                      'When your site manager submits evidence for a milestone, it appears here.',
                ),
              for (final (overview, milestone) in pending) ...[
                _ReviewTile(overview: overview, milestone: milestone),
                const SizedBox(height: 12),
              ],
            ],
          );
        },
      ),
    ),
  );
}

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({required this.overview, required this.milestone});

  final ProjectOverview overview;
  final Milestone milestone;

  @override
  Widget build(BuildContext context) => AppCard(
    padding: EdgeInsets.zero,
    child: ListRow(
      title: '${milestone.title} — ${overview.project.projectName}',
      subtitle:
          'Milestone ${milestone.sequence} of ${overview.milestones.length} · '
          '${overview.siteManager?.displayName ?? 'Site manager'}',
      leading: const Icon(Icons.fact_check_outlined, color: AppColors.awaiting),
      onTap: () => context.push(
        AppRoutes.review(overview.project.projectId, milestone.milestoneId),
      ),
    ),
  );
}
