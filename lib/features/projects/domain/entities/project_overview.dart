import 'package:equatable/equatable.dart';

import '../../../milestones/domain/entities/milestone.dart';
import 'project.dart';

/// A project with its plan, as shown on cards and the detail screen.
class ProjectOverview extends Equatable {
  const ProjectOverview({
    required this.project,
    required this.milestones,
    this.members = const [],
  });

  final Project project;

  /// Sorted by sequence.
  final List<Milestone> milestones;
  final List<ProjectMember> members;

  double get approvedAmount =>
      milestones.sumWhere((m) => m.status == MilestoneStatus.approved);

  double get inReviewAmount =>
      milestones.sumWhere((m) => m.status == MilestoneStatus.submitted);

  /// Planned project budget, or the sum of milestone budgets.
  double get totalAmount =>
      project.plannedBudget ?? milestones.sumWhere((_) => true);

  double get allocatedAmount => milestones.sumWhere((_) => true);

  double get approvedShare =>
      totalAmount <= 0 ? 0 : (approvedAmount / totalAmount).clamp(0, 1);

  Milestone? get current => milestones.current;

  /// 1-based phase number of [current] (or the last when all approved).
  int get phaseNumber => current?.sequence ?? milestones.length;

  /// Project site manager (first PROJECT_MANAGER member), if any.
  ProjectMember? get siteManager {
    for (final m in members) {
      if (m.role == ProjectRole.projectManager) return m;
    }
    return null;
  }

  ProjectMember? get owner {
    for (final m in members) {
      if (m.role == ProjectRole.owner) return m;
    }
    return null;
  }

  @override
  List<Object?> get props => [project, milestones, members];
}
