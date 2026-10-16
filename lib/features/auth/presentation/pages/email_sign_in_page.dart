import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/snackbar.dart';
import '../../../../core/widgets/labeled_field.dart';
import '../../../../core/widgets/onboarding_scaffold.dart';
import '../../../../core/widgets/primary_button.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/email_auth_cubit.dart';
import '../utils/onboarding_steps.dart';
import '../utils/validators.dart';
import '../widgets/legal_footnote.dart';

/// "Continue with email": email + password sign-in or account creation.
class EmailSignInPage extends StatelessWidget {
  const EmailSignInPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => getIt<EmailAuthCubit>(),
    child: const _EmailSignInView(),
  );
}

class _EmailSignInView extends StatefulWidget {
  const _EmailSignInView();

  @override
  State<_EmailSignInView> createState() => _EmailSignInViewState();
}

class _EmailSignInViewState extends State<_EmailSignInView> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<EmailAuthCubit>().submit(
      email: _email.text,
      password: _password.text,
    );
  }

  void _resetPassword() {
    final error = Validators.email(_email.text);
    if (error != null) return context.showMessage('Enter your email first.');
    context.read<EmailAuthCubit>().resetPassword(_email.text);
  }

  @override
  Widget build(BuildContext context) {
    final roleHint = context.select((AuthBloc b) => b.state.roleHint);
    return BlocConsumer<EmailAuthCubit, EmailAuthState>(
      listenWhen: (a, b) => a.status != b.status || a.error != b.error,
      listener: (context, state) {
        if (state.error != null) context.showMessage(state.error!);
        if (state.status == EmailAuthStatus.resetSent) {
          context.showMessage(
            'Password reset link sent to ${_email.text.trim()}.',
          );
        }
      },
      builder: (context, state) {
        final isSignUp = state.mode == EmailAuthMode.signUp;
        return Form(
          key: _formKey,
          child: OnboardingScaffold(
            step: 1,
            totalSteps: OnboardingSteps.total(roleHint),
            footer: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                PrimaryButton(
                  label: isSignUp ? 'Create account' : 'Log in',
                  loading:
                      state.isSubmitting ||
                      state.status == EmailAuthStatus.success,
                  onPressed: _submit,
                ),
                const SizedBox(height: 10),
                const LegalFootnote(),
              ],
            ),
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    isSignUp ? 'Create your account' : 'Log in with email',
                    style: AppTextStyles.displayL,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Use the email people will invite you with.',
                    style: AppTextStyles.body.copyWith(color: AppColors.ink2),
                  ),
                ],
              ),
              LabeledField(
                label: 'Email',
                child: TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  textInputAction: TextInputAction.next,
                  validator: Validators.email,
                ),
              ),
              LabeledField(
                label: 'Password',
                helper: isSignUp ? 'At least 6 characters.' : null,
                child: TextFormField(
                  controller: _password,
                  obscureText: _obscure,
                  autofillHints: [
                    isSignUp
                        ? AutofillHints.newPassword
                        : AutofillHints.password,
                  ],
                  textInputAction: TextInputAction.done,
                  validator: Validators.password,
                  onFieldSubmitted: (_) => _submit(),
                  decoration: InputDecoration(
                    suffixIcon: IconButton(
                      tooltip: _obscure ? 'Show password' : 'Hide password',
                      onPressed: () => setState(() => _obscure = !_obscure),
                      icon: Icon(
                        _obscure
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: state.isSubmitting
                        ? null
                        : context.read<EmailAuthCubit>().toggleMode,
                    child: Text(
                      isSignUp
                          ? 'I already have an account'
                          : 'Create an account',
                    ),
                  ),
                  if (!isSignUp)
                    TextButton(
                      onPressed: state.isSubmitting ? null : _resetPassword,
                      child: const Text('Forgot password?'),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
