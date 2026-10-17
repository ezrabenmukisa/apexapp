import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';

/// Flat surface card with a rule border (no shadow — "a record, not a toy").
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color = AppColors.surface,
    this.borderColor = AppColors.rule,
    this.dashed = false,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  final Color borderColor;

  /// Dashed border marks things that only exist on this phone (pending sync).
  final bool dashed;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppDimensions.radiusCard);
    Widget content = Material(
      color: color,
      shape: dashed
          ? RoundedRectangleBorder(borderRadius: radius)
          : RoundedRectangleBorder(
              borderRadius: radius,
              side: BorderSide(color: borderColor),
            ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
    if (dashed) {
      content = CustomPaint(
        foregroundPainter: _DashedBorderPainter(
          color: AppColors.ink2,
          radius: AppDimensions.radiusCard,
        ),
        child: content,
      );
    }
    return content;
  }
}

/// A card whose children are separated by rule dividers (settings lists,
/// milestone lists).
class AppCardList extends StatelessWidget {
  const AppCardList({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => AppCard(
    padding: EdgeInsets.zero,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const Divider(),
          children[i],
        ],
      ],
    ),
  );
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          Radius.circular(radius),
        ).deflate(0.6),
      );
    for (final metric in path.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += 9) {
        canvas.drawPath(metric.extractPath(d, d + 5), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) => old.color != color;
}

/// Wraps any widget in a dashed rounded border.
class DashedBorder extends StatelessWidget {
  const DashedBorder({
    super.key,
    required this.child,
    this.radius = AppDimensions.radiusControl,
    this.color = AppColors.ink2,
  });

  final Widget child;
  final double radius;
  final Color color;

  @override
  Widget build(BuildContext context) => CustomPaint(
    foregroundPainter: _DashedBorderPainter(color: color, radius: radius),
    child: child,
  );
}
