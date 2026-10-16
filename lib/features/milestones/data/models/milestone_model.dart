import '../../../../core/utils/json.dart';
import '../../domain/entities/milestone.dart';

abstract final class MilestoneModel {
  static Milestone fromJson(Map<String, dynamic> json) => Milestone(
    milestoneId: json['milestone_id'] as String,
    projectId: json['project_id'] as String? ?? '',
    title: json['title'] as String,
    sequence: (json['sequence'] as num).toInt(),
    description: Json.blankToNull(json['description']),
    startDate: Json.parseDate(json['start_date']) ?? DateTime.now(),
    dueDate: Json.parseDate(json['due_date']),
    plannedBudget: Json.toDouble(json['planned_budget']),
    status: MilestoneStatus.fromApi(json['status']),
  );

  static Map<String, dynamic> draftToJson(MilestoneDraft d) => {
    'title': ?d.title,
    'sequence': ?d.sequence,
    'description': ?d.description,
    'start_date': ?Json.date(d.startDate),
    'due_date': ?Json.date(d.dueDate),
    'planned_budget': ?d.plannedBudget,
  };
}
