import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/bloc/load_cubit.dart';
import '../../../../core/bloc/load_view.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/common.dart';
import '../../../../core/widgets/onboarding_scaffold.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../../projects/domain/entities/project_overview.dart';
import '../../../projects/presentation/bloc/project_cubits.dart';
import '../../domain/entities/milestone.dart';

/// Onboarding 15 (step 4 of 5) / Settings → Milestones: the plan and how
/// the budget is allocated across it.
class MilestonePlanPage extends StatelessWidget {
  const MilestonePlanPage({
    super.key,
    required this.projectId,
    this.setup = false,
  });

  final String projectId;
  final bool setup;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => getIt<ProjectOverviewCubit>(param1: projectId)..load(),
    child: BlocBuilder<ProjectOverviewCubit, LoadState<ProjectOverview>>(
      builder: (context, state) {
        final o = state.data;
        final content = LoadView<ProjectOverviewCubit, ProjectOverview>(
          builder: (context, o, state) => setup
              ? _PlanBody(overview: o, busy: state.busy)
              : SingleChildScrollView(
                  padding: const EdgeInsets.only(top: 8, bottom: 24),
                  child: _PlanBody(overview: o, busy: state.busy),
                ),
        );
        if (!setup) {
          return Scaffold(
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    BackHeader(breadcrumb: o?.project.projectName),
                    Expanded(child: content),
                  ],
                ),
              ),
            ),
          );
        }
        return OnboardingScaffold(
          step: 4,
          totalSteps: 5,
          footer: PrimaryButton(
            label: 'Next: add your site manager',
            onPressed: (o?.milestones.isEmpty ?? true)
                ? null
                : () => context.pushReplacement(
                    AppRoutes.projectTeam(projectId, setup: true),
                  ),
          ),
          children: [content],
        );
      },
    ),
  );
}

class _PlanBody extends StatelessWidget {
  const _PlanBody({required this.overview, required this.busy});

  final ProjectOverview overview;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final o = overview;
    final projectId = o.project.projectId;
    final cubit = context.read<ProjectOverviewCubit>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Split it into milestones', style: AppTextStyles.displayL),
        const SizedBox(height: 8),
        Text(
          'Your site manager submits evidence for each one, in this order, and you review it.',
          style: AppTextStyles.body.copyWith(color: AppColors.ink2),
        ),
        const SizedBox(height: 20),
        _AllocationCard(overview: o),
        const SizedBox(height: 16),
        if (o.milestones.isNotEmpty)
          AppCardList(
            children: [
              for (final (i, m) in o.milestones.indexed)
                _PlanRow(
                  milestone: m,
                  shade: _shade(i, o.milestones.length),
                  onTap: () => context.push(
                    AppRoutes.editMilestone(projectId, m.milestoneId),
                  ),
                ),
            ],
          ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: DashedBorder(
                child: OutlinedButton(
                  onPressed: () =>
                      context.push(AppRoutes.newMilestone(projectId)),
                  style: OutlinedButton.styleFrom(side: BorderSide.none),
                  child: const Text('+ Add milestone'),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton(
                onPressed: busy
                    ? null
                    : () async {
                        final ok =
                            o.milestones.isEmpty ||
                            (await showDialog<bool>(
                                  context: context,
                                  builder: (c) => AlertDialog(
                                    backgroundColor: AppColors.surface,
                                    title: const Text(
                                      'Add the house template?',
                                    ),
                                    content: const Text(
                                      'Adds Foundation, Walling, Roofing and Finishing after your existing milestones.',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(c, false),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.pop(c, true),
                                        child: const Text('Add'),
                                      ),
                                    ],
                                  ),
                                ) ??
                                false);
                        if (ok) await cubit.applyTemplate();
                      },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.controlBorder),
                ),
                child: busy
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Use a template'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Ink → laterite, like the prototype's allocation bar.
  static Color _shade(int i, int n) => n <= 1
      ? AppColors.laterite
      : Color.lerp(AppColors.ink, AppColors.laterite, i / (n - 1))!;
}

class _AllocationCard extends StatelessWidget {
  const _AllocationCard({required this.overview});

  final ProjectOverview overview;

  @override
  Widget build(BuildContext context) {
    final o = overview;
    final total = o.project.plannedBudget;
    final allocated = o.allocatedAmount;
    final (label, tone) = switch (total) {
      null => ('No budget set', StatusTone.notStarted),
      _ when (allocated - total).abs() < 1 => ('Balanced', StatusTone.approved),
      _ when allocated > total => (
        'Over by ${Formatters.compactMoney(allocated - total)}',
        StatusTone.flagged,
      ),
      _ => (
        '${Formatters.compactMoney(total - allocated)} unallocated',
        StatusTone.changes,
      ),
    };
    final ms = o.milestones;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 12,
            child: ms.isEmpty
                ? Container(color: AppColors.rule)
                : Row(
                    children: [
                      for (final (i, m) in ms.indexed) ...[
                        if (i > 0) const SizedBox(width: 3),
                        Expanded(
                          flex:
                              ((m.plannedBudget ?? 0) /
                                      (allocated <= 0 ? 1 : allocated) *
                                      1000)
                                  .round()
                                  .clamp(1, 1000),
                          child: Container(
                            color: _PlanBody._shade(i, ms.length),
                          ),
                        ),
                      ],
                    ],
                  ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: Formatters.compactMoney(allocated),
                        style: AppTextStyles.displayM.copyWith(fontSize: 22),
                      ),
                      if (total != null)
                        TextSpan(
                          text:
                              ' of ${Formatters.compactMoney(total)} allocated',
                        )
                      else
                        const TextSpan(text: ' allocated'),
                    ],
                  ),
                  style: AppTextStyles.body,
                ),
              ),
              StatusChip(label: label, tone: tone),
            ],
          ),
        ],
      ),
    );
  }
}

class _PlanRow extends StatelessWidget {
  const _PlanRow({
    required this.milestone,
    required this.shade,
    required this.onTap,
  });

  final Milestone milestone;
  final Color shade;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListRow(
    leading: Container(width: 10, height: 10, color: shade),
    title: milestone.title,
    subtitle: Formatters.dateRange(milestone.startDate, milestone.dueDate),
    trailing: milestone.plannedBudget == null
        ? null
        : Text(
            Formatters.compactMoney(milestone.plannedBudget!),
            style: AppTextStyles.mono(size: 14, letterSpacing: 0),
          ),
    onTap: onTap,
  );
}
