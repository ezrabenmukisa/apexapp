import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/bloc/load_view.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/common.dart';
import '../../domain/entities/app_notification.dart';
import '../bloc/inbox_cubit.dart';

/// Owner 06: every update, newest first. Opening one marks it read and
/// shows it from memory.
class InboxPage extends StatefulWidget {
  const InboxPage({super.key});

  @override
  State<InboxPage> createState() => _InboxPageState();
}

class _InboxPageState extends State<InboxPage> {
  bool _unreadOnly = false;

  void _open(AppNotification n) {
    context.read<InboxCubit>().open(n);
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(n.title, style: AppTextStyles.title),
              if (n.createdAt != null) ...[
                const SizedBox(height: 4),
                Text(
                  Formatters.proofTimestamp(n.createdAt!),
                  style: AppTextStyles.stepLabel,
                ),
              ],
              const SizedBox(height: 12),
              Text(n.body, style: AppTextStyles.bodyLarge),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: RefreshIndicator(
      onRefresh: context.read<InboxCubit>().load,
      child: LoadView<InboxCubit, List<AppNotification>>(
        builder: (context, all, _) {
          final unread = all.where((n) => !n.isRead).length;
          final items = _unreadOnly
              ? all.where((n) => !n.isRead).toList()
              : all;
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
            children: [
              const PageTitle(
                'Inbox',
                subtitle: 'Every update on your projects, newest first',
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _FilterChip(
                    label: 'All',
                    selected: !_unreadOnly,
                    onTap: () => setState(() => _unreadOnly = false),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: unread > 0 ? 'Unread · $unread' : 'Unread',
                    selected: _unreadOnly,
                    onTap: () => setState(() => _unreadOnly = true),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (items.isEmpty)
                EmptyState(
                  icon: Icons.notifications_none,
                  title: _unreadOnly ? 'All caught up' : 'No updates yet',
                ),
              for (final n in items)
                n.isRead
                    ? _ReadItem(notification: n, onTap: () => _open(n))
                    : Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: AppCard(
                          onTap: () => _open(n),
                          child: _ItemContent(notification: n),
                        ),
                      ),
            ],
          );
        },
      ),
    ),
  );
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    selected: selected,
    button: true,
    child: Material(
      color: selected ? AppColors.ink : AppColors.surface,
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: selected ? AppColors.ink : AppColors.controlBorder,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Text(
            label,
            style: AppTextStyles.label.copyWith(
              color: selected ? AppColors.surface : AppColors.ink,
            ),
          ),
        ),
      ),
    ),
  );
}

class _ItemContent extends StatelessWidget {
  const _ItemContent({required this.notification});

  final AppNotification notification;

  @override
  Widget build(BuildContext context) {
    final n = notification;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 7),
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: n.isRead ? Colors.transparent : AppColors.laterite,
              shape: BoxShape.circle,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                n.title,
                style: AppTextStyles.label.copyWith(
                  fontSize: 16,
                  fontWeight: n.isRead ? FontWeight.w600 : FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                n.body,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.body.copyWith(color: AppColors.ink2),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ReadItem extends StatelessWidget {
  const _ReadItem({required this.notification, required this.onTap});

  final AppNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.rule)),
      ),
      child: _ItemContent(notification: notification),
    ),
  );
}
