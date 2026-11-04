import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../domain/entities/milestone.dart';
import '../../domain/usecases/milestone_usecases.dart';

enum EditMilestoneStatus { editing, saving, saved }

final class EditMilestoneState extends Equatable {
  const EditMilestoneState({
    required this.startDate,
    this.dueDate,
    this.sequence = 1,
    this.maxSequence = 1,
    this.status = EditMilestoneStatus.editing,
    this.error,
  });

  final DateTime startDate;
  final DateTime? dueDate;
  final int sequence;
  final int maxSequence;
  final EditMilestoneStatus status;
  final String? error;

  EditMilestoneState copyWith({
    DateTime? startDate,
    DateTime? dueDate,
    bool clearDue = false,
    int? sequence,
    EditMilestoneStatus? status,
    String? error,
  }) => EditMilestoneState(
    startDate: startDate ?? this.startDate,
    dueDate: clearDue ? null : (dueDate ?? this.dueDate),
    sequence: sequence ?? this.sequence,
    maxSequence: maxSequence,
    status: status ?? this.status,
    error: error,
  );

  @override
  List<Object?> get props => [
    startDate,
    dueDate,
    sequence,
    maxSequence,
    status,
    error,
  ];
}

/// Create or edit one milestone (owner only).
@injectable
class EditMilestoneCubit extends Cubit<EditMilestoneState> {
  EditMilestoneCubit(this._create, this._update)
    : super(EditMilestoneState(startDate: DateTime.now()));

  final CreateMilestone _create;
  final UpdateMilestone _update;

  String? _projectId;
  String? _milestoneId;

  /// [existing] null means a new milestone appended after [count] others.
  void init({
    required String projectId,
    Milestone? existing,
    required int count,
    DateTime? defaultStart,
  }) {
    _projectId = projectId;
    _milestoneId = existing?.milestoneId;
    emit(
      EditMilestoneState(
        startDate: existing?.startDate ?? defaultStart ?? DateTime.now(),
        dueDate: existing?.dueDate,
        sequence: existing?.sequence ?? count + 1,
        maxSequence: existing == null ? count + 1 : count,
      ),
    );
  }

  void startChanged(DateTime d) => emit(state.copyWith(startDate: d));
  void dueChanged(DateTime? d) =>
      emit(state.copyWith(dueDate: d, clearDue: d == null));

  void moveUp() {
    if (state.sequence > 1) emit(state.copyWith(sequence: state.sequence - 1));
  }

  void moveDown() {
    if (state.sequence < state.maxSequence) {
      emit(state.copyWith(sequence: state.sequence + 1));
    }
  }

  Future<void> save({
    required String title,
    required String brief,
    required double? budget,
  }) async {
    final due = state.dueDate;
    if (due != null && due.isBefore(state.startDate)) {
      return emit(state.copyWith(error: 'The due date is before the start.'));
    }
    emit(state.copyWith(status: EditMilestoneStatus.saving));
    final draft = MilestoneDraft(
      title: title.trim(),
      sequence: state.sequence,
      description: brief.trim(),
      startDate: state.startDate,
      dueDate: due,
      plannedBudget: budget,
    );
    final result = _milestoneId == null
        ? await _create((projectId: _projectId!, draft: draft))
        : await _update((milestoneId: _milestoneId!, draft: draft));
    if (isClosed) return;
    emit(
      result.match(
        (f) => state.copyWith(
          status: EditMilestoneStatus.editing,
          error: f.message,
        ),
        (_) => state.copyWith(status: EditMilestoneStatus.saved),
      ),
    );
  }
}
