import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/error_mapper.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/usecases/auth_usecases.dart';

enum SignInOptionsStatus { idle, signingInWithGoogle, signedIn }

final class SignInOptionsState extends Equatable {
  const SignInOptionsState({
    this.status = SignInOptionsStatus.idle,
    this.error,
  });

  final SignInOptionsStatus status;
  final String? error;

  bool get isBusy => status != SignInOptionsStatus.idle;

  @override
  List<Object?> get props => [status, error];
}

/// "Continue with Google". Phone and email have their own screens.
///
/// On success Firebase's auth stream fires and `AuthBloc` navigates.
@injectable
class SignInOptionsCubit extends Cubit<SignInOptionsState> {
  SignInOptionsCubit(this._signInWithGoogle)
    : super(const SignInOptionsState());

  final SignInWithGoogle _signInWithGoogle;

  Future<void> continueWithGoogle() async {
    if (state.isBusy) return;
    emit(
      const SignInOptionsState(status: SignInOptionsStatus.signingInWithGoogle),
    );
    final result = await _signInWithGoogle(const NoParams());
    if (isClosed) return;
    emit(
      result.match(
        (failure) => SignInOptionsState(
          // Dismissing the account picker is not an error.
          error: failure is AuthFailure && failure.code == authCancelledCode
              ? null
              : failure.message,
        ),
        (_) => const SignInOptionsState(status: SignInOptionsStatus.signedIn),
      ),
    );
  }
}
