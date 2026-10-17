import '../../../../core/utils/json.dart';
import '../../domain/entities/project.dart';

abstract final class ProjectModel {
  static Project fromJson(Map<String, dynamic> json) => Project(
    projectId: json['project_id'] as String,
    projectName: json['project_name'] as String,
    description: Json.blankToNull(json['description']),
    latitude: Json.toDouble(json['latitude']) ?? 0,
    longitude: Json.toDouble(json['longitude']) ?? 0,
    locationName: json['location_name'] as String? ?? '',
    plannedBudget: Json.toDouble(json['planned_budget']),
    currency: json['currency'] as String? ?? 'UGX',
    targetCompletionDate: Json.parseDate(json['target_completion_date']),
    status: ProjectStatus.fromApi(json['status']),
    createdAt: json['created_at'] == null
        ? DateTime.now()
        : Json.parseDateTime(json['created_at']),
    currentUserRole: json['current_user_role'] == null
        ? null
        : ProjectRole.fromApi(json['current_user_role']),
  );

  /// Request body; only fields that are set are sent (POST and PATCH).
  static Map<String, dynamic> draftToJson(ProjectDraft d) => {
    'project_name': ?d.projectName,
    'description': ?d.description,
    'latitude': ?d.latitude,
    'longitude': ?d.longitude,
    'location_name': ?d.locationName,
    'planned_budget': ?d.plannedBudget,
    'currency': ?d.currency,
    'target_completion_date': ?Json.date(d.targetCompletionDate),
    'status': ?d.status?.apiValue,
  };
}

abstract final class ProjectMemberModel {
  static ProjectMember fromJson(Map<String, dynamic> json) {
    final name = [
      json['first_name'],
      json['last_name'],
    ].whereType<String>().where((s) => s.isNotEmpty).join(' ');
    return ProjectMember(
      userId: json['user_id'] as String,
      displayName: name.isNotEmpty
          ? name
          : (json['display_name'] as String? ??
                json['contact_email'] as String? ??
                ''),
      contactEmail: json['contact_email'] as String? ?? '',
      role: ProjectRole.fromApi(json['user_role']),
    );
  }
}
