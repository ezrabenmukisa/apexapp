import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// A form field with the prototype's label-above layout and optional helper.
class LabeledField extends StatelessWidget {
  const LabeledField({
    super.key,
    required this.label,
    required this.child,
    this.optional = false,
    this.helper,
  });

  final String label;
  final Widget child;
  final bool optional;
  final String? helper;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text.rich(
        TextSpan(
          text: label,
          children: [
            if (optional)
              TextSpan(
                text: ' (optional)',
                style: AppTextStyles.label.copyWith(
                  fontWeight: FontWeight.w400,
                  color: AppColors.ink3,
                ),
              ),
          ],
        ),
        style: AppTextStyles.label,
      ),
      const SizedBox(height: 6),
      child,
      if (helper != null) ...[
        const SizedBox(height: 6),
        Text(
          helper!,
          style: AppTextStyles.small.copyWith(color: AppColors.ink3),
        ),
      ],
    ],
  );
}
