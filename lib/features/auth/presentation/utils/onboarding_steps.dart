import '../../domain/entities/user_role.dart';

/// Onboarding length per role.
///
/// Owners: phone → profile → create project → milestones → add site manager.
/// Site managers: phone → profile, then they land on the project they were
/// added to.
abstract final class OnboardingSteps {
  static int total(UserRole? role) => role == UserRole.manager ? 2 : 5;
}
