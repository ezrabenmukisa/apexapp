import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../milestones/domain/entities/milestone.dart';
import '../../../projects/domain/entities/project.dart';
import '../../../projects/domain/entities/project_overview.dart';
import '../../../projects/domain/repositories/projects_repository.dart';
import '../../../projects/domain/usecases/project_usecases.dart';
import '../entities/evidence.dart';
import '../entities/outbox_item.dart';
import '../repositories/evidence_repository.dart';

/// Everything the owner's review screen needs.
class ReviewContext extends Equatable {
  const ReviewContext({
    required this.overview,
    required this.milestone,
    required this.evidence,
  });

  final ProjectOverview overview;
  final Milestone milestone;
  final Evidence? evidence;

  Project get project => overview.project;

  @override
  List<Object?> get props => [overview, milestone, evidence];
}

@injectable
class GetReviewContext
    implements
        UseCase<ReviewContext, ({String projectId, String milestoneId})> {
  const GetReviewContext(this._overview, this._evidence);

  final GetProjectOverview _overview;
  final EvidenceRepository _evidence;

  @override
  Future<Either<Failure, ReviewContext>> call(
    ({String projectId, String milestoneId}) p,
  ) async {
    final results = await (
      _overview(p.projectId),
      _evidence.getEvidence(p.milestoneId),
    ).wait;
    return switch (results) {
      (Right(value: final o), Right(value: final e)) =>
        o.milestones.where((m) => m.milestoneId == p.milestoneId).firstOrNull ==
                null
            ? const Left(ServerFailure('Milestone not found', statusCode: 404))
            : Right(
                ReviewContext(
                  overview: o,
                  milestone: o.milestones.firstWhere(
                    (m) => m.milestoneId == p.milestoneId,
                  ),
                  evidence: e,
                ),
              ),
      (Left(:final value), _) || (_, Left(:final value)) => Left(value),
    };
  }
}

typedef ReviewEvidenceParams = ({
  String evidenceId,
  ReviewDecision decision,
  String comment,
});

@injectable
class ReviewEvidence implements UseCase<String, ReviewEvidenceParams> {
  const ReviewEvidence(this._repository);

  final EvidenceRepository _repository;

  @override
  Future<Either<Failure, String>> call(ReviewEvidenceParams p) {
    if (p.comment.trim().isEmpty) {
      return Future.value(
        const Left(
          ServerFailure('Add a comment — it\'s required for any decision.'),
        ),
      );
    }
    return _repository.reviewEvidence(
      p.evidenceId,
      decision: p.decision,
      comment: p.comment,
    );
  }
}

/// The site manager's current job: the project they manage, the milestone
/// to evidence next, and the owner's last decision.
class SiteAssignment extends Equatable {
  const SiteAssignment({
    required this.overview,
    required this.current,
    this.lastReviewed,
    this.lastReview,
  });

  final ProjectOverview overview;

  /// Next milestone needing evidence, or null when everything is approved.
  final Milestone? current;

  /// Most recent milestone the owner has decided on, and that decision.
  final Milestone? lastReviewed;
  final ReviewSummary? lastReview;

  Project get project => overview.project;

  String get ownerName =>
      overview.owner?.displayName.split(' ').first ?? 'the owner';

  @override
  List<Object?> get props => [overview, current, lastReviewed, lastReview];
}

/// Null result means the site manager hasn't been added to a project yet.
@injectable
class GetSiteAssignment implements UseCase<SiteAssignment?, NoParams> {
  const GetSiteAssignment(this._projects, this._overview, this._evidence);

  final ProjectsRepository _projects;
  final GetProjectOverview _overview;
  final EvidenceRepository _evidence;

  @override
  Future<Either<Failure, SiteAssignment?>> call(NoParams params) async {
    final projects = await _projects.listProjects(status: ProjectStatus.active);
    if (projects case Left(:final value)) return Left(value);
    for (final p in projects.getOrElse((_) => [])) {
      final ProjectOverview o;
      switch (await _overview(p.projectId)) {
        case Left(:final value):
          return Left(value);
        case Right(:final value):
          o = value;
      }
      if (o.project.currentUserRole != ProjectRole.projectManager) continue;

      // Latest decision: walk back from the current milestone.
      Milestone? lastReviewed;
      ReviewSummary? lastReview;
      for (final m in o.milestones.reversed) {
        if (m.status == MilestoneStatus.notStarted ||
            m.status == MilestoneStatus.inProgress ||
            m.status == MilestoneStatus.submitted) {
          continue;
        }
        final e = await _evidence.getEvidence(m.milestoneId);
        final review = e.toNullable()?.latestReview;
        if (review != null) {
          lastReviewed = m;
          lastReview = review;
          break;
        }
      }
      return Right(
        SiteAssignment(
          overview: o,
          current: o.current,
          lastReviewed: lastReviewed,
          lastReview: lastReview,
        ),
      );
    }
    return const Right(null);
  }
}

typedef EnqueueEvidenceParams = ({
  EvidenceDraft draft,
  String milestoneTitle,
  String projectName,
  String ownerName,
});

/// Puts a submission in the encrypted outbox; it sends when online.
@injectable
class EnqueueEvidence implements UseCase<OutboxItem, EnqueueEvidenceParams> {
  const EnqueueEvidence(this._outbox);

  final OutboxRepository _outbox;

  @override
  Future<Either<Failure, OutboxItem>> call(EnqueueEvidenceParams p) {
    if (p.draft.siteMedia.isEmpty) {
      return Future.value(
        const Left(ServerFailure('Capture at least one site photo or video.')),
      );
    }
    if (p.draft.description.trim().isEmpty) {
      return Future.value(const Left(ServerFailure('Describe what was done.')));
    }
    return _outbox.enqueue(
      draft: p.draft,
      milestoneTitle: p.milestoneTitle,
      projectName: p.projectName,
      ownerName: p.ownerName,
    );
  }
}
