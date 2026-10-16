part of 'auth_bloc.dart';

sealed class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Start listening to Firebase. Dispatch once at app start.
final class AuthSubscriptionRequested extends AuthEvent {
  const AuthSubscriptionRequested();
}

final class _AuthIdentityChanged extends AuthEvent {
  const _AuthIdentityChanged(this.identity);

  final AuthIdentity? identity;

  @override
  List<Object?> get props => [identity];
}

/// Retry the backend session after a failure.
final class AuthRetryRequested extends AuthEvent {
  const AuthRetryRequested();
}

/// Welcome screen choice ("I was added to a project" → manager),
/// used to preselect the role on Complete Profile.
final class AuthRoleHintSelected extends AuthEvent {
  const AuthRoleHintSelected(this.role);

  final UserRole role;

  @override
  List<Object?> get props => [role];
}

/// Complete Profile saved successfully.
final class AuthProfileCompleted extends AuthEvent {
  const AuthProfileCompleted(this.user);

  final AppUser user;

  @override
  List<Object?> get props => [user];
}

final class AuthSignOutRequested extends AuthEvent {
  const AuthSignOutRequested();
}
