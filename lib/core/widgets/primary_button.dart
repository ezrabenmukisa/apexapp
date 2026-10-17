import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';

/// Full-width ink button that shows a spinner while [loading].
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) => FilledButton(
    onPressed: loading ? null : onPressed,
    style: loading
        ? FilledButton.styleFrom(
            disabledBackgroundColor: AppColors.ink,
            disabledForegroundColor: AppColors.paper,
          )
        : null,
    child: loading
        ? const SizedBox.square(
            dimension: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              color: AppColors.paper,
            ),
          )
        : Text(label),
  );
}
