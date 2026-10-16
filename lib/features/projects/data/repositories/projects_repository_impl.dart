import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/error/repository_guard.dart';
import '../../../../core/sync/data_changes.dart';
import '../../domain/entities/project.dart';
import '../../domain/repositories/projects_repository.dart';
import '../datasources/projects_data_source.dart';

@LazySingleton(as: ProjectsRepository)
class ProjectsRepositoryImpl
    with RepositoryGuard
    implements ProjectsRepository {
  ProjectsRepositoryImpl(this._source, this._changes);

  final ProjectsDataSource _source;
  final DataChanges _changes;

  @override
  Future<Either<Failure, List<Project>>> listProjects({
    ProjectStatus? status,
  }) => guard(() => _source.listProjects(status: status));

  @override
  Future<Either<Failure, Project>> getProject(String projectId) =>
      guard(() => _source.getProject(projectId));

  @override
  Future<Either<Failure, Project>> createProject(ProjectDraft draft) =>
      guard(() async {
        final project = await _source.createProject(draft);
        _changes.publish(DataTopic.projects);
        return project;
      });

  @override
  Future<Either<Failure, Project>> updateProject(
    String projectId,
    ProjectDraft draft,
  ) => guard(() async {
    final project = await _source.updateProject(projectId, draft);
    _changes.publish(DataTopic.projects);
    return project;
  });

  @override
  Future<Either<Failure, List<ProjectMember>>> listMembers(String projectId) =>
      guard(() => _source.listMembers(projectId));

  @override
  Future<Either<Failure, String>> inviteMember(
    String projectId, {
    required String email,
    required ProjectRole role,
  }) => guard(() async {
    final message = await _source.inviteMember(projectId, email.trim(), role);
    _changes.publish(DataTopic.members);
    return message;
  });

  @override
  Future<Either<Failure, String>> removeMember(
    String projectId,
    String userId,
  ) => guard(() async {
    final message = await _source.removeMember(projectId, userId);
    _changes.publish(DataTopic.members);
    return message;
  });
}
