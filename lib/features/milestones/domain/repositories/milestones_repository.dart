import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/milestone.dart';

abstract interface class MilestonesRepository {
  /// Sorted by `sequence`.
  Future<Either<Failure, List<Milestone>>> listMilestones(String projectId);
  Future<Either<Failure, Milestone>> getMilestone(String milestoneId);

  /// Owner only.
  Future<Either<Failure, Milestone>> createMilestone(
    String projectId,
    MilestoneDraft draft,
  );

  /// Owner only.
  Future<Either<Failure, Milestone>> updateMilestone(
    String milestoneId,
    MilestoneDraft draft,
  );
}
