abstract final class AppRoutes {
  static const splash = '/';
  static const welcome = '/welcome';

  /// Continue with Google / phone / email.
  static const signIn = '/sign-in';
  static const signInPhone = '/sign-in/phone';
  static const signInEmail = '/sign-in/email';
  static const completeProfile = '/onboarding/profile';
  static const sessionError = '/session-error';
  static const editProfile = '/profile/edit';

  /// Routes reachable while signed out.
  static const signedOut = {welcome, signIn, signInPhone, signInEmail};

  // ---- Owner (bottom nav: Projects · Review · Inbox · Account)
  static const ownerRoot = '/owner';
  static const ownerProjects = '/owner/projects';
  static const ownerReview = '/owner/review';
  static const ownerInbox = '/owner/inbox';
  static const ownerAccount = '/owner/account';

  static const newProject = '/owner/projects/new';
  static String project(String id) => '/owner/projects/$id';
  static String projectEdit(String id) => '/owner/projects/$id/edit';
  static String projectSettings(String id) => '/owner/projects/$id/settings';

  /// [setup] shows the onboarding step header and "Next" footer.
  static String projectPlan(String id, {bool setup = false}) =>
      '/owner/projects/$id/plan${setup ? '?setup=1' : ''}';
  static String projectTeam(String id, {bool setup = false}) =>
      '/owner/projects/$id/team${setup ? '?setup=1' : ''}';
  static String newMilestone(String projectId) =>
      '/owner/projects/$projectId/milestones/new';
  static String editMilestone(String projectId, String milestoneId) =>
      '/owner/projects/$projectId/milestones/$milestoneId';
  static String review(String projectId, String milestoneId) =>
      '/owner/projects/$projectId/review/$milestoneId';

  // ---- Site manager (bottom bar: Today · capture · Queue)
  static const siteRoot = '/site';
  static const siteToday = '/site/today';
  static const siteQueue = '/site/queue';
  static const siteCapture = '/site/capture';
  static const siteSubmit = '/site/submit';
  static const siteAccount = '/site/account';
  static const siteJoin = '/site/welcome';
}
