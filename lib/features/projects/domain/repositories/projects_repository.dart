import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/project.dart';

abstract interface class ProjectsRepository {
  Future<Either<Failure, List<Project>>> listProjects({ProjectStatus? status});
  Future<Either<Failure, Project>> getProject(String projectId);
  Future<Either<Failure, Project>> createProject(ProjectDraft draft);
  Future<Either<Failure, Project>> updateProject(
    String projectId,
    ProjectDraft draft,
  );
  Future<Either<Failure, List<ProjectMember>>> listMembers(String projectId);

  /// Owner only. Returns the server's confirmation message.
  Future<Either<Failure, String>> inviteMember(
    String projectId, {
    required String email,
    required ProjectRole role,
  });

  /// Owner only. Evidence the member submitted stays on the record.
  Future<Either<Failure, String>> removeMember(String projectId, String userId);
}
