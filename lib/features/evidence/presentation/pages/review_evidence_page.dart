import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/bloc/load_view.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/geo.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/common.dart';
import '../../../../core/widgets/labeled_field.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../../milestones/domain/entities/milestone.dart';
import '../../../milestones/presentation/utils/status_ui.dart';
import '../../domain/entities/evidence.dart';
import '../../domain/usecases/evidence_usecases.dart';
import '../bloc/evidence_cubits.dart';
import '../widgets/media_tiles.dart';

/// Owner 05: review a milestone's evidence and decide.
class ReviewEvidencePage extends StatelessWidget {
  const ReviewEvidencePage({
    super.key,
    required this.projectId,
    required this.milestoneId,
  });

  final String projectId;
  final String milestoneId;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) =>
        getIt<ReviewEvidenceCubit>(param1: '$projectId/$milestoneId')..load(),
    child: Scaffold(
      body: SafeArea(
        child: LoadView<ReviewEvidenceCubit, ReviewContext>(
          onActionSuccess: (context, _) {
            if (context.canPop()) context.pop();
          },
          builder: (context, ctx, state) =>
              _ReviewBody(context: ctx, busy: state.busy),
        ),
      ),
    ),
  );
}

class _ReviewBody extends StatefulWidget {
  const _ReviewBody({required this.context, required this.busy});

  final ReviewContext context;
  final bool busy;

  @override
  State<_ReviewBody> createState() => _ReviewBodyState();
}

class _ReviewBodyState extends State<_ReviewBody> {
  final _comment = TextEditingController();
  final _commentFocus = FocusNode();
  final _scroll = ScrollController();
  bool _commentError = false;

  @override
  void dispose() {
    _comment.dispose();
    _commentFocus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _decide(ReviewDecision decision) {
    if (_comment.text.trim().isEmpty) {
      setState(() => _commentError = true);
      _commentFocus.requestFocus();
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
      return;
    }
    context.read<ReviewEvidenceCubit>().decide(decision, _comment.text);
  }

  @override
  Widget build(BuildContext context) {
    final ctx = widget.context;
    final m = ctx.milestone;
    final e = ctx.evidence;
    final total = ctx.overview.milestones.length;
    String two(int n) => n.toString().padLeft(2, '0');
    final canDecide =
        e != null &&
        e.status == EvidenceStatus.submitted &&
        ctx.project.isOwner;

    return Column(
      children: [
        Expanded(
          child: ListView(
            controller: _scroll,
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              BackHeader(breadcrumb: ctx.project.projectName),
              const SizedBox(height: 12),
              Text(
                'MILESTONE ${two(m.sequence)} OF ${two(total)}'
                '${e == null ? '' : ' · SUBMITTED ${Formatters.dayMonth(e.submittedAt).toUpperCase()}, ${Formatters.time(e.submittedAt)}'}',
                style: AppTextStyles.stepLabel,
              ),
              const SizedBox(height: 8),
              Text(
                m.title,
                style: AppTextStyles.displayL.copyWith(
                  fontSize: 38,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (e != null)
                    StatusChip(
                      label: e.status == EvidenceStatus.submitted
                          ? 'Awaiting your review'
                          : e.status.label,
                      tone: e.status.tone,
                    )
                  else
                    StatusChip(label: m.status.label, tone: m.status.tone),
                  if (m.plannedBudget != null)
                    Text(
                      'Planned ${ctx.project.currency} ${Formatters.compactMoney(m.plannedBudget!)}',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.ink2,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              if (e == null)
                const EmptyState(
                  icon: Icons.photo_camera_outlined,
                  title: 'No evidence yet',
                  message:
                      'Your site manager hasn\'t submitted evidence for this milestone.',
                )
              else ...[
                _Statement(
                  evidence: e,
                  by: ctx.overview.siteManager?.displayName,
                ),
                const SizedBox(height: 24),
                _MediaSection(evidence: e),
                const SizedBox(height: 24),
                _WhereWhen(evidence: e, milestone: m, ctx: ctx),
                const SizedBox(height: 24),
                _Spending(evidence: e, currency: ctx.project.currency),
                const SizedBox(height: 24),
                if (e.latestReview case final review?)
                  _DecisionRecord(review: review)
                else if (canDecide)
                  LabeledField(
                    label: 'Your comment — required for any decision',
                    child: TextField(
                      controller: _comment,
                      focusNode: _commentFocus,
                      minLines: 2,
                      maxLines: 5,
                      textCapitalization: TextCapitalization.sentences,
                      onChanged: (_) {
                        if (_commentError) {
                          setState(() => _commentError = false);
                        }
                      },
                      decoration: InputDecoration(
                        hintText:
                            'e.g. Good progress — please add a close-up of the west wall.',
                        errorText: _commentError
                            ? 'Add a comment before deciding'
                            : null,
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
        if (canDecide)
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.rule)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FilledButton(
                  onPressed: widget.busy
                      ? null
                      : () => _decide(ReviewDecision.approve),
                  child: widget.busy
                      ? const SizedBox.square(
                          dimension: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: AppColors.paper,
                          ),
                        )
                      : Text('Approve ${m.title}'),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: widget.busy
                            ? null
                            : () => _decide(ReviewDecision.requestChanges),
                        child: const Text('Request changes'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: widget.busy
                            ? null
                            : () => _decide(ReviewDecision.flag),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.flagged,
                          side: const BorderSide(
                            color: AppColors.flagged,
                            width: 1.5,
                          ),
                        ),
                        icon: const Icon(Icons.flag_outlined, size: 18),
                        label: const Text('Flag'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Statement extends StatelessWidget {
  const _Statement({required this.evidence, this.by});

  final Evidence evidence;
  final String? by;

  @override
  Widget build(BuildContext context) => AppCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '"${evidence.description}"',
          style: AppTextStyles.displayM.copyWith(
            fontSize: 21,
            fontWeight: FontWeight.w400,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          '${by ?? 'Site manager'}, site manager',
          style: AppTextStyles.caption.copyWith(color: AppColors.ink2),
        ),
      ],
    ),
  );
}

class _MediaSection extends StatelessWidget {
  const _MediaSection({required this.evidence});

  final Evidence evidence;

  void _openAll(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.8,
      builder: (context, controller) => GridView.count(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        crossAxisCount: 2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        children: [
          for (final url in evidence.siteMediaUrls) MediaTile.fromUrl(url),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final urls = evidence.siteMediaUrls;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionLabel(
          'Site photos & video',
          action: 'See all ${urls.length}',
          onAction: () => _openAll(context),
        ),
        if (urls.isNotEmpty)
          SizedBox(
            height: 236,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 2,
                  child: MediaTile.fromUrl(
                    urls[0],
                    onTap: () => _openAll(context),
                  ),
                ),
                if (urls.length > 1) ...[
                  const SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: MediaTile.fromUrl(
                            urls[1],
                            onTap: () => _openAll(context),
                          ),
                        ),
                        if (urls.length > 2) ...[
                          const SizedBox(height: 6),
                          Expanded(
                            child: MediaTile.fromUrl(
                              urls[2],
                              onTap: () => _openAll(context),
                              overlayText: urls.length > 3
                                  ? '+${urls.length - 3}'
                                  : null,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(
              Icons.photo_camera_outlined,
              size: 14,
              color: AppColors.ink2,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Camera-only — gallery uploads aren\'t possible for site media.',
                style: AppTextStyles.small.copyWith(color: AppColors.ink2),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _WhereWhen extends StatelessWidget {
  const _WhereWhen({
    required this.evidence,
    required this.milestone,
    required this.ctx,
  });

  final Evidence evidence;
  final Milestone milestone;
  final ReviewContext ctx;

  @override
  Widget build(BuildContext context) {
    final e = evidence;
    final distance = distanceInMetres(
      e.capturedLatitude,
      e.capturedLongitude,
      ctx.project.latitude,
      ctx.project.longitude,
    );
    final onSite = distance <= onSiteRadiusMetres;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionLabel('Where & when'),
        _PinComparison(onSite: onSite),
        const SizedBox(height: 10),
        ProofTable(
          rows: [
            (
              'GPS',
              Formatters.coordinates(e.capturedLatitude, e.capturedLongitude),
            ),
            ('CAPTURED', Formatters.proofTimestamp(e.capturedAt)),
          ],
          footer: (
            onSite ? 'ON SITE' : 'OFF SITE',
            '${distance.round()} M FROM PIN',
            onSite,
          ),
        ),
      ],
    );
  }
}

/// Schematic of the capture point against the project pin.
class _PinComparison extends StatelessWidget {
  const _PinComparison({required this.onSite});

  final bool onSite;

  @override
  Widget build(BuildContext context) => Container(
    height: 88,
    decoration: BoxDecoration(
      color: const Color(0xFFEFE6D6),
      borderRadius: BorderRadius.circular(AppDimensions.radiusControl),
      border: Border.all(color: AppColors.controlBorder),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _legend(
          Icons.camera_alt,
          onSite ? AppColors.approved : AppColors.changes,
          'Captured',
        ),
        const SizedBox(width: 32),
        _legend(Icons.location_on, AppColors.laterite, 'Project pin'),
      ],
    ),
  );

  Widget _legend(IconData icon, Color color, String label) => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(icon, color: color, size: 26),
      const SizedBox(height: 4),
      Text(label, style: AppTextStyles.small.copyWith(color: AppColors.ink2)),
    ],
  );
}

class _Spending extends StatelessWidget {
  const _Spending({required this.evidence, required this.currency});

  final Evidence evidence;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final e = evidence;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionLabel('Spending'),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Total spent',
                      style: AppTextStyles.body.copyWith(color: AppColors.ink2),
                    ),
                  ),
                  Text(
                    e.totalCostSpent == null
                        ? '—'
                        : Formatters.money(
                            e.totalCostSpent!,
                            currency: currency,
                          ),
                    style: AppTextStyles.mono(size: 15, letterSpacing: 0),
                  ),
                ],
              ),
              if (e.expenditureNotes != null) ...[
                const SizedBox(height: 10),
                Text('"${e.expenditureNotes}"', style: AppTextStyles.body),
              ],
              if (e.receiptMediaUrls.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final url in e.receiptMediaUrls)
                      ReceiptChip(
                        name: Uri.tryParse(url)?.pathSegments.lastOrNull ?? url,
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _DecisionRecord extends StatelessWidget {
  const _DecisionRecord({required this.review});

  final ReviewSummary review;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: review.decision.tone.background,
      borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${switch (review.decision) {
            ReviewDecision.approve => 'You approved this',
            ReviewDecision.requestChanges => 'You requested changes',
            ReviewDecision.flag => 'You flagged this',
          }} · ${Formatters.timeAndDay(review.reviewedAt)}',
          style: AppTextStyles.label.copyWith(
            color: review.decision.tone.foreground,
          ),
        ),
        const SizedBox(height: 6),
        Text('"${review.comment}"', style: AppTextStyles.body),
        const SizedBox(height: 6),
        Text(
          'Evidence is immutable — corrections come as a new submission.',
          style: AppTextStyles.small.copyWith(color: AppColors.ink2),
        ),
      ],
    ),
  );
}
