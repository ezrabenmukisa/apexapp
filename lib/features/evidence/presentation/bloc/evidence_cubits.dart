import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/bloc/load_cubit.dart';
import '../../../../core/device/connectivity_service.dart';
import '../../../../core/device/device_services.dart';
import '../../../../core/error/failures.dart';
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
    this.recording = false,
    this.seconds = 0,
    this.busy = false,
    this.fix,
  });

  final CaptureMode mode;
  final bool recording;
  final int seconds;
  final bool busy;

  /// Live GPS shown in the viewfinder.
  final GeoFix? fix;

  CaptureState copyWith({
    CaptureMode? mode,
    bool? recording,
    int? seconds,
    bool? busy,
    GeoFix? fix,
  }) => CaptureState(
    mode: mode ?? this.mode,
    recording: recording ?? this.recording,
    seconds: seconds ?? this.seconds,
    busy: busy ?? this.busy,
    fix: fix ?? this.fix,
  );

  @override
  List<Object?> get props => [mode, recording, seconds, busy, fix];
}

/// In-app camera. Location and time are frozen when the shutter fires.
@injectable
class CaptureCubit extends Cubit<CaptureState> {
  CaptureCubit(this._capture, this._location) : super(const CaptureState());

  final CaptureService _capture;
  final LocationService _location;
  Timer? _timer;
  int _shots = 0;

  static const maxVideoSeconds = 60;
  static const _labels = [
    'east wall',
    'north wall',
    'west wall',
    'south wall',
    'ring beam close-up',
    'site overview',
    'materials on site',
    'detail',
  ];

  Future<void> refreshFix() async {
    try {
      final fix = await _location.currentFix();
      if (!isClosed) emit(state.copyWith(fix: fix));
    } catch (_) {}
  }

  void setMode(CaptureMode mode) {
    if (!state.recording) emit(state.copyWith(mode: mode));
  }

  /// Shutter: takes a photo, or starts/stops a video.
  Future<CapturedMedia?> shutter() async {
    if (state.busy) return null;
    if (state.mode == CaptureMode.photo) {
      emit(state.copyWith(busy: true));
      final media = await _capture.takePhoto(
        label: _labels[_shots++ % _labels.length],
      );
      if (!isClosed) emit(state.copyWith(busy: false, fix: media.fix));
      return media;
    }
    if (!state.recording) {
      emit(state.copyWith(recording: true, seconds: 0));
      _timer = Timer.periodic(const Duration(seconds: 1), (t) {
        final next = state.seconds + 1;
        emit(state.copyWith(seconds: next));
        if (next >= maxVideoSeconds) t.cancel();
      });
      return null;
    }
    return stopVideo();
  }

  Future<CapturedMedia?> stopVideo() async {
    _timer?.cancel();
    if (!state.recording) return null;
    final seconds = state.seconds.clamp(1, maxVideoSeconds);
    emit(state.copyWith(recording: false, busy: true));
    final media = await _capture.recordVideo(
      label: 'walk-through',
      seconds: seconds,
    );
    if (!isClosed) {
      emit(state.copyWith(busy: false, seconds: 0, fix: media.fix));
    }
    return media;
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
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
