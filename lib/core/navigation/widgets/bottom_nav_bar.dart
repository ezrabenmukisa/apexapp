import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class NavItem {
  const NavItem(this.label, this.icon, {this.count = 0});

  final String label;
  final IconData icon;

  /// Shown as "Review · 1".
  final int count;
}

/// Owner bottom navigation: an ink rule marks the active tab.
class BottomNavBar extends StatelessWidget {
  const BottomNavBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  final List<NavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      color: AppColors.surface,
      border: Border(top: BorderSide(color: AppColors.rule)),
    ),
    child: SafeArea(
      top: false,
      child: SizedBox(
        height: 64,
        child: Row(
          children: [
            for (final (i, item) in items.indexed)
              Expanded(child: _tab(item, i == currentIndex, () => onTap(i))),
          ],
        ),
      ),
    ),
  );

  Widget _tab(NavItem item, bool active, VoidCallback onTap) {
    final color = active ? AppColors.ink : AppColors.ink2;
    final label = item.count > 0 ? '${item.label} · ${item.count}' : item.label;
    return Semantics(
      selected: active,
      button: true,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: Column(
          children: [
            Container(
              height: 2,
              margin: const EdgeInsets.symmetric(horizontal: 12),
              color: active ? AppColors.laterite : Colors.transparent,
            ),
            const Spacer(),
            Icon(item.icon, size: 22, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTextStyles.small.copyWith(
                color: color,
                fontWeight: active ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}

/// Site manager bar: dark, with a raised laterite capture button — the one
/// action that matters most on site.
class SiteBottomBar extends StatelessWidget {
  const SiteBottomBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.onCapture,
    this.queueCount = 0,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback onCapture;
  final int queueCount;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 96 + MediaQuery.paddingOf(context).bottom,
    child: Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.bottomCenter,
      children: [
        Container(
          height: 72 + MediaQuery.paddingOf(context).bottom,
          color: AppColors.ink,
          padding: EdgeInsets.only(
            bottom: MediaQuery.paddingOf(context).bottom,
          ),
          child: Row(
            children: [
              Expanded(child: _tab(0, 'Today', Icons.calendar_today_outlined)),
              const SizedBox(width: 96),
              Expanded(
                child: _tab(
                  1,
                  queueCount > 0 ? 'Queue · $queueCount' : 'Queue',
                  Icons.download_outlined,
                ),
              ),
            ],
          ),
        ),
        Positioned(
          top: 0,
          child: Semantics(
            button: true,
            label: 'Capture evidence',
            excludeSemantics: true,
            child: Material(
              color: AppColors.laterite,
              shape: const CircleBorder(
                side: BorderSide(color: AppColors.surface, width: 4),
              ),
              elevation: 4,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onCapture,
                child: const SizedBox.square(
                  dimension: 72,
                  child: Icon(
                    Icons.photo_camera_outlined,
                    color: AppColors.surface,
                    size: 30,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _tab(int index, String label, IconData icon) {
    final active = index == currentIndex;
    final color = active
        ? AppColors.surface
        : AppColors.rule.withValues(alpha: 0.7);
    return Semantics(
      selected: active,
      button: true,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        onTap: () => onTap(index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTextStyles.small.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
