import '../../features/auth/domain/entities/user_role.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import 'app_routes.dart';

/// Where to send the user for [state], or null to stay on [location].
///
/// Implements the onboarding guard: a signed-in user whose profile is
/// incomplete can only see Complete Profile.
String? authRedirect(AuthState state, String location) {
  switch (state.status) {
    case AuthStatus.unknown:
      return location == AppRoutes.splash ? null : AppRoutes.splash;
    case AuthStatus.unauthenticated:
      return AppRoutes.signedOut.contains(location) ? null : AppRoutes.welcome;
    case AuthStatus.sessionError:
      return location == AppRoutes.sessionError ? null : AppRoutes.sessionError;
    case AuthStatus.needsProfile:
      return location == AppRoutes.completeProfile
          ? null
          : AppRoutes.completeProfile;
    case AuthStatus.authenticated:
      final role = state.user?.userRole;
      final home = homeFor(role);
      final otherRoot = role == UserRole.manager
          ? AppRoutes.ownerRoot
          : AppRoutes.siteRoot;
      final onAuthFlow =
          location == AppRoutes.splash ||
          location == AppRoutes.sessionError ||
          location == AppRoutes.completeProfile ||
          location == AppRoutes.ownerRoot ||
          location == AppRoutes.siteRoot ||
          AppRoutes.signedOut.contains(location);
      if (onAuthFlow || location.startsWith(otherRoot)) return home;
      return null;
  }
}

String homeFor(UserRole? role) =>
    role == UserRole.manager ? AppRoutes.siteToday : AppRoutes.ownerProjects;
