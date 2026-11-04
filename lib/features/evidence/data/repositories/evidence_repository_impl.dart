import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/error/repository_guard.dart';
import '../../../../core/sync/data_changes.dart';
import '../../domain/entities/evidence.dart';
import '../../domain/repositories/evidence_repository.dart';
import '../datasources/evidence_data_source.dart';

@LazySingleton(as: EvidenceRepository)
class EvidenceRepositoryImpl
    with RepositoryGuard
    implements EvidenceRepository {
  EvidenceRepositoryImpl(this._source, this._changes);

  final EvidenceDataSource _source;
  final DataChanges _changes;

  @override
  Future<Either<Failure, Evidence?>> getEvidence(String milestoneId) =>
      guard(() => _source.getEvidence(milestoneId));

  @override
  Future<Either<Failure, String>> reviewEvidence(
    String evidenceId, {
    required ReviewDecision decision,
    required String comment,
  }) => guard(() async {
    final message = await _source.reviewEvidence(
      evidenceId,
      decision,
      comment.trim(),
    );
    _changes
      ..publish(DataTopic.evidence)
      ..publish(DataTopic.milestones)
      ..publish(DataTopic.notifications);
    return message;
  });
}
