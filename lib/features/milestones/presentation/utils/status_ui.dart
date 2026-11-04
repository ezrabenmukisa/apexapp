import '../../../../core/widgets/status_chip.dart';
import '../../../evidence/domain/entities/evidence.dart';
import '../../domain/entities/milestone.dart';

extension MilestoneStatusUi on MilestoneStatus {
  /// Label from the owner's point of view.
  String get label => switch (this) {
    MilestoneStatus.notStarted => 'Not started',
    MilestoneStatus.inProgress => 'In progress',
    MilestoneStatus.submitted => 'Review',
    MilestoneStatus.changesRequested => 'Changes requested',
    MilestoneStatus.approved => 'Approved',
    MilestoneStatus.flagged => 'Flagged',
  };

  /// Label from the site manager's point of view.
  String get managerLabel => switch (this) {
    MilestoneStatus.submitted => 'Awaiting review',
    _ => label,
  };

  StatusTone get tone => switch (this) {
    MilestoneStatus.notStarted => StatusTone.notStarted,
    MilestoneStatus.inProgress => StatusTone.inProgress,
    MilestoneStatus.submitted => StatusTone.awaiting,
    MilestoneStatus.changesRequested => StatusTone.changes,
    MilestoneStatus.approved => StatusTone.approved,
    MilestoneStatus.flagged => StatusTone.flagged,
  };
}

extension EvidenceStatusUi on EvidenceStatus {
  String get label => switch (this) {
    EvidenceStatus.submitted => 'Awaiting review',
    EvidenceStatus.approved => 'Approved',
    EvidenceStatus.changesRequested => 'Changes requested',
    EvidenceStatus.flagged => 'Flagged',
  };

  StatusTone get tone => switch (this) {
    EvidenceStatus.submitted => StatusTone.awaiting,
    EvidenceStatus.approved => StatusTone.approved,
    EvidenceStatus.changesRequested => StatusTone.changes,
    EvidenceStatus.flagged => StatusTone.flagged,
  };
}

extension ReviewDecisionUi on ReviewDecision {
  String get pastTense => switch (this) {
    ReviewDecision.approve => 'approved',
    ReviewDecision.requestChanges => 'changes requested',
    ReviewDecision.flag => 'flagged',
  };

  StatusTone get tone => switch (this) {
    ReviewDecision.approve => StatusTone.approved,
    ReviewDecision.requestChanges => StatusTone.changes,
    ReviewDecision.flag => StatusTone.flagged,
  };
}
