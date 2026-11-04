import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../milestones/domain/entities/milestone.dart';
import '../../../milestones/domain/repositories/milestones_repository.dart';
import '../entities/project.dart';
import '../entities/project_overview.dart';
import '../repositories/projects_repository.dart';

/// Owner home: every project with its milestones, plus the submissions
/// waiting for a decision.
class OwnerDashboard {
  const OwnerDashboard({required this.projects});

  final List<ProjectOverview> projects;

  List<(ProjectOverview, Milestone)> get pendingReviews => [
    for (final p in projects)
      for (final m in p.milestones)
        if (m.status == MilestoneStatus.submitted) (p, m),
  ];
}

@injectable
class GetOwnerDashboard implements UseCase<OwnerDashboard, NoParams> {
  const GetOwnerDashboard(this._projects, this._milestones);

  final ProjectsRepository _projects;
  final MilestonesRepository _milestones;

  @override
  Future<Either<Failure, OwnerDashboard>> call(NoParams params) async {
    final projects = await _projects.listProjects();
    return projects.match(Left.new, (list) async {
      final overviews = <ProjectOverview>[];
      for (final p in list) {
        final (milestones, members) = await (
          _milestones.listMilestones(p.projectId),
          _projects.listMembers(p.projectId),
        ).wait;
        if (milestones case Left(:final value)) return Left(value);
        overviews.add(
          ProjectOverview(
            project: p,
            milestones: milestones.getOrElse((_) => []),
            // The team only labels cards; don't fail the dashboard for it.
            members: members.getOrElse((_) => []),
          ),
        );
      }
      overviews.sort(
        (a, b) => b.project.createdAt.compareTo(a.project.createdAt),
      );
      return Right(OwnerDashboard(projects: overviews));
    });
  }
}

/// Project detail: the project with the caller's role, plan and team.
@injectable
class GetProjectOverview implements UseCase<ProjectOverview, String> {
  const GetProjectOverview(this._projects, this._milestones);

  final ProjectsRepository _projects;
  final MilestonesRepository _milestones;

  @override
  Future<Either<Failure, ProjectOverview>> call(String projectId) async {
    final results = await (
      _projects.getProject(projectId),
      _milestones.listMilestones(projectId),
      _projects.listMembers(projectId),
    ).wait;
    return switch (results) {
      (Right(value: final p), Right(value: final m), Right(value: final t)) =>
        Right(ProjectOverview(project: p, milestones: m, members: t)),
      (Left(:final value), _, _) ||
      (_, Left(:final value), _) ||
      (_, _, Left(:final value)) => Left(value),
    };
  }
}

@injectable
class CreateProject implements UseCase<Project, ProjectDraft> {
  const CreateProject(this._repository);

  final ProjectsRepository _repository;

  @override
  Future<Either<Failure, Project>> call(ProjectDraft draft) =>
      _repository.createProject(draft);
}

typedef UpdateProjectParams = ({String projectId, ProjectDraft draft});

@injectable
class UpdateProject implements UseCase<Project, UpdateProjectParams> {
  const UpdateProject(this._repository);

  final ProjectsRepository _repository;

  @override
  Future<Either<Failure, Project>> call(UpdateProjectParams p) =>
      _repository.updateProject(p.projectId, p.draft);
}

typedef InviteMemberParams = ({
  String projectId,
  String email,
  ProjectRole role,
});

@injectable
class InviteMember implements UseCase<String, InviteMemberParams> {
  const InviteMember(this._repository);

  final ProjectsRepository _repository;

  @override
  Future<Either<Failure, String>> call(InviteMemberParams p) =>
      _repository.inviteMember(p.projectId, email: p.email, role: p.role);
}

typedef RemoveMemberParams = ({String projectId, String userId});

@injectable
class RemoveMember implements UseCase<String, RemoveMemberParams> {
  const RemoveMember(this._repository);

  final ProjectsRepository _repository;

  @override
  Future<Either<Failure, String>> call(RemoveMemberParams p) =>
      _repository.removeMember(p.projectId, p.userId);
}

@injectable
class ListProjectMembers implements UseCase<List<ProjectMember>, String> {
  const ListProjectMembers(this._repository);

  final ProjectsRepository _repository;

  @override
  Future<Either<Failure, List<ProjectMember>>> call(String projectId) =>
      _repository.listMembers(projectId);
}
