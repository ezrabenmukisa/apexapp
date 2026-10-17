import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/evidence.dart';
import '../entities/outbox_item.dart';

abstract interface class EvidenceRepository {
  /// The latest submission for a milestone, or null if none yet.
  Future<Either<Failure, Evidence?>> getEvidence(String milestoneId);

  /// Owner's decision. A comment is required for every decision.
  Future<Either<Failure, String>> reviewEvidence(
    String evidenceId, {
    required ReviewDecision decision,
    required String comment,
  });
}

/// Submissions are never sent directly: they go into an encrypted on-phone
/// queue and are pushed whenever a connection is available.
abstract interface class OutboxRepository {
  /// Current items, newest first; emits on every change.
  Stream<List<OutboxItem>> watch();

  Future<List<OutboxItem>> items();

  Future<Either<Failure, OutboxItem>> enqueue({
    required EvidenceDraft draft,
    required String milestoneTitle,
    required String projectName,
    required String ownerName,
  });

  /// Starts sending automatically whenever the phone comes back online.
  /// Idempotent; call when the site-manager area opens.
  void startAutoSync();

  /// Sends every waiting item the current network allows. Safe to call
  /// repeatedly; concurrent calls share one run.
  Future<void> sync();
}
