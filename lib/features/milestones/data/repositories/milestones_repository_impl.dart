import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/error/repository_guard.dart';
import '../../../../core/sync/data_changes.dart';
import '../../domain/entities/milestone.dart';
import '../../domain/repositories/milestones_repository.dart';
import '../datasources/milestones_data_source.dart';

@LazySingleton(as: MilestonesRepository)
class MilestonesRepositoryImpl
    with RepositoryGuard
    implements MilestonesRepository {
  MilestonesRepositoryImpl(this._source, this._changes);

  final MilestonesDataSource _source;
  final DataChanges _changes;

  @override
  Future<Either<Failure, List<Milestone>>> listMilestones(String projectId) =>
      guard(() async => (await _source.listMilestones(projectId)).bySequence);

  @override
  Future<Either<Failure, Milestone>> getMilestone(String milestoneId) =>
      guard(() => _source.getMilestone(milestoneId));

  @override
  Future<Either<Failure, Milestone>> createMilestone(
    String projectId,
    MilestoneDraft draft,
  ) => guard(() async {
    final milestone = await _source.createMilestone(projectId, draft);
    _changes.publish(DataTopic.milestones);
    return milestone;
  });

  @override
  Future<Either<Failure, Milestone>> updateMilestone(
    String milestoneId,
    MilestoneDraft draft,
  ) => guard(() async {
    final milestone = await _source.updateMilestone(milestoneId, draft);
    _changes.publish(DataTopic.milestones);
    return milestone;
  });
}
