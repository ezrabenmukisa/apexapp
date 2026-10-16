import 'package:flutter/material.dart';

import 'step_header.dart';

/// Layout for numbered onboarding steps: step header, scrolling body and
/// a footer pinned to the bottom (above the keyboard).
class OnboardingScaffold extends StatelessWidget {
  const OnboardingScaffold({
    super.key,
    required this.step,
    required this.totalSteps,
    required this.children,
    required this.footer,
    this.onBack,
    this.gap = 24,
  });

  final int step;
  final int totalSteps;
  final List<Widget> children;
  final Widget footer;
  final VoidCallback? onBack;

  /// Vertical space between [children].
  final double gap;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: StepHeader(
              step: step,
              totalSteps: totalSteps,
              onBack: onBack,
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < children.length; i++) ...[
                    if (i > 0) SizedBox(height: gap),
                    children[i],
                  ],
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: footer,
          ),
        ],
      ),
    ),
  );
}
