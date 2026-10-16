import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/snackbar.dart';
import '../../../../core/widgets/labeled_field.dart';
import '../../../../core/widgets/onboarding_scaffold.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../domain/entities/user_role.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/complete_profile_cubit.dart';
import '../utils/onboarding_steps.dart';
import '../utils/validators.dart';
import '../widgets/role_option_card.dart';

/// Onboarding 13, step 2. The router forces users here while the backend
/// reports `profile_complete: false`.
class CompleteProfilePage extends StatelessWidget {
  const CompleteProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthBloc>().state;
    return BlocProvider(
      create: (_) {
        final cubit = getIt<CompleteProfileCubit>();
        final role = auth.user?.userRole ?? auth.roleHint;
        if (role != null) cubit.roleSelected(role);
        return cubit;
      },
      child: const _CompleteProfileView(),
    );
  }
}

class _CompleteProfileView extends StatefulWidget {
  const _CompleteProfileView();

  @override
  State<_CompleteProfileView> createState() => _CompleteProfileViewState();
}

class _CompleteProfileViewState extends State<_CompleteProfileView> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _first;
  late final TextEditingController _middle;
  late final TextEditingController _last;
  late final TextEditingController _email;
  late final TextEditingController _phone;

  /// Phone sign-in already proved this number, so it is read-only.
  late final bool _phoneVerified;

  @override
  void initState() {
    super.initState();
    final identity = context.read<AuthBloc>().state.identity;
    _first = TextEditingController();
    _middle = TextEditingController();
    _last = TextEditingController();
    _email = TextEditingController(text: identity?.email);
    _phone = TextEditingController(text: identity?.phoneNumber);
    _phoneVerified = identity?.phoneNumber?.isNotEmpty ?? false;
  }

  @override
  void dispose() {
    for (final c in [_first, _middle, _last, _email, _phone]) {
      c.dispose();
    }
    super.dispose();
  }

  void _submit() {
    final cubit = context.read<CompleteProfileCubit>();
    final formValid = _formKey.currentState!.validate();
    final roleValid = cubit.validateRole();
    if (!formValid || !roleValid) return;
    cubit.submit(
      firstName: _first.text,
      middleName: _middle.text,
      lastName: _last.text,
      email: _email.text,
      phone: _phone.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CompleteProfileCubit, CompleteProfileState>(
      listener: (context, state) {
        if (state.error != null) context.showMessage(state.error!);
        if (state.savedUser case final user?
            when state.status == CompleteProfileStatus.saved) {
          context.read<AuthBloc>().add(AuthProfileCompleted(user));
        }
      },
      builder: (context, state) => Form(
        key: _formKey,
        child: OnboardingScaffold(
          step: 2,
          totalSteps: OnboardingSteps.total(state.role),
          onBack: () =>
              context.read<AuthBloc>().add(const AuthSignOutRequested()),
          gap: 16,
          footer: PrimaryButton(
            label: 'Continue',
            loading:
                state.isSubmitting ||
                state.status == CompleteProfileStatus.saved,
            onPressed: _submit,
          ),
          children: [
            Text(
              'Complete your profile',
              style: AppTextStyles.displayL.copyWith(
                fontSize: 30,
                height: 34 / 30,
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: LabeledField(
                    label: 'First name',
                    child: TextFormField(
                      controller: _first,
                      textCapitalization: TextCapitalization.words,
                      autofillHints: const [AutofillHints.givenName],
                      textInputAction: TextInputAction.next,
                      validator: (v) => Validators.required(v, 'first name'),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: LabeledField(
                    label: 'Middle',
                    optional: true,
                    child: TextFormField(
                      controller: _middle,
                      textCapitalization: TextCapitalization.words,
                      autofillHints: const [AutofillHints.middleName],
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                ),
              ],
            ),
            LabeledField(
              label: 'Last name',
              child: TextFormField(
                controller: _last,
                textCapitalization: TextCapitalization.words,
                autofillHints: const [AutofillHints.familyName],
                textInputAction: TextInputAction.next,
                validator: (v) => Validators.required(v, 'last name'),
              ),
            ),
            LabeledField(
              label: 'Email',
              helper:
                  'Projects are shared by email — use the one people will invite you with.',
              child: TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                textInputAction: TextInputAction.next,
                validator: Validators.email,
              ),
            ),
            LabeledField(
              label: 'Phone',
              optional: !_phoneVerified,
              child: TextFormField(
                controller: _phone,
                readOnly: _phoneVerified,
                keyboardType: TextInputType.phone,
                autofillHints: const [AutofillHints.telephoneNumber],
                validator: Validators.optionalPhone,
                style: AppTextStyles.mono(size: 15, letterSpacing: 0),
                decoration: InputDecoration(
                  hintText: '+256 772 123456',
                  fillColor: _phoneVerified ? AppColors.sunk : null,
                  suffixIcon: _phoneVerified
                      ? const Tooltip(
                          message: 'Verified by SMS',
                          child: Icon(
                            Icons.verified_outlined,
                            size: 18,
                            color: AppColors.approved,
                          ),
                        )
                      : null,
                ),
              ),
            ),
            _RolePicker(
              selected: state.role,
              showError: state.showRoleError,
              onSelected: context.read<CompleteProfileCubit>().roleSelected,
            ),
          ],
        ),
      ),
    );
  }
}

class _RolePicker extends StatelessWidget {
  const _RolePicker({
    required this.selected,
    required this.showError,
    required this.onSelected,
  });

  final UserRole? selected;
  final bool showError;
  final ValueChanged<UserRole> onSelected;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text('I\'m the…', style: AppTextStyles.label),
      const SizedBox(height: 8),
      IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: RoleOptionCard(
                title: 'Owner',
                description: 'Plan the project and review evidence',
                selected: selected == UserRole.owner,
                error: showError,
                onTap: () => onSelected(UserRole.owner),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: RoleOptionCard(
                title: 'Site manager',
                description: 'Submit evidence from site',
                selected: selected == UserRole.manager,
                error: showError,
                onTap: () => onSelected(UserRole.manager),
              ),
            ),
          ],
        ),
      ),
      if (showError) ...[
        const SizedBox(height: 6),
        Text(
          'Choose how you\'ll use Siteproof',
          style: AppTextStyles.small.copyWith(color: AppColors.flagged),
        ),
      ],
    ],
  );
}
