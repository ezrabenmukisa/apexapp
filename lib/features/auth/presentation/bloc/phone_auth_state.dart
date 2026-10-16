part of 'phone_auth_cubit.dart';

enum PhoneAuthStatus {
  enteringNumber,
  sendingCode,
  codeSent,
  verifying,
  verified,
}

final class PhoneAuthState extends Equatable {
  const PhoneAuthState({
    required this.country,
    this.nationalNumber = '',
    this.status = PhoneAuthStatus.enteringNumber,
    this.verificationId,
    this.resendToken,
    this.sentTo,
    this.resendIn = 0,
    this.error,
  });

  const PhoneAuthState.initial() : this(country: Country.uganda);

  final Country country;
  final String nationalNumber;
  final PhoneAuthStatus status;
  final String? verificationId;
  final int? resendToken;

  /// E.164 number the current code was sent to.
  final String? sentTo;

  /// Seconds until a new code may be requested.
  final int resendIn;
  final String? error;

  String get _digits => nationalNumber.replaceAll(RegExp(r'\D'), '');

  /// Number in E.164, dropping a leading trunk `0` (e.g. UG `0772…`).
  String get e164 =>
      '${country.dialCode}${_digits.replaceFirst(RegExp('^0+'), '')}';

  bool get isNumberValid => _digits.length >= 6 && _digits.length <= 14;

  bool get isBusy =>
      status == PhoneAuthStatus.sendingCode ||
      status == PhoneAuthStatus.verifying ||
      status == PhoneAuthStatus.verified;

  bool get hasCode => verificationId != null;

  /// Number changed since the last code was sent.
  bool get numberEdited => sentTo != null && sentTo != e164;

  bool get canSendCode =>
      isNumberValid && !isBusy && (numberEdited || !hasCode || resendIn == 0);

  PhoneAuthState copyWith({
    Country? country,
    String? nationalNumber,
    PhoneAuthStatus? status,
    String? verificationId,
    int? resendToken,
    String? sentTo,
    int? resendIn,
    String? error,
    bool clearError = false,
  }) => PhoneAuthState(
    country: country ?? this.country,
    nationalNumber: nationalNumber ?? this.nationalNumber,
    status: status ?? this.status,
    verificationId: verificationId ?? this.verificationId,
    resendToken: resendToken ?? this.resendToken,
    sentTo: sentTo ?? this.sentTo,
    resendIn: resendIn ?? this.resendIn,
    error: clearError ? null : (error ?? this.error),
  );

  @override
  List<Object?> get props => [
    country,
    nationalNumber,
    status,
    verificationId,
    resendToken,
    sentTo,
    resendIn,
    error,
  ];
}
