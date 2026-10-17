import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';
import 'hatched_box.dart';
import 'status_chip.dart';

/// One phase of the budget ledger: its weight (planned money) and status.
class LedgerSegment {
  const LedgerSegment({required this.weight, required this.tone});

  final double weight;
  final StatusTone tone;
}

/// The segmented "planned → approved / in review" bar used on project cards.
class LedgerBar extends StatelessWidget {
  const LedgerBar({super.key, required this.segments, this.height = 12});

  final List<LedgerSegment> segments;
  final double height;

  @override
  Widget build(BuildContext context) {
    final total = segments.fold<double>(0, (sum, s) => sum + s.weight);
    if (segments.isEmpty || total <= 0) {
      return Container(
        height: height,
        decoration: BoxDecoration(
          color: AppColors.rule,
          borderRadius: BorderRadius.circular(3),
        ),
      );
    }
    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < segments.length; i++) ...[
            if (i > 0) const SizedBox(width: 3),
            Expanded(
              flex: (segments[i].weight / total * 1000).round().clamp(1, 1000),
              child: _segment(segments[i], i == 0, i == segments.length - 1),
            ),
          ],
        ],
      ),
    );
  }

  Widget _segment(LedgerSegment s, bool first, bool last) {
    final radius = BorderRadius.horizontal(
      left: first ? const Radius.circular(3) : Radius.zero,
      right: last ? const Radius.circular(3) : Radius.zero,
    );
    return switch (s.tone) {
      StatusTone.approved => Container(
        decoration: BoxDecoration(
          color: AppColors.approved,
          borderRadius: radius,
        ),
      ),
      StatusTone.awaiting => HatchedBox(
        background: AppColors.awaitingBg,
        stripe: const Color(0x59234E78),
        stripeWidth: 3,
        gap: 5,
        borderRadius: radius,
        border: Border.all(color: AppColors.awaiting, width: 1.5),
      ),
      StatusTone.changes || StatusTone.flagged => Container(
        decoration: BoxDecoration(
          color: s.tone.background,
          borderRadius: radius,
          border: Border.all(color: s.tone.foreground, width: 1.5),
        ),
      ),
      _ => Container(
        decoration: BoxDecoration(color: AppColors.rule, borderRadius: radius),
      ),
    };
  }
}
