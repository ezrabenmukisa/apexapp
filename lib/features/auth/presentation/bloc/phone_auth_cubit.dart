import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../domain/entities/phone_verification.dart';
import '../../domain/usecases/auth_usecases.dart';
import '../utils/country.dart';

part 'phone_auth_state.dart';

/// Phone number entry, SMS code request/resend and verification.
///
/// On success Firebase's auth stream fires and `AuthBloc` takes over
/// navigation, so this cubit never navigates itself.
@injectable
class PhoneAuthCubit extends Cubit<PhoneAuthState> {
  PhoneAuthCubit(this._sendPhoneCode, this._confirmPhoneCode)
    : super(const PhoneAuthState.initial());

  final SendPhoneCode _sendPhoneCode;
  final ConfirmPhoneCode _confirmPhoneCode;
  Timer? _resendTimer;

  static const resendCooldown = 60;

  void countryChanged(Country country) =>
      emit(state.copyWith(country: country, clearError: true));

  void numberChanged(String number) =>
      emit(state.copyWith(nationalNumber: number, clearError: true));

  Future<void> sendCode() async {
    if (!state.canSendCode) return;
    final phone = state.e164;
    final resendToken = phone == state.sentTo ? state.resendToken : null;
    emit(state.copyWith(status: PhoneAuthStatus.sendingCode, clearError: true));

    final result = await _sendPhoneCode((
      phoneNumber: phone,
      resendToken: resendToken,
    ));
    if (isClosed) return;
    switch (result) {
      case Left(value: final failure):
        emit(
          state.copyWith(
            status: state.hasCode
                ? PhoneAuthStatus.codeSent
                : PhoneAuthStatus.enteringNumber,
            error: failure.message,
          ),
        );
      case Right(value: SmsCodeSent(:final verificationId, :final resendToken)):
        emit(
          state.copyWith(
            status: PhoneAuthStatus.codeSent,
            verificationId: verificationId,
            resendToken: resendToken,
            sentTo: phone,
          ),
        );
        _startResendTimer();
      case Right(value: PhoneAutoVerified()):
        emit(state.copyWith(status: PhoneAuthStatus.verified));
    }
  }

  Future<void> verify(String code) async {
    final verificationId = state.verificationId;
    if (verificationId == null || code.length != 6 || state.isBusy) return;
    emit(state.copyWith(status: PhoneAuthStatus.verifying, clearError: true));

    final result = await _confirmPhoneCode((
      verificationId: verificationId,
      smsCode: code,
    ));
    if (isClosed) return;
    emit(
      result.match(
        (failure) => state.copyWith(
          status: PhoneAuthStatus.codeSent,
          error: failure.message,
        ),
        (_) => state.copyWith(status: PhoneAuthStatus.verified),
      ),
    );
  }

  void _startResendTimer() {
    _resendTimer?.cancel();
    emit(state.copyWith(resendIn: resendCooldown));
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final next = state.resendIn - 1;
      emit(state.copyWith(resendIn: next < 0 ? 0 : next));
      if (next <= 0) timer.cancel();
    });
  }

  @override
  Future<void> close() {
    _resendTimer?.cancel();
    return super.close();
  }
}
