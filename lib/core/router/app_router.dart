import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/pages/complete_profile_page.dart';
import '../../features/auth/presentation/pages/email_sign_in_page.dart';
import '../../features/auth/presentation/pages/phone_sign_in_page.dart';
import '../../features/auth/presentation/pages/session_error_page.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/auth/presentation/pages/welcome_page.dart';
import '../../features/home/presentation/pages/home_placeholder_page.dart';
import 'app_routes.dart';
import 'auth_redirect.dart';

GoRouter createAppRouter(AuthBloc authBloc) => GoRouter(
  initialLocation: AppRoutes.splash,
  refreshListenable: _StreamListenable(authBloc.stream),
  redirect: (context, routerState) =>
      authRedirect(authBloc.state, routerState.matchedLocation),
  routes: [
    GoRoute(path: AppRoutes.splash, builder: (_, _) => const SplashPage()),
    GoRoute(path: AppRoutes.welcome, builder: (_, _) => const WelcomePage()),
    GoRoute(
      path: AppRoutes.signIn,
      builder: (_, _) => const PhoneSignInPage(),
      routes: [
        GoRoute(path: 'email', builder: (_, _) => const EmailSignInPage()),
      ],
    ),
    GoRoute(
      path: AppRoutes.completeProfile,
      builder: (_, _) => const CompleteProfilePage(),
    ),
    GoRoute(
      path: AppRoutes.sessionError,
      builder: (_, _) => const SessionErrorPage(),
    ),
    // Shells are filled in with the prototype screens in the next PR.
    GoRoute(
      path: AppRoutes.owner,
      builder: (_, _) => const HomePlaceholderPage(),
    ),
    GoRoute(
      path: AppRoutes.site,
      builder: (_, _) => const HomePlaceholderPage(),
    ),
  ],
);

/// Re-runs GoRouter redirects whenever the auth state changes.
class _StreamListenable extends ChangeNotifier {
  _StreamListenable(Stream<Object?> stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<Object?> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
