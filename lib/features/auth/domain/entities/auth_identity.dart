import 'package:equatable/equatable.dart';

/// Who Firebase says is signed in, before the Apex backend is consulted.
class AuthIdentity extends Equatable {
  const AuthIdentity({required this.uid, this.phoneNumber, this.email});

  final String uid;

  /// E.164, set when the user signed in with a phone code.
  final String? phoneNumber;

  /// Set when the user signed in with email and password.
  final String? email;

  @override
  List<Object?> get props => [uid, phoneNumber, email];
}
