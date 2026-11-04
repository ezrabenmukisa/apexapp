import 'package:material_ui/material_ui.dart';

import '../../../../core/widgets/apex_logo.dart';

/// Shown while the session is being resolved at start-up.
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) => const Scaffold(
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ApexLogo(),
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
