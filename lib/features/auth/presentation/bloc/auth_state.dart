part of 'auth_bloc.dart';

enum AuthStatus {
  /// Start-up, or talking to the backend after Firebase sign-in.
  unknown,

  unauthenticated,

  /// Signed in, but `profile_complete` is false (onboarding guard).
  needsProfile,

  authenticated,

  /// Signed in to Firebase but the backend session could not be set up.
  sessionError,
}

final class AuthState extends Equatable {
  const AuthState._({
    required this.status,
    this.identity,
    this.user,
    this.failure,
    this.roleHint,
  });

  const AuthState.unknown() : this._(status: AuthStatus.unknown);

  const AuthState.unauthenticated({UserRole? roleHint})
    : this._(status: AuthStatus.unauthenticated, roleHint: roleHint);

  final AuthStatus status;
  final AuthIdentity? identity;
  final AppUser? user;
  final Failure? failure;
  final UserRole? roleHint;

  AuthState toNeedsProfile(AuthIdentity identity) => AuthState._(
    status: AuthStatus.needsProfile,
    identity: identity,
    roleHint: roleHint,
  );

  AuthState toAuthenticated(AuthIdentity identity, AppUser user) => AuthState._(
    status: AuthStatus.authenticated,
    identity: identity,
    user: user,
  );

  AuthState toSessionError(AuthIdentity identity, Failure failure) =>
      AuthState._(
        status: AuthStatus.sessionError,
        identity: identity,
        failure: failure,
        roleHint: roleHint,
      );

  AuthState copyWith({
    AuthStatus? status,
    Failure? failure,
    UserRole? roleHint,
  }) => AuthState._(
    status: status ?? this.status,
    identity: identity,
    user: user,
    failure: failure ?? this.failure,
    roleHint: roleHint ?? this.roleHint,
  );

  @override
  List<Object?> get props => [status, identity, user, failure, roleHint];
}
