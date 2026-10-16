import 'package:equatable/equatable.dart';

/// Milestone lifecycle. The contract lists `status(enum)` without values;
/// these follow the review flow and are tolerant of unknown values.
enum MilestoneStatus {
  notStarted('NOT_STARTED'),
  inProgress('IN_PROGRESS'),

  /// Evidence submitted, awaiting the owner's review.
  submitted('SUBMITTED'),
  changesRequested('CHANGES_REQUESTED'),
  approved('APPROVED'),
  flagged('FLAGGED');

  const MilestoneStatus(this.apiValue);

  final String apiValue;

  static MilestoneStatus fromApi(Object? value) =>
      values.firstWhere((s) => s.apiValue == value, orElse: () => notStarted);

  /// Site manager can submit (new) evidence in these states.
  bool get acceptsEvidence =>
      this == notStarted ||
      this == inProgress ||
      this == changesRequested ||
      this == flagged;
}

/// A planned stage of a project (`/projects/{id}/milestones`).
class Milestone extends Equatable {
  const Milestone({
    required this.milestoneId,
    required this.projectId,
    required this.title,
    required this.sequence,
    required this.startDate,
    required this.status,
    this.description,
    this.dueDate,
    this.plannedBudget,
  });

  final String milestoneId;
  final String projectId;
  final String title;

  /// Display and execution order (1, 2, 3 …).
  final int sequence;

  /// The owner's brief: what they expect to see.
  final String? description;
  final DateTime startDate;
  final DateTime? dueDate;
  final double? plannedBudget;
  final MilestoneStatus status;

  @override
  List<Object?> get props => [
    milestoneId,
    projectId,
    title,
    sequence,
    description,
    startDate,
    dueDate,
    plannedBudget,
    status,
  ];
}

/// Fields for `POST /projects/{id}/milestones` and `PATCH /milestones/{id}`.
class MilestoneDraft extends Equatable {
  const MilestoneDraft({
    this.title,
    this.sequence,
    this.description,
    this.startDate,
    this.dueDate,
    this.plannedBudget,
  });

  final String? title;
  final int? sequence;
  final String? description;
  final DateTime? startDate;
  final DateTime? dueDate;
  final double? plannedBudget;

  @override
  List<Object?> get props => [
    title,
    sequence,
    description,
    startDate,
    dueDate,
    plannedBudget,
  ];
}

extension MilestoneListX on List<Milestone> {
  List<Milestone> get bySequence =>
      [...this]..sort((a, b) => a.sequence.compareTo(b.sequence));

  double sumWhere(bool Function(Milestone) test) =>
      where(test).fold(0, (sum, m) => sum + (m.plannedBudget ?? 0));

  /// The first milestone not yet approved, in order.
  Milestone? get current {
    for (final m in bySequence) {
      if (m.status != MilestoneStatus.approved) return m;
    }
    return null;
  }
}
