abstract final class AppRoutes {
  static const splash = '/';
  static const welcome = '/welcome';

  /// Continue with Google / phone / email.
  static const signIn = '/sign-in';
  static const signInPhone = '/sign-in/phone';
  static const signInEmail = '/sign-in/email';
  static const completeProfile = '/onboarding/profile';
  static const sessionError = '/session-error';

  /// Owner shell root (Projects).
  static const owner = '/owner';

  /// Site manager shell root.
  static const site = '/site';

  /// Routes reachable while signed out.
  static const signedOut = {welcome, signIn, signInPhone, signInEmail};
}
