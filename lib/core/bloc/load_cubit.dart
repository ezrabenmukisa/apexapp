import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';

import '../error/failures.dart';
import '../sync/data_changes.dart';

enum ActionStatus { idle, busy, success, failure }

/// State for a screen that loads [T] and can run actions on it.
final class LoadState<T> extends Equatable {
  const LoadState({
    this.loading = true,
    this.data,
    this.failure,
    this.action = ActionStatus.idle,
    this.actionMessage,
  });

  final bool loading;
  final T? data;

  /// Load failure (shown only when there is no data to fall back on).
  final Failure? failure;

  final ActionStatus action;

  /// One-shot message for the last action (snackbar).
  final String? actionMessage;

  bool get busy => action == ActionStatus.busy;

  LoadState<T> copyWith({
    bool? loading,
    T? data,
    Failure? failure,
    bool clearFailure = false,
    ActionStatus? action,
    String? actionMessage,
  }) => LoadState<T>(
    loading: loading ?? this.loading,
    data: data ?? this.data,
    failure: clearFailure ? null : (failure ?? this.failure),
    action: action ?? this.action,
    actionMessage: actionMessage,
  );

  @override
  List<Object?> get props => [loading, data, failure, action, actionMessage];
}

/// Loads data via [fetch], reloads silently when any of [topics] change
/// elsewhere in the app, and runs actions with busy/success/failure state.
abstract class LoadCubit<T> extends Cubit<LoadState<T>> {
  LoadCubit(DataChanges changes, Set<DataTopic> topics)
    : super(LoadState<T>()) {
    if (topics.isNotEmpty) {
      _subscription = changes.on(topics).listen((_) => _scheduleReload());
    }
  }

  StreamSubscription<DataTopic>? _subscription;
  bool _reloadScheduled = false;

  Future<Either<Failure, T>> fetch();

  Future<void> load() async {
    emit(state.copyWith(loading: true, clearFailure: true));
    await _fetchInto();
  }

  /// Several topics are often published together; reload once.
  void _scheduleReload() {
    if (_reloadScheduled) return;
    _reloadScheduled = true;
    scheduleMicrotask(() {
      _reloadScheduled = false;
      if (!isClosed) _fetchInto();
    });
  }

  Future<void> _fetchInto() async {
    final result = await fetch();
    if (isClosed) return;
    emit(
      result.match(
        (failure) => state.copyWith(loading: false, failure: failure),
        (data) =>
            state.copyWith(loading: false, data: data, clearFailure: true),
      ),
    );
  }

  /// Runs [run]; on success emits [successMessage] (or the returned
  /// message) and reloads unless [reload] is false.
  Future<bool> runAction<R>(
    Future<Either<Failure, R>> Function() run, {
    String? successMessage,
    bool reload = true,
  }) async {
    if (state.busy) return false;
    emit(state.copyWith(action: ActionStatus.busy));
    final result = await run();
    if (isClosed) return result.isRight();
    switch (result) {
      case Left(:final value):
        emit(
          state.copyWith(
            action: ActionStatus.failure,
            actionMessage: value.message,
          ),
        );
        return false;
      case Right(:final value):
        emit(
          state.copyWith(
            action: ActionStatus.success,
            actionMessage: successMessage ?? (value is String ? value : null),
          ),
        );
        if (reload) await _fetchInto();
        return true;
    }
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
