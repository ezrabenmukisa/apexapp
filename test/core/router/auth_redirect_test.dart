import 'package:app/core/router/app_routes.dart';
import 'package:app/core/router/auth_redirect.dart';
import 'package:app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fixtures.dart';

void main() {
  const unknown = AuthState.unknown();
  const signedOut = AuthState.unauthenticated();
  final needsProfile = signedOut.toNeedsProfile(tIdentity);
  final owner = signedOut.toAuthenticated(tIdentity, tOwner);
  final manager = signedOut.toAuthenticated(tIdentity, tManager);

  group('authRedirect', () {
    test('holds on splash while the session is unknown', () {
      expect(authRedirect(unknown, AppRoutes.welcome), AppRoutes.splash);
      expect(authRedirect(unknown, AppRoutes.splash), isNull);
    });

    test('signed-out users may only see the sign-in flow', () {
      expect(authRedirect(signedOut, AppRoutes.splash), AppRoutes.welcome);
      expect(
        authRedirect(signedOut, AppRoutes.ownerProjects),
        AppRoutes.welcome,
      );
      expect(authRedirect(signedOut, AppRoutes.signIn), isNull);
      expect(authRedirect(signedOut, AppRoutes.signInPhone), isNull);
      expect(authRedirect(signedOut, AppRoutes.signInEmail), isNull);
    });

    test('onboarding guard forces Complete Profile', () {
      for (final location in [
        AppRoutes.splash,
        AppRoutes.signIn,
        AppRoutes.ownerProjects,
        AppRoutes.siteToday,
      ]) {
        expect(authRedirect(needsProfile, location), AppRoutes.completeProfile);
      }
      expect(authRedirect(needsProfile, AppRoutes.completeProfile), isNull);
    });

    test('authenticated users land on the home for their role', () {
      expect(
        authRedirect(owner, AppRoutes.completeProfile),
        AppRoutes.ownerProjects,
      );
      expect(authRedirect(manager, AppRoutes.signIn), AppRoutes.siteToday);
      expect(authRedirect(owner, AppRoutes.ownerProjects), isNull);
    });

    test('users cannot open the other role\'s shell', () {
      expect(authRedirect(owner, AppRoutes.siteToday), AppRoutes.ownerProjects);
      expect(
        authRedirect(manager, AppRoutes.ownerProjects),
        AppRoutes.siteToday,
      );
    });
  });
}
