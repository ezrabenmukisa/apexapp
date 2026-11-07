import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/files/documents.dart';
import '../../../../core/logging/app_logger.dart';

final class DocumentViewerState extends Equatable {
  const DocumentViewerState({
    this.file,
    this.error,
    this.busy = false,
    this.message,
  });

  /// The downloaded (or local) file once ready.
  final File? file;
  final String? error;

  /// Sharing or saving in progress.
  final bool busy;

  /// One-shot snackbar text.
  final String? message;

  bool get loading => file == null && error == null;

  DocumentViewerState copyWith({
    File? file,
    String? error,
    bool clearError = false,
    bool? busy,
    String? message,
  }) => DocumentViewerState(
    file: file ?? this.file,
    error: clearError ? null : (error ?? this.error),
    busy: busy ?? this.busy,
    message: message,
  );

  @override
  List<Object?> get props => [file?.path, error, busy, message];
}

/// Opens a receipt/document in the app, then offers share and save.
@injectable
class DocumentViewerCubit extends Cubit<DocumentViewerState> {
  DocumentViewerCubit(@factoryParam this.doc, this._cache, this._actions)
    : super(const DocumentViewerState());

  final DocumentRef? doc;
  final DocumentCache _cache;
  final DocumentActions _actions;

  Future<void> load() async {
    emit(const DocumentViewerState());
    try {
      final file = await _cache.fetch(doc!);
      if (!isClosed) emit(DocumentViewerState(file: file));
    } on DocumentException catch (e) {
      if (!isClosed) emit(DocumentViewerState(error: e.message));
    } catch (e, st) {
      appLogger.w('Opening ${doc?.name} failed', error: e, stackTrace: st);
      if (!isClosed) {
        emit(const DocumentViewerState(error: 'Couldn\'t open this file.'));
      }
    }
  }

  Future<void> share() => _run((file) async {
    await _actions.share(file, doc!);
    return null;
  });

  Future<void> save() => _run(
    (file) async =>
        await _actions.save(file, doc!) ? 'Saved ${doc!.name}.' : null,
  );

  Future<void> _run(Future<String?> Function(File) action) async {
    final file = state.file;
    if (file == null || state.busy) return;
    emit(state.copyWith(busy: true));
    try {
      final message = await action(file);
      if (!isClosed) emit(state.copyWith(busy: false, message: message));
    } catch (e, st) {
      appLogger.w('Document action failed', error: e, stackTrace: st);
      if (!isClosed) {
        emit(
          state.copyWith(busy: false, message: 'That didn\'t work. Try again.'),
        );
      }
    }
  }
}
