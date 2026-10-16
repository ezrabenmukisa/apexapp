import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';
import '../theme/app_text_styles.dart';

/// Uppercase section heading, e.g. "YOUR PROJECTS", with an optional action.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.action, this.onAction});

  final String text;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      children: [
        Expanded(
          child: Text(
            text.toUpperCase(),
            style: AppTextStyles.small.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: AppColors.ink2,
            ),
          ),
        ),
        if (action != null) LinkText(action!, onTap: onAction),
      ],
    ),
  );
}

/// Underlined laterite text link ("+ New project", "See all 10").
class LinkText extends StatelessWidget {
  const LinkText(
    this.text, {
    super.key,
    this.onTap,
    this.color = AppColors.laterite,
  });

  final String text;
  final VoidCallback? onTap;
  final Color color;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 40),
      child: Align(
        widthFactor: 1,
        child: Text(
          text,
          style: AppTextStyles.label.copyWith(
            color: color,
            decoration: TextDecoration.underline,
            decorationColor: color,
          ),
        ),
      ),
    ),
  );
}

/// Round initials avatar ("KB", "S"). The only fully round element.
class InitialsAvatar extends StatelessWidget {
  const InitialsAvatar(
    this.initials, {
    super.key,
    this.size = 40,
    this.background = AppColors.lateriteTint,
    this.foreground = AppColors.lateriteDeep,
  });

  final String initials;
  final double size;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: BoxDecoration(color: background, shape: BoxShape.circle),
    child: Text(
      initials,
      style: AppTextStyles.label.copyWith(
        color: foreground,
        fontSize: size * 0.36,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

/// Tappable list row: title, optional subtitle, trailing value and chevron.
class ListRow extends StatelessWidget {
  const ListRow({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.chevron = true,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool chevron;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 52),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: 12)],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title, style: AppTextStyles.bodyLarge),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.ink2,
                      ),
                    ),
                ],
              ),
            ),
            ?trailing,
            if (chevron && onTap != null) ...[
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, size: 20, color: AppColors.ink2),
            ],
          ],
        ),
      ),
    ),
  );
}

/// Screen title block: Newsreader heading with optional subtitle.
class PageTitle extends StatelessWidget {
  const PageTitle(this.title, {super.key, this.subtitle, this.eyebrow});

  final String title;
  final String? subtitle;

  /// Mono caps line above the title ("MILESTONE 02 OF 04 · …").
  final String? eyebrow;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (eyebrow != null) ...[
        Text(eyebrow!, style: AppTextStyles.stepLabel),
        const SizedBox(height: 8),
      ],
      Text(
        title,
        style: AppTextStyles.displayL.copyWith(fontSize: 36, height: 40 / 36),
      ),
      if (subtitle != null) ...[
        const SizedBox(height: 4),
        Text(
          subtitle!,
          style: AppTextStyles.body.copyWith(color: AppColors.ink2),
        ),
      ],
    ],
  );
}

/// Back arrow + breadcrumb ("← Four-bedroom house"), with optional actions.
class BackHeader extends StatelessWidget {
  const BackHeader({
    super.key,
    this.breadcrumb,
    this.onBack,
    this.close = false,
    this.actions = const [],
  });

  final String? breadcrumb;
  final VoidCallback? onBack;
  final bool close;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 48,
    child: Row(
      children: [
        Transform.translate(
          offset: const Offset(-12, 0),
          child: IconButton(
            tooltip: close ? 'Close' : 'Back',
            onPressed: onBack ?? () => Navigator.of(context).maybePop(),
            icon: Icon(close ? Icons.close : Icons.arrow_back, size: 22),
          ),
        ),
        if (breadcrumb != null)
          Expanded(
            child: Transform.translate(
              offset: const Offset(-8, 0),
              child: Text(
                breadcrumb!,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.body.copyWith(color: AppColors.ink2),
              ),
            ),
          )
        else
          const Spacer(),
        ...actions,
      ],
    ),
  );
}

/// Centered message for empty lists and errors, with an optional action.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    this.message,
    this.icon,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? message;
  final IconData? icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 8),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 32, color: AppColors.ink3),
          const SizedBox(height: 12),
        ],
        Text(title, style: AppTextStyles.title, textAlign: TextAlign.center),
        if (message != null) ...[
          const SizedBox(height: 6),
          Text(
            message!,
            style: AppTextStyles.body.copyWith(color: AppColors.ink2),
            textAlign: TextAlign.center,
          ),
        ],
        if (actionLabel != null) ...[
          const SizedBox(height: 16),
          OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      ],
    ),
  );
}

/// Shown while a screen loads its data.
class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) => const Center(
    child: SizedBox.square(
      dimension: 24,
      child: CircularProgressIndicator(strokeWidth: 2),
    ),
  );
}

/// Error with a retry button.
class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: EmptyState(
      icon: Icons.cloud_off_outlined,
      title: 'Couldn\'t load this',
      message: message,
      actionLabel: 'Try again',
      onAction: onRetry,
    ),
  );
}

/// Mono key/value rows for machine-recorded proof (GPS, timestamps).
class ProofTable extends StatelessWidget {
  const ProofTable({super.key, required this.rows, this.footer});

  final List<(String, String)> rows;

  /// Highlighted last row, e.g. ("ON SITE", "LOCKED AT SHUTTER").
  final (String, String, bool)? footer;

  @override
  Widget build(BuildContext context) {
    final meta = AppTextStyles.mono(color: AppColors.ink3, letterSpacing: 0.04);
    final value = AppTextStyles.mono(letterSpacing: 0.04);
    Widget row(String k, String v, {Color? bg, Color? fg}) => Container(
      color: bg,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Text(k, style: fg == null ? meta : meta.copyWith(color: fg)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              v,
              textAlign: TextAlign.right,
              style: fg == null ? value : value.copyWith(color: fg),
            ),
          ),
        ],
      ),
    );
    final f = footer;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.ink, width: 1.2),
        borderRadius: BorderRadius.circular(AppDimensions.radiusControl),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const Divider(),
            row(rows[i].$1, rows[i].$2),
          ],
          if (f != null) ...[
            const Divider(),
            row(
              f.$1,
              f.$2,
              bg: f.$3 ? AppColors.approvedBg : AppColors.changesBg,
              fg: f.$3 ? AppColors.approved : AppColors.changes,
            ),
          ],
        ],
      ),
    );
  }
}

/// Segmented two-or-more option toggle ("Photo | Video", "English | Luganda").
class SegmentedChoice<T> extends StatelessWidget {
  const SegmentedChoice({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  final Map<T, String> options;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      for (final (i, entry) in options.entries.indexed) ...[
        if (i > 0) const SizedBox(width: 8),
        Expanded(
          child: Semantics(
            selected: entry.key == selected,
            button: true,
            child: OutlinedButton(
              onPressed: () => onChanged(entry.key),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(AppDimensions.inputHeight),
                backgroundColor: AppColors.surface,
                side: BorderSide(
                  color: entry.key == selected
                      ? AppColors.ink
                      : AppColors.controlBorder,
                  width: entry.key == selected ? 2 : 1,
                ),
              ),
              child: Text(entry.value),
            ),
          ),
        ),
      ],
    ],
  );
}
