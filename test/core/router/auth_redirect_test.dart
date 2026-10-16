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
      expect(authRedirect(signedOut, AppRoutes.owner), AppRoutes.welcome);
      expect(authRedirect(signedOut, AppRoutes.signIn), isNull);
      expect(authRedirect(signedOut, AppRoutes.signInEmail), isNull);
    });

    test('onboarding guard forces Complete Profile', () {
      for (final location in [
        AppRoutes.splash,
        AppRoutes.signIn,
        AppRoutes.owner,
        AppRoutes.site,
      ]) {
        expect(authRedirect(needsProfile, location), AppRoutes.completeProfile);
      }
      expect(authRedirect(needsProfile, AppRoutes.completeProfile), isNull);
    });

    test('authenticated users land on the home for their role', () {
      expect(authRedirect(owner, AppRoutes.completeProfile), AppRoutes.owner);
      expect(authRedirect(manager, AppRoutes.signIn), AppRoutes.site);
      expect(authRedirect(owner, AppRoutes.owner), isNull);
    });

    test('users cannot open the other role\'s shell', () {
      expect(authRedirect(owner, AppRoutes.site), AppRoutes.owner);
      expect(authRedirect(manager, AppRoutes.owner), AppRoutes.site);
    });
  });
}
