import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/snackbar.dart';
import '../../../../core/widgets/common.dart';
import '../../../../core/widgets/labeled_field.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/complete_profile_cubit.dart';
import '../../../auth/presentation/utils/validators.dart';

/// Edit name and contact details (`PATCH /users/me`). The role stays as is.
class EditProfilePage extends StatelessWidget {
  const EditProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthBloc>().state.user;
    if (user == null) return const SizedBox.shrink();
    return BlocProvider(
      create: (_) {
        final cubit = getIt<CompleteProfileCubit>();
        if (user.userRole != null) cubit.roleSelected(user.userRole!);
        return cubit;
      },
      child: _EditProfileForm(user: user),
    );
  }
}

class _EditProfileForm extends StatefulWidget {
  const _EditProfileForm({required this.user});

  final AppUser user;

  @override
  State<_EditProfileForm> createState() => _EditProfileFormState();
}

class _EditProfileFormState extends State<_EditProfileForm> {
  final _formKey = GlobalKey<FormState>();
  late final _first = TextEditingController(text: widget.user.firstName);
  late final _middle = TextEditingController(text: widget.user.middleName);
  late final _last = TextEditingController(text: widget.user.lastName);
  late final _email = TextEditingController(text: widget.user.contactEmail);
  late final _phone = TextEditingController(text: widget.user.contactPhone);

  @override
  void dispose() {
    for (final c in [_first, _middle, _last, _email, _phone]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(
    BuildContext context,
  ) => BlocConsumer<CompleteProfileCubit, CompleteProfileState>(
    listener: (context, state) {
      if (state.error != null) context.showMessage(state.error!);
      if (state.savedUser case final user?
          when state.status == CompleteProfileStatus.saved) {
        context.read<AuthBloc>().add(AuthProfileCompleted(user));
        context.showMessage('Profile updated.');
        context.pop();
      }
    },
    builder: (context, state) => Scaffold(
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  children: [
                    const BackHeader(),
                    Text('Edit profile', style: AppTextStyles.displayL),
                    const SizedBox(height: 18),
                    LabeledField(
                      label: 'First name',
                      child: TextFormField(
                        controller: _first,
                        textCapitalization: TextCapitalization.words,
                        validator: (v) => Validators.required(v, 'first name'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    LabeledField(
                      label: 'Middle',
                      optional: true,
                      child: TextFormField(
                        controller: _middle,
                        textCapitalization: TextCapitalization.words,
                      ),
                    ),
                    const SizedBox(height: 16),
                    LabeledField(
                      label: 'Last name',
                      child: TextFormField(
                        controller: _last,
                        textCapitalization: TextCapitalization.words,
                        validator: (v) => Validators.required(v, 'last name'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    LabeledField(
                      label: 'Email',
                      helper:
                          'Projects are shared by email — use the one people will invite you with.',
                      child: TextFormField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        validator: Validators.email,
                      ),
                    ),
                    const SizedBox(height: 16),
                    LabeledField(
                      label: 'Phone',
                      optional: true,
                      child: TextFormField(
                        controller: _phone,
                        keyboardType: TextInputType.phone,
                        validator: Validators.optionalPhone,
                        style: AppTextStyles.mono(size: 15, letterSpacing: 0),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: PrimaryButton(
                  label: 'Save',
                  loading: state.isSubmitting,
                  onPressed: () {
                    if (!_formKey.currentState!.validate()) return;
                    context.read<CompleteProfileCubit>().submit(
                      firstName: _first.text,
                      middleName: _middle.text,
                      lastName: _last.text,
                      email: _email.text,
                      phone: _phone.text,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
