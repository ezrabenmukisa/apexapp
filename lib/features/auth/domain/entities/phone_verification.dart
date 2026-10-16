import 'package:equatable/equatable.dart';

/// Outcome of requesting an SMS code.
sealed class PhoneVerification extends Equatable {
  const PhoneVerification();

  @override
  List<Object?> get props => [];
}

/// The SMS was sent; the user must enter the code.
final class SmsCodeSent extends PhoneVerification {
  const SmsCodeSent({required this.verificationId, this.resendToken});

  final String verificationId;
  final int? resendToken;

  @override
  List<Object?> get props => [verificationId, resendToken];
}

/// Android read the SMS itself and the user is already signed in.
final class PhoneAutoVerified extends PhoneVerification {
  const PhoneAutoVerified();
}
