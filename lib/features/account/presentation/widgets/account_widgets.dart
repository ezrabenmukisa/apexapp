import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/common.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';

/// "Email · sarah@example.com" style row.
class KeyValueRow extends StatelessWidget {
  const KeyValueRow(this.label, this.value, {super.key, this.mono = false});

  final String label;
  final String value;
  final bool mono;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    child: Row(
      children: [
        Text(label, style: AppTextStyles.body.copyWith(color: AppColors.ink2)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
            style: mono
                ? AppTextStyles.mono(size: 13, letterSpacing: 0)
                : AppTextStyles.body,
          ),
        ),
      ],
    ),
  );
}

/// Title with a checkbox (the prototype uses ink checkboxes, not switches).
class SwitchRow extends StatelessWidget {
  const SwitchRow({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => MergeSemantics(
    child: ListRow(
      title: title,
      subtitle: subtitle,
      chevron: false,
      onTap: () => onChanged(!value),
      trailing: Checkbox(
        value: value,
        onChanged: (v) => onChanged(v ?? false),
        activeColor: AppColors.ink,
        checkColor: AppColors.surface,
        side: const BorderSide(color: AppColors.ink, width: 1.5),
      ),
    ),
  );
}

/// Permission row value: "Allowed" in green, or an Allow button.
class PermissionValue extends StatelessWidget {
  const PermissionValue({
    super.key,
    required this.granted,
    required this.onAllow,
    this.filled = false,
  });

  final bool granted;
  final VoidCallback onAllow;
  final bool filled;

  @override
  Widget build(BuildContext context) => granted
      ? Text(
          'Allowed',
          style: AppTextStyles.caption.copyWith(
            color: AppColors.approved,
            fontWeight: FontWeight.w700,
          ),
        )
      : filled
      ? FilledButton(
          onPressed: onAllow,
          style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
          child: const Text('Allow'),
        )
      : OutlinedButton(
          onPressed: onAllow,
          style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44)),
          child: const Text('Allow'),
        );
}

class SignOutLink extends StatelessWidget {
  const SignOutLink({super.key});

  @override
  Widget build(BuildContext context) => Center(
    child: LinkText(
      'Sign out',
      onTap: () => context.read<AuthBloc>().add(const AuthSignOutRequested()),
    ),
  );
}

Future<void> showInfoSheet(BuildContext context, String title, String body) =>
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.title),
              const SizedBox(height: 12),
              Text(body, style: AppTextStyles.body),
            ],
          ),
        ),
      ),
    );

const helpText =
    'Owners plan a project, split it into milestones and review the evidence '
    'the site manager sends. Site managers capture photos and video on site — '
    'each stamped with GPS and time — and submit them per milestone. '
    'Questions? Contact the Apex team.';

const privacyText =
    'Your location is only recorded when you capture evidence — never in the '
    'background. Evidence is shared only with people on the same project. '
    'Submissions waiting for signal are encrypted on this phone.';
