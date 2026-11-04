import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/common.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../../account/presentation/bloc/settings_cubit.dart';
import '../../../account/presentation/widgets/account_widgets.dart';
import '../../../milestones/presentation/utils/status_ui.dart';
import '../../domain/entities/evidence.dart';
import '../../domain/entities/outbox_item.dart';
import '../bloc/evidence_cubits.dart';

/// Site manager 10: what's waiting for signal and what happened to past
/// submissions.
class QueuePage extends StatelessWidget {
  const QueuePage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<OutboxCubit>().state;
    final settings = context.watch<SettingsCubit>();
    final pending = state.pending;
    final sent = state.sent;
    final waitingForWifi =
        state.network != null &&
        state.network!.online &&
        !state.network!.onWifi &&
        settings.state.videoOnWifiOnly &&
        pending.any((i) => i.draft.hasVideo);

    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: context.read<OutboxCubit>().syncNow,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                children: [
                  const PageTitle(
                    'Queue',
                    subtitle:
                        'Submissions waiting for signal, and what happened to past ones',
                  ),
                  const SizedBox(height: 16),
                  if (state.offline)
                    const _Banner(
                      icon: Icons.signal_cellular_off,
                      bold: 'Offline.',
                      text: ' Sends automatically when you\'re connected.',
                    )
                  else if (waitingForWifi)
                    const _Banner(
                      icon: Icons.wifi_off,
                      bold: 'Waiting for Wi-Fi.',
                      text: ' Video uploads are set to Wi-Fi only.',
                    ),
                  const SizedBox(height: 20),
                  SectionLabel('Waiting · ${pending.length}'),
                  if (pending.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        'Nothing waiting. New submissions appear here until they reach the server.',
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.ink2,
                        ),
                      ),
                    ),
                  for (final item in pending) ...[
                    _PendingCard(item: item),
                    const SizedBox(height: 10),
                  ],
                  const SizedBox(height: 16),
                  const SectionLabel('Sent'),
                  if (sent.isEmpty)
                    Text(
                      'Nothing sent from this phone yet.',
                      style: AppTextStyles.body.copyWith(color: AppColors.ink2),
                    )
                  else
                    AppCardList(
                      children: [for (final item in sent) _SentRow(item: item)],
                    ),
                ],
              ),
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.rule)),
            ),
            child: SwitchRow(
              title: 'Upload video on Wi-Fi only',
              subtitle: 'Holds the whole submission until Wi-Fi',
              value: settings.state.videoOnWifiOnly,
              onChanged: (v) async {
                await settings.update((s) => s.copyWith(videoOnWifiOnly: v));
                if (context.mounted) {
                  await context.read<OutboxCubit>().syncNow();
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.icon, required this.bold, required this.text});

  final IconData icon;
  final String bold;
  final String text;

  @override
  Widget build(BuildContext context) => DashedBorder(
    radius: AppDimensions.radiusCard,
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.sunk,
        borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
      ),
      child: Row(
        children: [
          Icon(icon, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: bold,
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextSpan(text: text),
                ],
              ),
              style: AppTextStyles.body,
            ),
          ),
        ],
      ),
    ),
  );
}

class _PendingCard extends StatelessWidget {
  const _PendingCard({required this.item});

  final OutboxItem item;

  @override
  Widget build(BuildContext context) {
    final d = item.draft;
    final sending = item.status == OutboxStatus.sending;
    final failed = item.status == OutboxStatus.failed;
    final parts = [
      '${d.siteMedia.length} site media',
      if (d.receipts.isNotEmpty)
        '${d.receipts.length} receipt${d.receipts.length == 1 ? '' : 's'}',
      'notes',
    ];
    return AppCard(
      dashed: !failed,
      borderColor: failed ? AppColors.flagged : AppColors.rule,
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
                      '${item.milestoneTitle} evidence',
                      style: AppTextStyles.title.copyWith(fontSize: 17),
                    ),
                    Text(
                      parts.join(', '),
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.ink2,
                      ),
                    ),
                  ],
                ),
              ),
              StatusChip(
                label: failed
                    ? 'Failed'
                    : (sending ? 'Sending' : 'Pending sync'),
                tone: failed ? StatusTone.flagged : StatusTone.pendingSync,
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: sending ? null : 0,
              minHeight: 6,
              backgroundColor: AppColors.rule,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            failed
                ? (item.error ?? 'Couldn\'t send. Pull down to retry.')
                : 'CAPTURED ${Formatters.time(d.fix.timestamp)} · ENCRYPTED ON THIS PHONE',
            style: failed
                ? AppTextStyles.caption.copyWith(color: AppColors.flagged)
                : AppTextStyles.mono(color: AppColors.ink2, size: 11),
          ),
        ],
      ),
    );
  }
}

class _SentRow extends StatelessWidget {
  const _SentRow({required this.item});

  final OutboxItem item;

  @override
  Widget build(BuildContext context) {
    final outcome = item.outcome ?? EvidenceStatus.submitted;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${item.milestoneTitle} evidence',
                  style: AppTextStyles.label.copyWith(fontSize: 16),
                ),
                Text(
                  'SENT ${Formatters.dayMonth(item.sentAt ?? item.queuedAt).toUpperCase()}',
                  style: AppTextStyles.mono(color: AppColors.ink2, size: 11),
                ),
              ],
            ),
          ),
          StatusChip(label: outcome.label, tone: outcome.tone),
        ],
      ),
    );
  }
}
