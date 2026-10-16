import 'package:flutter/material.dart';

import '../../../../core/widgets/siteproof_mark.dart';

/// Shown while the session is being resolved at start-up.
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) => const Scaffold(
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SiteproofLogo(),
          SizedBox(height: 32),
          SizedBox.square(
            dimension: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ],
      ),
    ),
  );
}
