import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/apex_logo.dart';
import '../bloc/auth_bloc.dart';

/// Signed in to Firebase, but the Apex backend couldn't be reached.
class SessionErrorPage extends StatelessWidget {
  const SessionErrorPage({super.key});

  @override
  Widget build(BuildContext context) {
    final failure = context.select((AuthBloc b) => b.state.failure);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Align(alignment: Alignment.centerLeft, child: ApexLogo()),
              const Spacer(),
              Text(
                'We couldn\'t open your account',
                style: AppTextStyles.displayM,
              ),
              const SizedBox(height: 12),
              Text(
                failure?.message ?? 'Something went wrong. Please try again.',
                style: AppTextStyles.bodyLarge.copyWith(color: AppColors.ink2),
              ),
              const Spacer(),
              FilledButton(
                onPressed: () =>
                    context.read<AuthBloc>().add(const AuthRetryRequested()),
                child: const Text('Try again'),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () =>
                    context.read<AuthBloc>().add(const AuthSignOutRequested()),
                child: const Text('Sign out'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
