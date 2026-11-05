import '../../../../core/utils/json.dart';
import '../../domain/entities/milestone.dart';

abstract final class MilestoneModel {
  /// [evidenceStatus] is the `status` of the milestone's latest evidence
  /// (`GET /milestones/{id}/evidence`), or null when none was submitted.
  static Milestone fromJson(
    Map<String, dynamic> json, {
    String? evidenceStatus,
  }) => Milestone(
    milestoneId: json['milestone_id'] as String,
    projectId: json['project_id'] as String? ?? '',
    title: json['title'] as String,
    sequence: (json['sequence'] as num).toInt(),
    description: Json.blankToNull(json['description']),
    startDate: Json.parseDate(json['start_date']) ?? DateTime.now(),
    dueDate: Json.parseDate(json['due_date']),
    plannedBudget: Json.toDouble(json['planned_budget']),
    status: displayStatus(json['status'], evidenceStatus),
  );

  /// A completed milestone is done; otherwise the latest evidence's review
  /// state wins over the milestone's progress status.
  static MilestoneStatus displayStatus(Object? milestone, String? evidence) {
    if (milestone == 'COMPLETED') return MilestoneStatus.approved;
    switch (evidence) {
      case 'SUBMITTED':
        return MilestoneStatus.submitted;
      case 'REQUEST_CHANGES':
        return MilestoneStatus.changesRequested;
      case 'FLAGGED':
        return MilestoneStatus.flagged;
      case 'APPROVED':
        return MilestoneStatus.approved;
    }
    return switch (milestone) {
      'IN_PROGRESS' => MilestoneStatus.inProgress,
      'DELAYED' => MilestoneStatus.delayed,
      _ => MilestoneStatus.notStarted,
    };
  }

  static Map<String, dynamic> draftToJson(MilestoneDraft d) => {
    'title': ?d.title,
    'sequence': ?d.sequence,
    'description': ?d.description,
    'start_date': ?Json.date(d.startDate),
    'due_date': ?Json.date(d.dueDate),
    'planned_budget': ?d.plannedBudget,
  };
}
