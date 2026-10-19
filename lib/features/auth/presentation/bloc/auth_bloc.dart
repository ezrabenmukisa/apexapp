import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/entities/auth_identity.dart';
import '../../domain/entities/user_role.dart';
import '../../domain/usecases/auth_usecases.dart';
import '../../domain/usecases/profile_usecases.dart';

part 'auth_event.dart';
part 'auth_state.dart';

/// App-wide session state. The router redirects from [AuthState.status].
///
/// Flow: Firebase identity → `POST /auth/firebase` → if `profile_complete`
/// is false go to Complete Profile, otherwise `GET /users/me` and enter the
/// app.
@lazySingleton
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc(
    this._watchIdentity,
    this._establishSession,
    this._getProfile,
    this._signOut,
  ) : super(const AuthState.unknown()) {
    on<AuthSubscriptionRequested>(_onSubscriptionRequested);
    on<_AuthIdentityChanged>(_onIdentityChanged, transformer: restartable());
    on<AuthRetryRequested>(_onRetryRequested, transformer: restartable());
    on<AuthRoleHintSelected>(_onRoleHintSelected);
    on<AuthProfileCompleted>(_onProfileCompleted);
    on<AuthSignOutRequested>(_onSignOutRequested);
  }

  final WatchAuthIdentity _watchIdentity;
  final EstablishSession _establishSession;
  final GetProfile _getProfile;
  final SignOut _signOut;

  Future<void> _onSubscriptionRequested(
    AuthSubscriptionRequested event,
    Emitter<AuthState> emit,
  ) => emit.onEach(
    _watchIdentity(),
    onData: (identity) => add(_AuthIdentityChanged(identity)),
  );

  Future<void> _onIdentityChanged(
    _AuthIdentityChanged event,
    Emitter<AuthState> emit,
  ) async {
    final identity = event.identity;
    if (identity == null) {
      return emit(AuthState.unauthenticated(roleHint: state.roleHint));
    }
    await _resolveSession(identity, emit);
  }

  Future<void> _onRetryRequested(
    AuthRetryRequested event,
    Emitter<AuthState> emit,
  ) async {
    final identity = state.identity;
    if (identity == null) return;
    emit(state.copyWith(status: AuthStatus.unknown));
    await _resolveSession(identity, emit);
  }

  Future<void> _resolveSession(
    AuthIdentity identity,
    Emitter<AuthState> emit,
  ) async {
    final session = await _establishSession(const NoParams());
    switch (session) {
      case Left(:final value):
        return emit(state.toSessionError(identity, value));
      case Right(value: final s) when !s.profileComplete:
        return emit(state.toNeedsProfile(identity));
      case Right():
        break;
    }

    final profile = await _getProfile(const NoParams());
    emit(
      profile.match(
        (failure) => state.toSessionError(identity, failure),
        (user) => user.userRole == null
            // The API has no user_role yet; on a new phone ask for it once,
            // with the rest of the profile prefilled.
            ? state.toNeedsProfile(identity, user: user)
            : state.toAuthenticated(identity, user),
      ),
    );
  }

  void _onRoleHintSelected(
    AuthRoleHintSelected event,
    Emitter<AuthState> emit,
  ) => emit(state.copyWith(roleHint: event.role));

  void _onProfileCompleted(
    AuthProfileCompleted event,
    Emitter<AuthState> emit,
  ) {
    final identity = state.identity;
    if (identity == null) return;
    emit(state.toAuthenticated(identity, event.user));
  }

  Future<void> _onSignOutRequested(
    AuthSignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    final result = await _signOut(const NoParams());
    // On success the identity stream emits null and we go unauthenticated.
    if (result case Left(:final value)) {
      emit(state.copyWith(failure: value));
    }
  }
}
