/// REST paths from the Apex API contract, relative to `AppConfig.apiBaseUrl`.
abstract final class ApiEndpoints {
  // 1. User and access management
  static const authFirebase = '/auth/firebase';
  static const me = '/users/me';
  static String projectMembers(String projectId) =>
      '/projects/$projectId/members';
  static String projectMember(String projectId, String userId) =>
      '/projects/$projectId/members/$userId';

  // 2. Project management
  static const projects = '/projects';
  static String project(String projectId) => '/projects/$projectId';

  // 3. Milestone management
  static String projectMilestones(String projectId) =>
      '/projects/$projectId/milestones';
  static String milestone(String milestoneId) => '/milestones/$milestoneId';

  // 4. Progress evidence management
  static String milestoneEvidence(String milestoneId) =>
      '/milestones/$milestoneId/evidence';
  static String evidenceReviews(String evidenceId) =>
      '/evidence/$evidenceId/reviews';

  // 5. Notifications
  static const notifications = '/notifications';
  static String notification(String notificationId) =>
      '/notifications/$notificationId';
  static const pushToken = '/devices/push-token';
}
