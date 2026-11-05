import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/bloc/load_cubit.dart';
import '../../../../core/device/connectivity_service.dart';
import '../../../../core/device/device_services.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/sync/data_changes.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../../core/utils/geo.dart';
import '../../domain/entities/evidence.dart';
import '../../domain/entities/outbox_item.dart';
import '../../domain/repositories/evidence_repository.dart';
import '../../domain/usecases/evidence_usecases.dart';

/// Owner: review one milestone's submission.
@injectable
class ReviewEvidenceCubit extends LoadCubit<ReviewContext> {
  ReviewEvidenceCubit(
    @factoryParam this.ids,
    this._get,
    this._review,
    DataChanges changes,
  ) : super(changes, {DataTopic.evidence});

  /// "projectId/milestoneId".
  final String? ids;
  final GetReviewContext _get;
  final ReviewEvidence _review;

  String get _projectId => ids!.split('/').first;
  String get _milestoneId => ids!.split('/').last;

  @override
  Future<Either<Failure, ReviewContext>> fetch() =>
      _get((projectId: _projectId, milestoneId: _milestoneId));

  Future<bool> decide(ReviewDecision decision, String comment) {
    final evidence = state.data?.evidence;
    if (evidence == null) return Future.value(false);
    final title = state.data!.milestone.title;
    return runAction(
      () => _review((
        evidenceId: evidence.evidenceId,
        decision: decision,
        comment: comment,
      )),
      successMessage: switch (decision) {
        ReviewDecision.approve => '$title approved.',
        ReviewDecision.requestChanges => 'Changes requested on $title.',
        ReviewDecision.flag => '$title flagged.',
      },
    );
  }
}

/// The site manager's assignment plus the latest GPS fix (distance to pin).
class SiteData extends Equatable {
  const SiteData({this.assignment, this.fix});

  final SiteAssignment? assignment;
  final GeoFix? fix;

  double? get distanceToPin {
    final a = assignment, f = fix;
    if (a == null || f == null) return null;
    return distanceInMetres(
      f.latitude,
      f.longitude,
      a.project.latitude,
      a.project.longitude,
    );
  }

  @override
  List<Object?> get props => [assignment, fix];
}

/// Site manager "Today" (shared at shell level).
@injectable
class SiteCubit extends LoadCubit<SiteData> {
  SiteCubit(this._get, this._location, DataChanges changes)
    : super(changes, {
        DataTopic.projects,
        DataTopic.milestones,
        DataTopic.evidence,
      });

  final GetSiteAssignment _get;
  final LocationService _location;

  @override
  Future<Either<Failure, SiteData>> fetch() async {
    final result = await _get(const NoParams());
    GeoFix? fix;
    try {
      fix = await _location.currentFix();
    } catch (_) {}
    return result.map((a) => SiteData(assignment: a, fix: fix));
  }
}

/// What the site manager is putting together for one submission. Lives at
/// shell level so Capture and Submit share it.
final class EvidenceDraftState extends Equatable {
  const EvidenceDraftState({
    this.milestoneId,
    this.media = const [],
    this.receipts = const [],
  });

  final String? milestoneId;
  final List<CapturedMedia> media;
  final List<ReceiptFile> receipts;

  EvidenceDraftState copyWith({
    String? milestoneId,
    List<CapturedMedia>? media,
    List<ReceiptFile>? receipts,
  }) => EvidenceDraftState(
    milestoneId: milestoneId ?? this.milestoneId,
    media: media ?? this.media,
    receipts: receipts ?? this.receipts,
  );

  @override
  List<Object?> get props => [milestoneId, media, receipts];
}

@injectable
class EvidenceDraftCubit extends Cubit<EvidenceDraftState> {
  EvidenceDraftCubit(this._receipts) : super(const EvidenceDraftState());

  final ReceiptPicker _receipts;

  /// Starts a fresh draft when the milestone changes.
  void startFor(String milestoneId) {
    if (state.milestoneId != milestoneId) {
      emit(EvidenceDraftState(milestoneId: milestoneId));
    }
  }

  void addMedia(CapturedMedia media) =>
      emit(state.copyWith(media: [...state.media, media]));

  void removeMedia(String id) => emit(
    state.copyWith(
      media: [
        for (final m in state.media)
          if (m.id != id) m,
      ],
    ),
  );

  Future<void> addReceipt() async {
    final file = await _receipts.pick();
    if (file != null && !isClosed) {
      emit(state.copyWith(receipts: [...state.receipts, file]));
    }
  }

  void removeReceipt(String id) => emit(
    state.copyWith(
      receipts: [
        for (final r in state.receipts)
          if (r.id != id) r,
      ],
    ),
  );

  void clear() => emit(EvidenceDraftState(milestoneId: state.milestoneId));
}

enum CaptureMode { photo, video }

final class CaptureState extends Equatable {
  const CaptureState({
    this.mode = CaptureMode.photo,
    this.busy = false,
    this.fix,
    this.error,
  });

  final CaptureMode mode;

  /// The phone's camera is open (or the shot is being saved).
  final bool busy;

  /// Live GPS shown on the capture screen.
  final GeoFix? fix;

  /// Why the last capture failed, shown once in a snackbar.
  final String? error;

  CaptureState copyWith({
    CaptureMode? mode,
    bool? busy,
    GeoFix? fix,
    String? Function()? error,
  }) => CaptureState(
    mode: mode ?? this.mode,
    busy: busy ?? this.busy,
    fix: fix ?? this.fix,
    error: error == null ? this.error : error(),
  );

  @override
  List<Object?> get props => [mode, busy, fix, error];
}

/// Opens the phone's camera (photo or video, never the gallery). Location
/// and time are taken around the shot by [CaptureService].
@injectable
class CaptureCubit extends Cubit<CaptureState> {
  CaptureCubit(this._capture, this._location) : super(const CaptureState());

  final CaptureService _capture;
  final LocationService _location;

  static const maxVideoDuration = Duration(minutes: 1);

  Future<void> refreshFix() async {
    try {
      final fix = await _location.currentFix();
      if (!isClosed) emit(state.copyWith(fix: fix));
    } catch (_) {}
  }

  void setMode(CaptureMode mode) {
    if (!state.busy) emit(state.copyWith(mode: mode));
  }

  /// Shutter: opens the camera for one photo or one video. Null when the
  /// user backs out or something went wrong (see [CaptureState.error]).
  Future<CapturedMedia?> shutter() async {
    if (state.busy) return null;
    emit(state.copyWith(busy: true, error: () => null));
    try {
      final media = state.mode == CaptureMode.photo
          ? await _capture.takePhoto()
          : await _capture.recordVideo(maxDuration: maxVideoDuration);
      if (!isClosed) emit(state.copyWith(busy: false, fix: media?.fix));
      return media;
    } on DeviceException catch (e) {
      if (!isClosed) emit(state.copyWith(busy: false, error: () => e.message));
    } catch (e, st) {
      appLogger.w('Capture failed', error: e, stackTrace: st);
      if (!isClosed) {
        emit(
          state.copyWith(
            busy: false,
            error: () => 'Something went wrong with the camera. Try again.',
          ),
        );
      }
    }
    return null;
  }
}

final class OutboxState extends Equatable {
  const OutboxState({this.items = const [], this.network});

  final List<OutboxItem> items;
  final NetworkState? network;

  List<OutboxItem> get pending => items.where((i) => i.isPending).toList();
  List<OutboxItem> get sent =>
      items.where((i) => i.status == OutboxStatus.sent).toList();
  bool get offline => network != null && !network!.online;

  @override
  List<Object?> get props => [items, network];
}

/// The Queue tab (shared at shell level for the badge).
@injectable
class OutboxCubit extends Cubit<OutboxState> {
  OutboxCubit(this._outbox, this._enqueue, this._network)
    : super(const OutboxState());

  final OutboxRepository _outbox;
  final EnqueueEvidence _enqueue;
  final ConnectivityService _network;
  final _subs = <StreamSubscription<Object?>>[];

  Future<void> start() async {
    _subs
      ..add(
        _outbox.watch().listen(
          (items) => emit(OutboxState(items: items, network: state.network)),
        ),
      )
      ..add(
        _network.watch().listen(
          (n) => emit(OutboxState(items: state.items, network: n)),
        ),
      );
    final items = await _outbox.items();
    final network = await _network.current();
    if (!isClosed) emit(OutboxState(items: items, network: network));
    _outbox.startAutoSync();
  }

  Future<void> syncNow() => _outbox.sync();

  Future<Either<Failure, OutboxItem>> submit(EnqueueEvidenceParams params) =>
      _enqueue(params);

  @override
  Future<void> close() async {
    for (final s in _subs) {
      await s.cancel();
    }
    return super.close();
  }
}
