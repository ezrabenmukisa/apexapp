import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/snackbar.dart';
import '../../../../core/widgets/onboarding_scaffold.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/sign_in_options_cubit.dart';
import '../utils/onboarding_steps.dart';
import '../widgets/legal_footnote.dart';

/// Step 1: choose how to sign in. One flow for new and returning users.
class SignInOptionsPage extends StatelessWidget {
  const SignInOptionsPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => getIt<SignInOptionsCubit>(),
    child: const _SignInOptionsView(),
  );
}

class _SignInOptionsView extends StatelessWidget {
  const _SignInOptionsView();

  @override
  Widget build(BuildContext context) {
    final roleHint = context.select((AuthBloc b) => b.state.roleHint);
    return BlocConsumer<SignInOptionsCubit, SignInOptionsState>(
      listenWhen: (a, b) => b.error != null && a.error != b.error,
      listener: (context, state) => context.showMessage(state.error!),
      builder: (context, state) {
        final googleBusy = state.status != SignInOptionsStatus.idle;
        return OnboardingScaffold(
          step: 1,
          totalSteps: OnboardingSteps.total(roleHint),
          footer: const LegalFootnote(),
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Sign in to Siteproof', style: AppTextStyles.displayL),
                const SizedBox(height: 8),
                Text(
                  'One sign-in for new and returning users. Use the account '
                  'people will invite you with.',
                  style: AppTextStyles.body.copyWith(color: AppColors.ink2),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ProviderButton(
                  label: 'Continue with Google',
                  icon: SvgPicture.asset(
                    'assets/icons/google_g.svg',
                    width: 20,
                    height: 20,
                  ),
                  loading: googleBusy,
                  onPressed: state.isBusy
                      ? null
                      : context.read<SignInOptionsCubit>().continueWithGoogle,
                ),
                const SizedBox(height: 10),
                _ProviderButton(
                  label: 'Continue with phone',
                  icon: const Icon(Icons.phone_iphone, size: 20),
                  onPressed: state.isBusy
                      ? null
                      : () => context.push(AppRoutes.signInPhone),
                ),
                const SizedBox(height: 10),
                _ProviderButton(
                  label: 'Continue with email',
                  icon: const Icon(Icons.mail_outline, size: 20),
                  onPressed: state.isBusy
                      ? null
                      : () => context.push(AppRoutes.signInEmail),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _ProviderButton extends StatelessWidget {
  const _ProviderButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.loading = false,
  });

  final String label;
  final Widget icon;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) => OutlinedButton(
    onPressed: onPressed,
    style: OutlinedButton.styleFrom(
      backgroundColor: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16),
    ),
    child: Row(
      children: [
        SizedBox.square(
          dimension: 24,
          child: Center(
            child: loading
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : icon,
          ),
        ),
        Expanded(child: Text(label, textAlign: TextAlign.center)),
        // Balances the leading icon so the label stays centred.
        const SizedBox(width: 24),
      ],
    ),
  );
}
