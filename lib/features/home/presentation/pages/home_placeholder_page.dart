import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/siteproof_mark.dart';
import '../../../auth/domain/entities/user_role.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';

/// Temporary landing screen after onboarding until the owner and site
/// manager shells land.
class HomePlaceholderPage extends StatelessWidget {
  const HomePlaceholderPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.select((AuthBloc b) => b.state.user);
    final isOwner = user?.userRole != UserRole.manager;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Align(
                alignment: Alignment.centerLeft,
                child: SiteproofLogo(),
              ),
              const SizedBox(height: 32),
              Text(
                'Welcome, ${user?.firstName ?? ''}',
                style: AppTextStyles.displayM,
              ),
              const SizedBox(height: 8),
              Text(
                isOwner
                    ? 'Signed in as owner. Your projects will appear here.'
                    : 'Signed in as site manager. Projects you were added to will appear here.',
                style: AppTextStyles.bodyLarge.copyWith(color: AppColors.ink2),
              ),
              const SizedBox(height: 16),
              Text(
                [
                  user?.contactEmail,
                  user?.contactPhone,
                ].whereType<String>().join(' · ').toUpperCase(),
                style: AppTextStyles.mono(color: AppColors.ink3),
              ),
              const Spacer(),
              OutlinedButton(
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
