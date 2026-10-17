import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Onboarding header: back button, "STEP n OF m" and a segmented progress bar.
class StepHeader extends StatelessWidget {
  const StepHeader({
    super.key,
    required this.step,
    required this.totalSteps,
    this.onBack,
  });

  final int step;
  final int totalSteps;

  /// Defaults to popping the current route when one exists.
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    final back =
        onBack ?? (canPop ? () => Navigator.of(context).maybePop() : null);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Transform.translate(
              offset: const Offset(-12, 0),
              child: SizedBox.square(
                dimension: 48,
                child: back == null
                    ? null
                    : IconButton(
                        tooltip: 'Back',
                        onPressed: back,
                        icon: const Icon(Icons.arrow_back, size: 22),
                      ),
              ),
            ),
            Semantics(
              label: 'Step $step of $totalSteps',
              excludeSemantics: true,
              child: Text(
                'STEP $step OF $totalSteps',
                style: AppTextStyles.stepLabel,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            for (var i = 1; i <= totalSteps; i++) ...[
              if (i > 1) const SizedBox(width: 4),
              Expanded(
                child: Container(
                  height: 3,
                  color: i <= step ? AppColors.ink : AppColors.rule,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
