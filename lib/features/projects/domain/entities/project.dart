import 'package:equatable/equatable.dart';

enum ProjectStatus {
  active('ACTIVE'),
  paused('PAUSED'),
  completed('COMPLETED');

  const ProjectStatus(this.apiValue);

  final String apiValue;

  static ProjectStatus fromApi(Object? value) =>
      values.firstWhere((s) => s.apiValue == value, orElse: () => active);
}

/// The caller's role on one project (`current_user_role`, member `user_role`).
enum ProjectRole {
  owner('OWNER'),
  projectManager('PROJECT_MANAGER');

  const ProjectRole(this.apiValue);

  final String apiValue;

  String get label => this == owner ? 'Owner' : 'Site manager';

  static ProjectRole fromApi(Object? value) => switch (value) {
    'OWNER' => owner,
    _ => projectManager, // PROJECT_MANAGER / MANAGER
  };
}

/// A physical project (`/projects`).
class Project extends Equatable {
  const Project({
    required this.projectId,
    required this.projectName,
    required this.latitude,
    required this.longitude,
    required this.locationName,
    required this.status,
    required this.createdAt,
    this.description,
    this.plannedBudget,
    this.currency = 'UGX',
    this.targetCompletionDate,
    this.currentUserRole,
  });

  final String projectId;
  final String projectName;
  final String? description;
  final double latitude;
  final double longitude;
  final String locationName;
  final double? plannedBudget;
  final String currency;
  final DateTime? targetCompletionDate;
  final ProjectStatus status;
  final DateTime createdAt;

  /// Only returned by `GET /projects/{id}`.
  final ProjectRole? currentUserRole;

  bool get isOwner => currentUserRole == ProjectRole.owner;

  /// Short area name for cards: the first part of the address.
  String get area => locationName.split(',').first.trim();

  @override
  List<Object?> get props => [
    projectId,
    projectName,
    description,
    latitude,
    longitude,
    locationName,
    plannedBudget,
    currency,
    targetCompletionDate,
    status,
    createdAt,
    currentUserRole,
  ];
}

/// Fields for `POST /projects` and `PATCH /projects/{id}`.
class ProjectDraft extends Equatable {
  const ProjectDraft({
    this.projectName,
    this.description,
    this.latitude,
    this.longitude,
    this.locationName,
    this.plannedBudget,
    this.currency,
    this.targetCompletionDate,
    this.status,
  });

  final String? projectName;
  final String? description;
  final double? latitude;
  final double? longitude;
  final String? locationName;
  final double? plannedBudget;
  final String? currency;
  final DateTime? targetCompletionDate;
  final ProjectStatus? status;

  @override
  List<Object?> get props => [
    projectName,
    description,
    latitude,
    longitude,
    locationName,
    plannedBudget,
    currency,
    targetCompletionDate,
    status,
  ];
}

/// A participant on a project (`GET /projects/{id}/members`).
class ProjectMember extends Equatable {
  const ProjectMember({
    required this.userId,
    required this.displayName,
    required this.contactEmail,
    required this.role,
  });

  final String userId;
  final String displayName;
  final String contactEmail;
  final ProjectRole role;

  String get initials {
    final parts = displayName.trim().split(RegExp(r'\s+'));
    return parts.take(2).map((p) => p.isEmpty ? '' : p[0]).join().toUpperCase();
  }

  @override
  List<Object?> get props => [userId, displayName, contactEmail, role];
}
