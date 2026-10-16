import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/ledger_bar.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../../milestones/domain/entities/milestone.dart';
import '../../../milestones/presentation/utils/status_ui.dart';
import '../../domain/entities/project.dart';
import '../../domain/entities/project_overview.dart';

LedgerBar ledgerFor(List<Milestone> milestones, {double height = 12}) =>
    LedgerBar(
      height: height,
      segments: [
        for (final m in milestones)
          LedgerSegment(
            weight: (m.plannedBudget ?? 0) > 0 ? m.plannedBudget! : 1,
            tone: m.status.tone,
          ),
      ],
    );

/// Project summary card on the owner's Projects tab.
class ProjectCard extends StatelessWidget {
  const ProjectCard({super.key, required this.overview, this.onTap});

  final ProjectOverview overview;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = overview.project;
    final total = overview.milestones.length;
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.projectName,
                      style: AppTextStyles.displayM.copyWith(
                        fontSize: 22,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        p.area,
                        overview.siteManager?.displayName,
                      ].whereType<String>().join(' · '),
                      style: AppTextStyles.body.copyWith(color: AppColors.ink2),
                    ),
                  ],
                ),
              ),
              if (p.status == ProjectStatus.paused)
                const StatusChip(label: 'Paused', tone: StatusTone.changes)
              else if (total > 0)
                StatusChip(
                  label: 'Phase ${overview.phaseNumber} of $total',
                  tone: StatusTone.awaiting,
                ),
            ],
          ),
          const SizedBox(height: 16),
          ledgerFor(overview.milestones),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),
          Row(
            children: [
              _Figure('Approved', overview.approvedAmount),
              _Figure('In review', overview.inReviewAmount),
              _Figure('Total', overview.totalAmount),
            ],
          ),
        ],
      ),
    );
  }
}

class _Figure extends StatelessWidget {
  const _Figure(this.label, this.amount);

  final String label;
  final double amount;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.small.copyWith(color: AppColors.ink2)),
        Text(
          Formatters.compactMoney(amount),
          style: AppTextStyles.displayM.copyWith(fontSize: 22),
        ),
      ],
    ),
  );
}

/// "Walling is due 1 Nov — 17 days left of 30."
class DueCard extends StatelessWidget {
  const DueCard({super.key, required this.milestone});

  final Milestone milestone;

  @override
  Widget build(BuildContext context) {
    final due = milestone.dueDate;
    if (due == null) return const SizedBox.shrink();
    final left = Formatters.daysUntil(due);
    final span = due.difference(milestone.startDate).inDays + 1;
    final style = AppTextStyles.body;
    return AppCard(
      child: Row(
        children: [
          Icon(
            Icons.schedule,
            size: 22,
            color: left < 0 ? AppColors.flagged : AppColors.changes,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: '${milestone.title} is due '),
                  TextSpan(
                    text: Formatters.dayMonth(due),
                    style: style.copyWith(fontWeight: FontWeight.w700),
                  ),
                  TextSpan(
                    text: left < 0
                        ? ' — ${-left} days overdue.'
                        : ' — $left days left of $span.',
                  ),
                ],
              ),
              style: style,
            ),
          ),
        ],
      ),
    );
  }
}

/// One numbered milestone row (project detail).
class MilestoneRow extends StatelessWidget {
  const MilestoneRow({
    super.key,
    required this.milestone,
    this.onTap,
    this.highlight = false,
  });

  final Milestone milestone;
  final VoidCallback? onTap;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final m = milestone;
    final budget = m.plannedBudget == null
        ? null
        : Formatters.compactMoney(m.plannedBudget!);
    final detail = switch (m.status) {
      MilestoneStatus.approved => 'approved',
      MilestoneStatus.notStarted => Formatters.dateRange(
        m.startDate,
        m.dueDate,
      ),
      _ => m.dueDate == null ? null : 'due ${Formatters.dayMonth(m.dueDate!)}',
    };
    return Material(
      color: highlight
          ? AppColors.awaitingBg.withValues(alpha: 0.5)
          : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              SizedBox(
                width: 36,
                child: Text(
                  m.sequence.toString().padLeft(2, '0'),
                  style: AppTextStyles.mono(color: AppColors.ink2, size: 13),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      m.title,
                      style: AppTextStyles.title.copyWith(fontSize: 17),
                    ),
                    Text(
                      [budget, detail].whereType<String>().join(' · '),
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.ink2,
                      ),
                    ),
                  ],
                ),
              ),
              StatusChip(label: m.status.label, tone: m.status.tone),
            ],
          ),
        ),
      ),
    );
  }
}
