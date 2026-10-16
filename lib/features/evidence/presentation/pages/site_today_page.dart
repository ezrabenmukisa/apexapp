import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/bloc/load_cubit.dart';
import '../../../../core/bloc/load_view.dart';
import '../../../../core/navigation/main_shell.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/geo.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/common.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../../account/presentation/bloc/settings_cubit.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../milestones/domain/entities/milestone.dart';
import '../../../milestones/presentation/utils/status_ui.dart';
import '../../domain/entities/evidence.dart';
import '../../domain/usecases/evidence_usecases.dart';
import '../bloc/evidence_cubits.dart';

/// Site manager 07: today's milestone, the owner's brief and the last
/// decision.
class SiteTodayPage extends StatelessWidget {
  const SiteTodayPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.select((AuthBloc b) => b.state.user);
    return BlocListener<SiteCubit, LoadState<SiteData>>(
      listenWhen: (a, b) =>
          a.data?.assignment == null && b.data?.assignment != null,
      listener: (context, state) {
        // First visit after being added: "Sarah added you to a project".
        if (!context.read<SettingsCubit>().state.seenJoinIntro) {
          context.push(AppRoutes.siteJoin);
        }
      },
      child: SafeArea(
        child: RefreshIndicator(
          onRefresh: context.read<SiteCubit>().load,
          child: LoadView<SiteCubit, SiteData>(
            builder: (context, data, _) {
              final a = data.assignment;
              return CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    sliver: SliverToBoxAdapter(
                      child: _Header(
                        initials: user?.initials ?? '',
                        name: user?.fullName ?? '',
                        distance: data.distanceToPin,
                      ),
                    ),
                  ),
                  if (a == null)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: EmptyState(
                        icon: Icons.mark_email_unread_outlined,
                        title: 'Waiting to be added',
                        message:
                            'Ask the project owner to add ${user?.contactEmail ?? 'your email'} as site manager. Pull down to refresh.',
                      ),
                    )
                  else
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _AssignmentBody(assignment: a),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.initials, required this.name, this.distance});

  final String initials;
  final String name;
  final double? distance;

  @override
  Widget build(BuildContext context) {
    final d = distance;
    final onSite = d != null && d <= onSiteRadiusMetres;
    return Row(
      children: [
        Semantics(
          button: true,
          label: 'Account',
          excludeSemantics: true,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () => context.push(AppRoutes.siteAccount),
            child: InitialsAvatar(
              initials,
              size: 36,
              background: AppColors.ink,
              foreground: AppColors.surface,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            name.toUpperCase(),
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.mono(color: AppColors.ink2),
          ),
        ),
        if (d != null)
          StatusChip(
            label: d < 1000
                ? '${d.round()} m from site'
                : '${(d / 1000).toStringAsFixed(1)} km from site',
            tone: onSite ? StatusTone.approved : StatusTone.changes,
          ),
      ],
    );
  }
}

class _AssignmentBody extends StatelessWidget {
  const _AssignmentBody({required this.assignment});

  final SiteAssignment assignment;

  @override
  Widget build(BuildContext context) {
    final a = assignment;
    final m = a.current;
    final total = a.overview.milestones.length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${a.project.projectName}, ${a.project.area}',
            style: AppTextStyles.body.copyWith(color: AppColors.ink2),
          ),
          if (m == null) ...[
            const SizedBox(height: 24),
            const EmptyState(
              icon: Icons.verified_outlined,
              title: 'Every milestone is approved',
              message: 'Nothing left to capture on this project.',
            ),
          ] else ...[
            Text(
              m.title,
              style: AppTextStyles.displayL.copyWith(
                fontSize: 40,
                height: 1.15,
              ),
            ),
            const SizedBox(height: 2),
            _Schedule(milestone: m, total: total),
            const SizedBox(height: 16),
            _Brief(
              milestone: m,
              ownerName: a.ownerName,
              currency: a.project.currency,
            ),
            if (a.lastReviewed != null && a.lastReview != null) ...[
              const SizedBox(height: 12),
              _LastDecision(milestone: a.lastReviewed!, review: a.lastReview!),
            ],
          ],
          const Spacer(),
          const SizedBox(height: 16),
          if (m != null) _CaptureCta(milestone: m, ownerName: a.ownerName),
        ],
      ),
    );
  }
}

class _Schedule extends StatelessWidget {
  const _Schedule({required this.milestone, required this.total});

  final Milestone milestone;
  final int total;

  @override
  Widget build(BuildContext context) {
    final m = milestone;
    final due = m.dueDate;
    final left = due == null ? null : Formatters.daysUntil(due);
    final style = AppTextStyles.body.copyWith(color: AppColors.ink2);
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text:
                'Milestone ${m.sequence} of $total · ${Formatters.dayMonth(m.startDate)} – ',
          ),
          if (due != null)
            TextSpan(
              text: Formatters.dayMonth(due),
              style: style.copyWith(
                color: AppColors.ink,
                fontWeight: FontWeight.w700,
              ),
            ),
          if (left != null)
            TextSpan(
              text: left < 0
                  ? ' · ${-left} days overdue'
                  : ' · $left days left',
            ),
        ],
      ),
      style: style,
    );
  }
}

class _Brief extends StatelessWidget {
  const _Brief({
    required this.milestone,
    required this.ownerName,
    required this.currency,
  });

  final Milestone milestone;
  final String ownerName;
  final String currency;

  @override
  Widget build(BuildContext context) => AppCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'THE BRIEF, FROM ${ownerName.toUpperCase()}',
          style: AppTextStyles.mono(color: AppColors.ink2, size: 11),
        ),
        const SizedBox(height: 8),
        Text(
          milestone.description ??
              'No brief yet — capture each part of the work clearly.',
          style: AppTextStyles.displayM.copyWith(
            fontSize: 21,
            fontWeight: FontWeight.w400,
            height: 1.35,
          ),
        ),
        if (milestone.plannedBudget != null) ...[
          const SizedBox(height: 14),
          const Divider(),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text('Planned budget', style: AppTextStyles.caption),
              ),
              Text(
                Formatters.money(milestone.plannedBudget!, currency: currency),
                style: AppTextStyles.mono(size: 14, letterSpacing: 0),
              ),
            ],
          ),
        ],
      ],
    ),
  );
}

class _LastDecision extends StatelessWidget {
  const _LastDecision({required this.milestone, required this.review});

  final Milestone milestone;
  final ReviewSummary review;

  @override
  Widget build(BuildContext context) {
    final tone = review.decision.tone;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tone.background,
        borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(tone.icon, size: 14, color: tone.foreground),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${milestone.title} ${review.decision.pastTense} · ${Formatters.dayMonth(review.reviewedAt)}',
                  style: AppTextStyles.caption.copyWith(
                    color: tone.foreground,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('"${review.comment}"', style: AppTextStyles.body),
        ],
      ),
    );
  }
}

class _CaptureCta extends StatelessWidget {
  const _CaptureCta({required this.milestone, required this.ownerName});

  final Milestone milestone;
  final String ownerName;

  @override
  Widget build(BuildContext context) {
    if (!milestone.status.acceptsEvidence) {
      return AppCard(
        color: AppColors.awaitingBg,
        borderColor: AppColors.awaitingBg,
        child: Row(
          children: [
            const Icon(Icons.hourglass_top, color: AppColors.awaiting),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Sent — waiting for $ownerName to review ${milestone.title}.',
                style: AppTextStyles.body.copyWith(color: AppColors.awaiting),
              ),
            ),
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (milestone.status == MilestoneStatus.changesRequested ||
            milestone.status == MilestoneStatus.flagged) ...[
          StatusChip(
            label: milestone.status.managerLabel,
            tone: milestone.status.tone,
          ),
          const SizedBox(height: 10),
        ],
        FilledButton.icon(
          onPressed: () => openCapture(context),
          style: FilledButton.styleFrom(backgroundColor: AppColors.laterite),
          icon: const Icon(Icons.photo_camera_outlined),
          label: const Text('Capture evidence'),
        ),
        const SizedBox(height: 8),
        Text(
          'One submission per visit. Once sent it can\'t be edited — send a new one to correct it.',
          textAlign: TextAlign.center,
          style: AppTextStyles.small.copyWith(color: AppColors.ink2),
        ),
      ],
    );
  }
}
