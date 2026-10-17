import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pinput/pinput.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/labeled_field.dart';
import '../../../../core/widgets/onboarding_scaffold.dart';
import '../../../../core/widgets/primary_button.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/phone_auth_cubit.dart';
import '../utils/country.dart';
import '../utils/onboarding_steps.dart';
import '../widgets/country_picker_sheet.dart';
import '../widgets/legal_footnote.dart';

/// Onboarding 12, step 1: "Continue with phone".
class PhoneSignInPage extends StatelessWidget {
  const PhoneSignInPage({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.maybeLocaleOf(context);
    return BlocProvider(
      create: (_) =>
          getIt<PhoneAuthCubit>()
            ..countryChanged(Country.fromIso(locale?.countryCode)),
      child: const _PhoneSignInView(),
    );
  }
}

class _PhoneSignInView extends StatefulWidget {
  const _PhoneSignInView();

  @override
  State<_PhoneSignInView> createState() => _PhoneSignInViewState();
}

class _PhoneSignInViewState extends State<_PhoneSignInView> {
  final _numberController = TextEditingController();
  final _codeController = TextEditingController();
  final _codeFocus = FocusNode();

  @override
  void dispose() {
    _numberController.dispose();
    _codeController.dispose();
    _codeFocus.dispose();
    super.dispose();
  }

  Future<void> _pickCountry(PhoneAuthCubit cubit) async {
    final country = await showCountryPicker(
      context,
      selected: cubit.state.country,
    );
    if (country != null) cubit.countryChanged(country);
  }

  @override
  Widget build(BuildContext context) {
    final roleHint = context.select((AuthBloc b) => b.state.roleHint);
    final cubit = context.read<PhoneAuthCubit>();

    return BlocConsumer<PhoneAuthCubit, PhoneAuthState>(
      listenWhen: (a, b) => a.verificationId != b.verificationId,
      listener: (context, state) {
        _codeController.clear();
        _codeFocus.requestFocus();
      },
      builder: (context, state) {
        final showCode = state.hasCode && !state.numberEdited;
        return OnboardingScaffold(
          step: 1,
          totalSteps: OnboardingSteps.total(roleHint),
          footer: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showCode)
                PrimaryButton(
                  label: 'Verify',
                  loading:
                      state.status == PhoneAuthStatus.verifying ||
                      state.status == PhoneAuthStatus.verified,
                  onPressed: () => cubit.verify(_codeController.text),
                )
              else
                PrimaryButton(
                  label: 'Send code',
                  loading:
                      state.status == PhoneAuthStatus.sendingCode ||
                      state.status == PhoneAuthStatus.verified,
                  onPressed: state.canSendCode ? cubit.sendCode : null,
                ),
              const SizedBox(height: 10),
              const LegalFootnote(),
            ],
          ),
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Your phone number', style: AppTextStyles.displayL),
                const SizedBox(height: 8),
                Text(
                  'One sign-in for new and returning users. We\'ll text a code; '
                  'any country works.',
                  style: AppTextStyles.body.copyWith(color: AppColors.ink2),
                ),
              ],
            ),
            LabeledField(
              label: 'Mobile number',
              child: Row(
                children: [
                  _CountryButton(
                    country: state.country,
                    onPressed: state.isBusy ? null : () => _pickCountry(cubit),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SizedBox(
                      height: AppDimensions.phoneInputHeight,
                      child: TextField(
                        controller: _numberController,
                        enabled: !state.isBusy,
                        keyboardType: TextInputType.phone,
                        autofillHints: const [
                          AutofillHints.telephoneNumberNational,
                        ],
                        textInputAction: TextInputAction.send,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9 ]')),
                          LengthLimitingTextInputFormatter(16),
                        ],
                        style: AppTextStyles.mono(size: 16, letterSpacing: 0),
                        decoration: const InputDecoration(
                          hintText: '772 123 456',
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 16,
                          ),
                        ),
                        onChanged: cubit.numberChanged,
                        onSubmitted: (_) => cubit.sendCode(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (showCode)
              _CodeSection(
                state: state,
                controller: _codeController,
                focusNode: _codeFocus,
                onCompleted: cubit.verify,
                onResend: cubit.sendCode,
              )
            else
              _UseEmailLink(enabled: !state.isBusy),
            if (state.error != null)
              Text(
                state.error!,
                style: AppTextStyles.caption.copyWith(color: AppColors.flagged),
              ),
          ],
        );
      },
    );
  }
}

class _CountryButton extends StatelessWidget {
  const _CountryButton({required this.country, required this.onPressed});

  final Country country;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: 'Country: ${country.name}, ${country.dialCode}',
    excludeSemantics: true,
    child: Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: AppColors.controlBorder),
        borderRadius: BorderRadius.circular(AppDimensions.radiusControl),
      ),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppDimensions.radiusControl),
        child: SizedBox(
          height: AppDimensions.phoneInputHeight,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  country.label,
                  style: AppTextStyles.mono(size: 15, letterSpacing: 0),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.expand_more, size: 16),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _CodeSection extends StatelessWidget {
  const _CodeSection({
    required this.state,
    required this.controller,
    required this.focusNode,
    required this.onCompleted,
    required this.onResend,
  });

  final PhoneAuthState state;
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onCompleted;
  final VoidCallback onResend;

  @override
  Widget build(BuildContext context) {
    final box = PinTheme(
      height: AppDimensions.otpBoxHeight,
      width: double.infinity,
      textStyle: AppTextStyles.mono(size: 22, letterSpacing: 0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.controlBorder),
        borderRadius: BorderRadius.circular(AppDimensions.radiusControl),
      ),
    );
    final focused = box.copyWith(
      decoration: box.decoration!.copyWith(
        border: Border.all(color: AppColors.ink, width: 1.5),
        boxShadow: const [
          BoxShadow(color: AppColors.lateriteTint, spreadRadius: 3),
        ],
      ),
    );
    final meta = AppTextStyles.caption.copyWith(color: AppColors.ink3);

    return Container(
      padding: const EdgeInsets.only(top: 20),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.rule)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Code sent to ${state.sentTo}', style: AppTextStyles.label),
          const SizedBox(height: 10),
          Pinput(
            length: 6,
            controller: controller,
            focusNode: focusNode,
            enabled: !state.isBusy,
            autofocus: true,
            separatorBuilder: (_) => const SizedBox(width: 8),
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            defaultPinTheme: box,
            focusedPinTheme: focused,
            pinputAutovalidateMode: PinputAutovalidateMode.disabled,
            onCompleted: onCompleted,
          ),
          const SizedBox(height: 10),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (state.resendIn > 0)
                Text.rich(
                  TextSpan(
                    text: 'Resend in ',
                    children: [
                      TextSpan(
                        text: _mmss(state.resendIn),
                        style: AppTextStyles.mono(
                          size: 13,
                          color: AppColors.ink3,
                          letterSpacing: 0,
                        ),
                      ),
                    ],
                  ),
                  style: meta,
                )
              else
                _InlineLink(
                  label: 'Resend code',
                  onTap: state.isBusy ? null : onResend,
                ),
              Text(' · ', style: meta),
              _InlineLink(
                label: 'Use email instead',
                onTap: state.isBusy
                    ? null
                    : () => context.push(AppRoutes.signInEmail),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _mmss(int seconds) =>
      '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
}

class _UseEmailLink extends StatelessWidget {
  const _UseEmailLink({required this.enabled});

  final bool enabled;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: _InlineLink(
      label: 'Use email instead',
      onTap: enabled ? () => context.push(AppRoutes.signInEmail) : null,
    ),
  );
}

class _InlineLink extends StatelessWidget {
  const _InlineLink({required this.label, required this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: ConstrainedBox(
      constraints: const BoxConstraints(
        minHeight: AppDimensions.minTouchTarget,
      ),
      child: Align(
        widthFactor: 1,
        child: Text(
          label,
          style: AppTextStyles.caption.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
            decoration: TextDecoration.underline,
          ),
        ),
      ),
    ),
  );
}
