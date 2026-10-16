import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../domain/usecases/auth_usecases.dart';

enum EmailAuthMode { signIn, signUp }

enum EmailAuthStatus { idle, submitting, success, resetSent }

final class EmailAuthState extends Equatable {
  const EmailAuthState({
    this.mode = EmailAuthMode.signIn,
    this.status = EmailAuthStatus.idle,
    this.error,
  });

  final EmailAuthMode mode;
  final EmailAuthStatus status;
  final String? error;

  bool get isSubmitting => status == EmailAuthStatus.submitting;

  @override
  List<Object?> get props => [mode, status, error];
}

/// "Use email instead": email + password sign-in or account creation.
@injectable
class EmailAuthCubit extends Cubit<EmailAuthState> {
  EmailAuthCubit(this._signIn, this._signUp, this._sendPasswordReset)
    : super(const EmailAuthState());

  final SignInWithEmail _signIn;
  final SignUpWithEmail _signUp;
  final SendPasswordReset _sendPasswordReset;

  void toggleMode() => emit(
    EmailAuthState(
      mode: state.mode == EmailAuthMode.signIn
          ? EmailAuthMode.signUp
          : EmailAuthMode.signIn,
    ),
  );

  Future<void> submit({required String email, required String password}) async {
    if (state.isSubmitting) return;
    emit(EmailAuthState(mode: state.mode, status: EmailAuthStatus.submitting));
    final credentials = (email: email.trim(), password: password);
    final result = state.mode == EmailAuthMode.signIn
        ? await _signIn(credentials)
        : await _signUp(credentials);
    if (isClosed) return;
    emit(
      result.match(
        (failure) => EmailAuthState(mode: state.mode, error: failure.message),
        (_) =>
            EmailAuthState(mode: state.mode, status: EmailAuthStatus.success),
      ),
    );
  }

  Future<void> resetPassword(String email) async {
    if (state.isSubmitting) return;
    emit(EmailAuthState(mode: state.mode, status: EmailAuthStatus.submitting));
    final result = await _sendPasswordReset(email.trim());
    if (isClosed) return;
    emit(
      result.match(
        (failure) => EmailAuthState(mode: state.mode, error: failure.message),
        (_) =>
            EmailAuthState(mode: state.mode, status: EmailAuthStatus.resetSent),
      ),
    );
  }
}
