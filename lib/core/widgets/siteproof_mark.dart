import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// The surveyor's benchmark mark: a level line over a chiselled arrow.
class SiteproofMark extends StatelessWidget {
  const SiteproofMark({
    super.key,
    this.size = 30,
    this.color = AppColors.laterite,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: CustomPaint(painter: _MarkPainter(color)),
  );
}

class _MarkPainter extends CustomPainter {
  const _MarkPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    // Drawn on the prototype's 32×32 grid.
    final s = size.width / 32;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.6 * s
      ..strokeCap = StrokeCap.square
      ..style = PaintingStyle.stroke;
    canvas
      ..drawLine(Offset(3 * s, 7 * s), Offset(29 * s, 7 * s), paint)
      ..drawLine(Offset(16 * s, 8 * s), Offset(6 * s, 27 * s), paint)
      ..drawLine(Offset(16 * s, 8 * s), Offset(26 * s, 27 * s), paint);
  }

  @override
  bool shouldRepaint(_MarkPainter oldDelegate) => oldDelegate.color != color;
}

/// Mark plus "Siteproof" wordmark.
class SiteproofLogo extends StatelessWidget {
  const SiteproofLogo({super.key});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      const SiteproofMark(),
      const SizedBox(width: 10),
      Text('Siteproof', style: AppTextStyles.brand),
    ],
  );
}
