import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class LegalFootnote extends StatelessWidget {
  const LegalFootnote({super.key});

  @override
  Widget build(BuildContext context) {
    final style = AppTextStyles.small.copyWith(color: AppColors.ink3);
    final link = style.copyWith(decoration: TextDecoration.underline);
    return Text.rich(
      TextSpan(
        text: 'By continuing you agree to the ',
        children: [
          TextSpan(text: 'Terms', style: link),
          const TextSpan(text: ' and '),
          TextSpan(text: 'Privacy notice', style: link),
          const TextSpan(text: '.'),
        ],
      ),
      style: style,
      textAlign: TextAlign.center,
    );
  }
}
