import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/mock/mock_api_server.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/utils/json.dart';
import '../../domain/entities/project.dart';
import '../models/project_model.dart';

/// `/projects` and `/projects/{id}/members`.
abstract interface class ProjectsDataSource {
  Future<List<Project>> listProjects({ProjectStatus? status});
  Future<Project> getProject(String projectId);
  Future<Project> createProject(ProjectDraft draft);
  Future<Project> updateProject(String projectId, ProjectDraft draft);
  Future<List<ProjectMember>> listMembers(String projectId);

  /// Emails an invite link. The person only appears in [listMembers] after
  /// they accept it. Returns a confirmation for the owner.
  Future<String> inviteMember(
    String projectId,
    String email,
    ProjectRole role, {
    required String message,
  });

  Future<String> removeMember(String projectId, String userId);

  /// Accepts the invite behind an emailed link's `token` for the signed-in
  /// user. Returns the id of the project they joined.
  Future<String> acceptInvitation(String token);
}

@lazySingleton
class ProjectsDataSourceRemote implements ProjectsDataSource {
  const ProjectsDataSourceRemote(this._dio);

  final Dio _dio;

  @override
  Future<List<Project>> listProjects({ProjectStatus? status}) async {
    final res = await _dio.get<Object>(
      ApiEndpoints.projects,
      queryParameters: {'status': ?status?.apiValue},
    );
    return Json.items(res.data).map(ProjectModel.fromJson).toList();
  }

  @override
  Future<Project> getProject(String projectId) async {
    final res = await _dio.get<Map<String, dynamic>>(
      ApiEndpoints.project(projectId),
    );
    return ProjectModel.fromJson(res.data!);
  }

  @override
  Future<Project> createProject(ProjectDraft draft) async {
    final res = await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.projects,
      data: ProjectModel.draftToJson(draft),
    );
    return ProjectModel.fromJson(res.data!);
  }

  @override
  Future<Project> updateProject(String projectId, ProjectDraft draft) async {
    final res = await _dio.patch<Map<String, dynamic>>(
      ApiEndpoints.project(projectId),
      data: ProjectModel.draftToJson(draft),
    );
    return ProjectModel.fromJson(res.data!);
  }

  @override
  Future<List<ProjectMember>> listMembers(String projectId) async {
    final res = await _dio.get<Object>(ApiEndpoints.projectMembers(projectId));
    return Json.items(res.data).map(ProjectMemberModel.fromJson).toList();
  }

  @override
  Future<String> inviteMember(
    String projectId,
    String email,
    ProjectRole role, {
    required String message,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.projectMembers(projectId),
      data: {
        'contact_email': email,
        'user_role': role.apiValue,
        'message': message,
      },
    );
    return 'Invitation sent to ${res.data?['email'] as String? ?? email}';
  }

  @override
  Future<String> removeMember(String projectId, String userId) async {
    final res = await _dio.delete<Map<String, dynamic>>(
      ApiEndpoints.projectMember(projectId, userId),
    );
    return res.data?['message'] as String? ?? 'Member removed';
  }

  @override
  Future<String> acceptInvitation(String token) async {
    final res = await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.acceptInvitation,
      data: {'token': token},
    );
    return res.data!['project_id'] as String;
  }
}

@lazySingleton
class ProjectsDataSourceMock implements ProjectsDataSource {
  const ProjectsDataSourceMock(this._server);

  final MockApiServer _server;

  @override
  Future<List<Project>> listProjects({ProjectStatus? status}) async {
    await _server.ready();
    return _server
        .listProjects(status: status?.apiValue)
        .map(ProjectModel.fromJson)
        .toList();
  }

  @override
  Future<Project> getProject(String projectId) async {
    await _server.ready();
    return ProjectModel.fromJson(_server.getProject(projectId));
  }

  @override
  Future<Project> createProject(ProjectDraft draft) async {
    await _server.ready();
    return ProjectModel.fromJson(
      _server.createProject(ProjectModel.draftToJson(draft)),
    );
  }

  @override
  Future<Project> updateProject(String projectId, ProjectDraft draft) async {
    await _server.ready();
    return ProjectModel.fromJson(
      _server.updateProject(projectId, ProjectModel.draftToJson(draft)),
    );
  }

  @override
  Future<List<ProjectMember>> listMembers(String projectId) async {
    await _server.ready();
    return _server
        .listMembers(projectId)
        .map(ProjectMemberModel.fromJson)
        .toList();
  }

  @override
  Future<String> inviteMember(
    String projectId,
    String email,
    ProjectRole role, {
    required String message,
  }) async {
    await _server.ready();
    final invitation = _server.inviteMember(projectId, email, role.apiValue);
    return 'Invitation sent to ${invitation['email']}';
  }

  @override
  Future<String> removeMember(String projectId, String userId) async {
    await _server.ready();
    return _server.removeMember(projectId, userId)['message'] as String;
  }

  @override
  Future<String> acceptInvitation(String token) async {
    await _server.ready();
    return _server.acceptInvitation(token)['project_id'] as String;
  }
}
