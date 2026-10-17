import 'package:equatable/equatable.dart';

/// Who Firebase says is signed in, before the Apex backend is consulted.
class AuthIdentity extends Equatable {
  const AuthIdentity({
    required this.uid,
    this.phoneNumber,
    this.email,
    this.displayName,
  });

  final String uid;

  /// E.164, set when the user signed in with a phone code.
  final String? phoneNumber;

  /// Set for email/password and Google sign-ins.
  final String? email;

  /// From the Google account, used to prefill Complete Profile.
  final String? displayName;

  @override
  List<Object?> get props => [uid, phoneNumber, email, displayName];
}
