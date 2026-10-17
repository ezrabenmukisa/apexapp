import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/geo.dart';
import '../../../../core/utils/snackbar.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/common.dart';
import '../../../../core/widgets/form_fields.dart';
import '../../../../core/widgets/labeled_field.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../domain/entities/evidence.dart';
import '../bloc/evidence_cubits.dart';
import '../widgets/media_tiles.dart';

/// Site manager 09: one unified submission — media, notes, spending and
/// receipts — queued encrypted on the phone and sent when there is signal.
class SubmitEvidencePage extends StatefulWidget {
  const SubmitEvidencePage({super.key});

  @override
  State<SubmitEvidencePage> createState() => _SubmitEvidencePageState();
}

class _SubmitEvidencePageState extends State<SubmitEvidencePage> {
  final _formKey = GlobalKey<FormState>();
  final _description = TextEditingController();
  final _spent = TextEditingController();
  final _notes = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    for (final c in [_description, _spent, _notes]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    final draftState = context.read<EvidenceDraftCubit>().state;
    final assignment = context.read<SiteCubit>().state.data?.assignment;
    final milestone = assignment?.current;
    if (assignment == null || milestone == null) return;
    if (draftState.media.isEmpty) {
      return context.showMessage('Capture at least one site photo or video.');
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);
    final notes = _notes.text.trim();
    final result = await context.read<OutboxCubit>().submit((
      draft: EvidenceDraft(
        milestoneId: milestone.milestoneId,
        description: _description.text.trim(),
        siteMedia: draftState.media,
        receipts: draftState.receipts,
        expenditureNotes: notes.isEmpty ? null : notes,
        totalCostSpent: MoneyField.parse(_spent),
      ),
      milestoneTitle: milestone.title,
      projectName: assignment.project.projectName,
      ownerName: assignment.ownerName,
    ));
    if (!mounted) return;
    setState(() => _submitting = false);
    result.match((f) => context.showMessage(f.message), (_) {
      context.read<EvidenceDraftCubit>().clear();
      final offline = context.read<OutboxCubit>().state.offline;
      context.showMessage(
        offline
            ? 'Saved on this phone. It\'ll send when you\'re back online.'
            : 'Sending to ${assignment.ownerName}…',
      );
      context.go(AppRoutes.siteQueue);
    });
  }

  @override
  Widget build(BuildContext context) {
    final draft = context.watch<EvidenceDraftCubit>().state;
    final assignment = context.watch<SiteCubit>().state.data?.assignment;
    final offline = context.select((OutboxCubit c) => c.state.offline);
    final milestone = assignment?.current;
    final owner = assignment?.ownerName ?? 'the owner';
    final first = draft.media.firstOrNull;
    final distance = first == null || assignment == null
        ? null
        : distanceInMetres(
            first.fix.latitude,
            first.fix.longitude,
            assignment.project.latitude,
            assignment.project.longitude,
          );

    return Scaffold(
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  children: [
                    BackHeader(
                      breadcrumb: milestone == null
                          ? null
                          : '${milestone.title} · milestone ${milestone.sequence}',
                    ),
                    const SizedBox(height: 8),
                    const PageTitle('Submit evidence'),
                    const SizedBox(height: 20),
                    SectionLabel(
                      'Site photos & video · ${draft.media.length}',
                      action: '+ Camera',
                      onAction: () =>
                          context.pushReplacement(AppRoutes.siteCapture),
                    ),
                    _MediaGrid(
                      media: draft.media,
                      onRemove: context.read<EvidenceDraftCubit>().removeMedia,
                    ),
                    if (first != null) ...[
                      const SizedBox(height: 12),
                      ProofTable(
                        rows: [
                          (
                            'CAPTURED',
                            Formatters.proofTimestamp(first.fix.timestamp),
                          ),
                          (
                            'GPS',
                            Formatters.coordinates(
                              first.fix.latitude,
                              first.fix.longitude,
                            ),
                          ),
                        ],
                        footer: distance == null
                            ? null
                            : (
                                distance <= onSiteRadiusMetres
                                    ? 'ON SITE'
                                    : '${distance.round()} M FROM PIN',
                                'LOCKED AT SHUTTER',
                                distance <= onSiteRadiusMetres,
                              ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    LabeledField(
                      label: 'What was done',
                      child: TextFormField(
                        controller: _description,
                        minLines: 3,
                        maxLines: 6,
                        textCapitalization: TextCapitalization.sentences,
                        validator: (v) => (v?.trim().isEmpty ?? true)
                            ? 'Describe the work done'
                            : null,
                        decoration: InputDecoration(
                          hintText: milestone?.description == null
                              ? 'Describe the work done this visit'
                              : 'Brief: ${milestone!.description}',
                          hintMaxLines: 3,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text.rich(
                      TextSpan(
                        text: 'Spending',
                        children: [
                          TextSpan(
                            text: ' (optional)',
                            style: AppTextStyles.label.copyWith(
                              fontWeight: FontWeight.w400,
                              color: AppColors.ink3,
                            ),
                          ),
                        ],
                      ),
                      style: AppTextStyles.label.copyWith(fontSize: 16),
                    ),
                    const SizedBox(height: 10),
                    LabeledField(
                      label: 'Total spent on this milestone',
                      child: MoneyField(
                        controller: _spent,
                        currency: assignment?.project.currency ?? 'UGX',
                      ),
                    ),
                    const SizedBox(height: 14),
                    LabeledField(
                      label: 'Spending notes',
                      child: TextFormField(
                        controller: _notes,
                        minLines: 2,
                        maxLines: 4,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          hintText: 'e.g. bricks, cement, labour weeks 5–8',
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text('Receipts & invoices', style: AppTextStyles.label),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        for (final r in draft.receipts)
                          ReceiptChip(
                            name: r.name,
                            onRemove: () => context
                                .read<EvidenceDraftCubit>()
                                .removeReceipt(r.id),
                          ),
                        DashedBorder(
                          child: TextButton(
                            onPressed: context
                                .read<EvidenceDraftCubit>()
                                .addReceipt,
                            style: TextButton.styleFrom(
                              minimumSize: const Size(0, 44),
                            ),
                            child: const Text('+ Camera, photos or PDF'),
                          ),
                        ),
                      ],
                    ),
                    if (offline) ...[
                      const SizedBox(height: 20),
                      const _OfflineNote(),
                    ],
                    const SizedBox(height: 16),
                    Text(
                      'You can\'t edit this after sending. To correct it, submit again.',
                      style: AppTextStyles.small.copyWith(
                        color: AppColors.ink2,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: PrimaryButton(
                  label: 'Submit to $owner',
                  loading: _submitting,
                  onPressed: draft.media.isEmpty ? null : _submit,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MediaGrid extends StatelessWidget {
  const _MediaGrid({required this.media, required this.onRemove});

  final List<CapturedMedia> media;
  final ValueChanged<String> onRemove;

  static const _maxTiles = 8;

  @override
  Widget build(BuildContext context) {
    if (media.isEmpty) {
      return AppCard(
        child: Text(
          'Nothing captured yet. Use the camera — gallery photos aren\'t accepted for site media.',
          style: AppTextStyles.body.copyWith(color: AppColors.ink2),
        ),
      );
    }
    final overflow = media.length - _maxTiles;
    final shown = overflow > 0 ? media.take(_maxTiles - 1).toList() : media;
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 6,
      crossAxisSpacing: 6,
      children: [
        for (final m in shown)
          Stack(
            fit: StackFit.expand,
            children: [
              MediaTile.fromCapture(m),
              Positioned(
                top: 0,
                right: 0,
                child: IconButton(
                  tooltip: 'Remove',
                  visualDensity: VisualDensity.compact,
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.surface.withValues(alpha: 0.85),
                  ),
                  onPressed: () => onRemove(m.id),
                  icon: const Icon(Icons.close, size: 14),
                ),
              ),
            ],
          ),
        if (overflow > 0)
          Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.sunk,
              borderRadius: BorderRadius.circular(AppDimensions.radiusControl),
            ),
            child: Text('+${overflow + 1}', style: AppTextStyles.title),
          ),
      ],
    );
  }
}

class _OfflineNote extends StatelessWidget {
  const _OfflineNote();

  @override
  Widget build(BuildContext context) => DashedBorder(
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.sunk,
        borderRadius: BorderRadius.circular(AppDimensions.radiusControl),
      ),
      child: Row(
        children: [
          const Icon(Icons.signal_cellular_off, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'No signal. It\'ll be encrypted on this phone and sent when you\'re back online.',
              style: AppTextStyles.caption,
            ),
          ),
        ],
      ),
    ),
  );
}
