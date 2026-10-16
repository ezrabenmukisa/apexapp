import 'dart:async';

import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/device/connectivity_service.dart';
import '../../../../core/error/error_mapper.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/sync/data_changes.dart';
import '../../../account/domain/repositories/settings_repository.dart';
import '../../../auth/data/datasources/firebase_auth_data_source.dart';
import '../../domain/entities/evidence.dart';
import '../../domain/entities/outbox_item.dart';
import '../../domain/repositories/evidence_repository.dart';
import '../datasources/evidence_data_source.dart';
import '../datasources/outbox_local_data_source.dart';

/// Encrypted on-phone queue for evidence, sent when connectivity allows.
/// Listens to the network and syncs automatically once [startAutoSync]
/// has been called.
@LazySingleton(as: OutboxRepository)
class OutboxRepositoryImpl implements OutboxRepository {
  OutboxRepositoryImpl(
    this._local,
    this._remote,
    this._auth,
    this._network,
    this._settings,
    this._changes,
  );

  final OutboxLocalDataSource _local;
  final EvidenceDataSource _remote;
  final FirebaseAuthDataSource _auth;
  final ConnectivityService _network;
  final SettingsRepository _settings;
  final DataChanges _changes;

  final _controller = StreamController<List<OutboxItem>>.broadcast();
  StreamSubscription<NetworkState>? _networkSub;
  Future<void>? _running;

  String? get _uid => _auth.currentUid;

  @override
  Stream<List<OutboxItem>> watch() => _controller.stream;

  @override
  Future<List<OutboxItem>> items() async {
    final uid = _uid;
    if (uid == null) return [];
    return _sorted(await _local.read(uid));
  }

  @override
  Future<Either<Failure, OutboxItem>> enqueue({
    required EvidenceDraft draft,
    required String milestoneTitle,
    required String projectName,
    required String ownerName,
  }) async {
    final uid = _uid;
    if (uid == null) return const Left(UnauthorizedFailure());
    try {
      final item = OutboxItem(
        id: 'obx_${DateTime.now().microsecondsSinceEpoch}',
        draft: draft,
        milestoneTitle: milestoneTitle,
        projectName: projectName,
        ownerName: ownerName,
        queuedAt: DateTime.now(),
        status: OutboxStatus.waiting,
      );
      await _write(uid, [item, ...await _local.read(uid)]);
      unawaited(sync());
      return Right(item);
    } catch (e, st) {
      return Left(mapErrorToFailure(e, st));
    }
  }

  @override
  void startAutoSync() {
    _networkSub ??= _network.watch().listen((state) {
      if (state.online) unawaited(sync());
    });
    unawaited(sync());
  }

  @override
  Future<void> sync() =>
      _running ??= _sync().whenComplete(() => _running = null);

  Future<void> _sync() async {
    final uid = _uid;
    if (uid == null) return;
    final network = await _network.current();
    if (!network.online) return;
    final wifiOnly = _settings.current.videoOnWifiOnly;

    for (final item in await _local.read(uid)) {
      if (item.status != OutboxStatus.waiting &&
          item.status != OutboxStatus.failed) {
        continue;
      }
      if (item.draft.hasVideo && wifiOnly && !network.onWifi) continue;

      await _replace(uid, item.copyWith(status: OutboxStatus.sending));
      try {
        final evidence = await _remote.submitEvidence(item.draft);
        await _replace(
          uid,
          item.copyWith(
            status: OutboxStatus.sent,
            sentAt: DateTime.now(),
            outcome: evidence.status,
          ),
        );
        _changes
          ..publish(DataTopic.evidence)
          ..publish(DataTopic.milestones)
          ..publish(DataTopic.notifications);
        appLogger.i('Outbox: sent ${item.milestoneTitle} evidence');
      } catch (e, st) {
        final failure = mapErrorToFailure(e, st);
        final retryable = failure is NetworkFailure;
        await _replace(
          uid,
          item.copyWith(
            status: retryable ? OutboxStatus.waiting : OutboxStatus.failed,
            error: retryable ? null : failure.message,
          ),
        );
        if (retryable) return; // Wait for the next connectivity change.
      }
    }
    await _refreshOutcomes(uid);
  }

  /// Updates review results ("Approved", "Changes requested") for items
  /// already sent.
  Future<void> _refreshOutcomes(String uid) async {
    final items = await _local.read(uid);
    var changed = false;
    final updated = <OutboxItem>[];
    final latest = <String, Evidence?>{};
    for (final item in items) {
      if (item.status != OutboxStatus.sent) {
        updated.add(item);
        continue;
      }
      try {
        final id = item.draft.milestoneId;
        final evidence = latest.containsKey(id)
            ? latest[id]
            : (latest[id] = await _remote.getEvidence(id));
        // Only the newest sent item for a milestone tracks its live status.
        final isNewest = !updated.any(
          (u) => u.status == OutboxStatus.sent && u.draft.milestoneId == id,
        );
        if (evidence != null && isNewest && evidence.status != item.outcome) {
          updated.add(item.copyWith(outcome: evidence.status));
          changed = true;
          continue;
        }
      } catch (_) {
        // Keep the last known outcome.
      }
      updated.add(item);
    }
    if (changed) await _write(uid, updated);
  }

  Future<void> _replace(String uid, OutboxItem item) async {
    final items = await _local.read(uid);
    await _write(uid, [for (final i in items) i.id == item.id ? item : i]);
  }

  Future<void> _write(String uid, List<OutboxItem> items) async {
    await _local.write(uid, items);
    _controller.add(_sorted(items));
    _changes.publish(DataTopic.outbox);
  }

  static List<OutboxItem> _sorted(List<OutboxItem> items) =>
      [...items]..sort((a, b) => b.queuedAt.compareTo(a.queuedAt));
}
