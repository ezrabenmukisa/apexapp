import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Diagonal-hatched fill used for photo placeholders and "in review" bars.
class HatchedBox extends StatelessWidget {
  const HatchedBox({
    super.key,
    this.background = AppColors.placeholder,
    this.stripe = const Color(0x121F1B16),
    this.stripeWidth = 2,
    this.gap = 8,
    this.borderRadius = BorderRadius.zero,
    this.border,
    this.child,
  });

  final Color background;
  final Color stripe;
  final double stripeWidth;
  final double gap;
  final BorderRadius borderRadius;
  final BoxBorder? border;
  final Widget? child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(borderRadius: borderRadius, border: border),
    child: ClipRRect(
      borderRadius: borderRadius,
      child: CustomPaint(
        painter: _HatchPainter(background, stripe, stripeWidth, gap),
        child: child,
      ),
    ),
  );
}

class _HatchPainter extends CustomPainter {
  const _HatchPainter(this.background, this.stripe, this.width, this.gap);

  final Color background;
  final Color stripe;
  final double width;
  final double gap;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = background);
    final paint = Paint()
      ..color = stripe
      ..strokeWidth = width;
    final step = width + gap;
    for (var x = -size.height; x < size.width; x += step) {
      canvas.drawLine(
        Offset(x, size.height),
        Offset(x + size.height, 0),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_HatchPainter old) =>
      old.background != background || old.stripe != stripe;
}
