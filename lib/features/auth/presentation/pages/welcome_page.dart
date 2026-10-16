import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/siteproof_mark.dart';
import '../../domain/entities/user_role.dart';
import '../bloc/auth_bloc.dart';
import '../widgets/welcome_illustration.dart';

/// Onboarding 11: first screen for signed-out users.
class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  void _start(BuildContext context, UserRole hint) {
    context.read<AuthBloc>().add(AuthRoleHintSelected(hint));
    context.push(AppRoutes.signIn);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
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
            const SizedBox(height: 28),
            const Expanded(child: WelcomeIllustration()),
            const SizedBox(height: 28),
            Text(
              'See your project, not just hear about it.',
              style: AppTextStyles.hero,
            ),
            const SizedBox(height: 12),
            Text(
              'Every phase, photo and shilling — stamped with where and when — '
              'before you approve the next stage.',
              style: AppTextStyles.bodyLarge.copyWith(color: AppColors.ink2),
            ),
            const SizedBox(height: 28),
            FilledButton(
              onPressed: () => _start(context, UserRole.owner),
              child: const Text('Get started'),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () => _start(context, UserRole.manager),
              child: const Text('I was added to a project'),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => context.push(AppRoutes.signIn),
              child: const Text('Log in'),
            ),
          ],
        ),
      ),
    ),
  );
}
