import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/milestone.dart';
import '../repositories/milestones_repository.dart';

@injectable
class ListMilestones implements UseCase<List<Milestone>, String> {
  const ListMilestones(this._repository);

  final MilestonesRepository _repository;

  @override
  Future<Either<Failure, List<Milestone>>> call(String projectId) =>
      _repository.listMilestones(projectId);
}

@injectable
class GetMilestone implements UseCase<Milestone, String> {
  const GetMilestone(this._repository);

  final MilestonesRepository _repository;

  @override
  Future<Either<Failure, Milestone>> call(String milestoneId) =>
      _repository.getMilestone(milestoneId);
}

typedef CreateMilestoneParams = ({String projectId, MilestoneDraft draft});

@injectable
class CreateMilestone implements UseCase<Milestone, CreateMilestoneParams> {
  const CreateMilestone(this._repository);

  final MilestonesRepository _repository;

  @override
  Future<Either<Failure, Milestone>> call(CreateMilestoneParams p) =>
      _repository.createMilestone(p.projectId, p.draft);
}

typedef UpdateMilestoneParams = ({String milestoneId, MilestoneDraft draft});

@injectable
class UpdateMilestone implements UseCase<Milestone, UpdateMilestoneParams> {
  const UpdateMilestone(this._repository);

  final MilestonesRepository _repository;

  @override
  Future<Either<Failure, Milestone>> call(UpdateMilestoneParams p) =>
      _repository.updateMilestone(p.milestoneId, p.draft);
}

/// The standard four-phase house build, used by "Use a template".
/// Budgets split the project total 25/20/23/32 (the prototype's ledger).
@injectable
class ApplyHouseTemplate
    implements
        UseCase<
          List<Milestone>,
          ({String projectId, double? totalBudget, DateTime start})
        > {
  const ApplyHouseTemplate(this._repository);

  final MilestonesRepository _repository;

  static const phases = [
    (
      'Foundation',
      0.25,
      30,
      'Footings, blockwork to plinth and damp-proof course. Show each side and a DPC close-up.',
    ),
    (
      'Walling',
      0.20,
      30,
      'All four walls up to ring beam, ring beam cast. Show each wall, a ring beam close-up and a short walk-through.',
    ),
    (
      'Roofing',
      0.23,
      21,
      'Trusses fixed and iron sheets on. Show the trusses before sheeting and the finished roof.',
    ),
    (
      'Finishing',
      0.32,
      45,
      'Plaster, floors, windows, doors and paint. A walk-through of every room.',
    ),
  ];

  @override
  Future<Either<Failure, List<Milestone>>> call(
    ({String projectId, double? totalBudget, DateTime start}) p,
  ) async {
    final existing = await _repository.listMilestones(p.projectId);
    if (existing case Left(:final value)) return Left(value);
    var sequence = existing.getOrElse((_) => []).length;
    var start = p.start;
    for (final (title, share, days, brief) in phases) {
      final due = start.add(Duration(days: days - 1));
      final created = await _repository.createMilestone(
        p.projectId,
        MilestoneDraft(
          title: title,
          sequence: ++sequence,
          description: brief,
          startDate: start,
          dueDate: due,
          plannedBudget: p.totalBudget == null
              ? null
              : (p.totalBudget! * share).roundToDouble(),
        ),
      );
      if (created case Left(:final value)) return Left(value);
      start = due.add(const Duration(days: 1));
    }
    return _repository.listMilestones(p.projectId);
  }
}
