import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/hatched_box.dart';

/// Welcome hero: a site photo, a proof ticket and the four-phase ledger bar.
class WelcomeIllustration extends StatelessWidget {
  const WelcomeIllustration({super.key});

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final h = constraints.maxHeight;
      // Collapse to the ledger bar only on very short screens.
      final showPhoto = h > 180;
      return Stack(
        children: [
          if (showPhoto)
            Positioned(
              left: 0,
              top: 8,
              width: constraints.maxWidth * 0.62,
              height: (h - 60).clamp(0, 250),
              child: HatchedBox(
                borderRadius: BorderRadius.circular(14),
                child: Center(
                  child: Text(
                    '[site photo]',
                    style: AppTextStyles.small.copyWith(color: AppColors.ink2),
                  ),
                ),
              ),
            ),
          if (showPhoto)
            Positioned(
              right: 0,
              top: (h - 60).clamp(0, 250) * 0.6,
              width: 210,
              child: const _ProofTicket(),
            ),
          const Positioned(left: 0, right: 0, bottom: 0, child: _PhaseLedger()),
        ],
      );
    },
  );
}

class _ProofTicket extends StatelessWidget {
  const _ProofTicket();

  @override
  Widget build(BuildContext context) {
    final style = AppTextStyles.mono(size: 11, letterSpacing: 0.03);
    final meta = style.copyWith(color: AppColors.ink3);
    Widget row(String k, String v) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.rule)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(k, style: meta),
          Text(v, style: style),
        ],
      ),
    );
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.ink, width: 1.5),
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x591F1B16),
            blurRadius: 28,
            offset: Offset(0, 12),
            spreadRadius: -12,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          row('PHASE', '02 · WALLING'),
          row('GPS', '±6M'),
          row('TIME', '10:42 EAT'),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: const BoxDecoration(
              color: AppColors.approvedBg,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(7)),
            ),
            child: Text(
              'ON SITE ✓',
              style: style.copyWith(color: AppColors.approved),
            ),
          ),
        ],
      ),
    );
  }
}

class _PhaseLedger extends StatelessWidget {
  const _PhaseLedger();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      SizedBox(
        height: 12,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 250,
              child: Container(
                decoration: const BoxDecoration(
                  color: AppColors.approved,
                  borderRadius: BorderRadius.horizontal(
                    left: Radius.circular(3),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 3),
            Expanded(
              flex: 200,
              child: HatchedBox(
                background: AppColors.awaitingBg,
                stripe: const Color(0x59234E78),
                stripeWidth: 3,
                gap: 5,
                border: Border.all(color: AppColors.awaiting, width: 1.5),
              ),
            ),
            const SizedBox(width: 3),
            Expanded(flex: 229, child: Container(color: AppColors.rule)),
            const SizedBox(width: 3),
            Expanded(
              flex: 321,
              child: Container(
                decoration: const BoxDecoration(
                  color: AppColors.rule,
                  borderRadius: BorderRadius.horizontal(
                    right: Radius.circular(3),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 8),
      Text(
        'FOUNDATION · WALLING · ROOFING · FINISHING',
        style: AppTextStyles.mono(
          size: 11,
          color: AppColors.ink3,
          letterSpacing: 0.04,
        ),
      ),
    ],
  );
}
