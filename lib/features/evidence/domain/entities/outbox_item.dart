import 'package:equatable/equatable.dart';

import 'evidence.dart';

enum OutboxStatus { waiting, sending, sent, failed }

/// A submission stored on this phone until it reaches the server, then kept
/// as history.
class OutboxItem extends Equatable {
  const OutboxItem({
    required this.id,
    required this.draft,
    required this.milestoneTitle,
    required this.projectName,
    required this.ownerName,
    required this.queuedAt,
    required this.status,
    this.sentAt,
    this.outcome,
    this.error,
  });

  final String id;
  final EvidenceDraft draft;
  final String milestoneTitle;
  final String projectName;

  /// Who reviews it ("Submit to Sarah").
  final String ownerName;
  final DateTime queuedAt;
  final OutboxStatus status;
  final DateTime? sentAt;

  /// Review result once known.
  final EvidenceStatus? outcome;
  final String? error;

  bool get isPending =>
      status == OutboxStatus.waiting ||
      status == OutboxStatus.sending ||
      status == OutboxStatus.failed;

  OutboxItem copyWith({
    OutboxStatus? status,
    DateTime? sentAt,
    EvidenceStatus? outcome,
    String? error,
  }) => OutboxItem(
    id: id,
    draft: draft,
    milestoneTitle: milestoneTitle,
    projectName: projectName,
    ownerName: ownerName,
    queuedAt: queuedAt,
    status: status ?? this.status,
    sentAt: sentAt ?? this.sentAt,
    outcome: outcome ?? this.outcome,
    error: error,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'draft': draft.toJson(),
    'milestone_title': milestoneTitle,
    'project_name': projectName,
    'owner_name': ownerName,
    'queued_at': queuedAt.toIso8601String(),
    'status': status.name,
    'sent_at': sentAt?.toIso8601String(),
    'outcome': outcome?.apiValue,
    'error': error,
  };

  static OutboxItem fromJson(Map<String, dynamic> json) => OutboxItem(
    id: json['id'] as String,
    draft: EvidenceDraft.fromJson(json['draft'] as Map<String, dynamic>),
    milestoneTitle: json['milestone_title'] as String,
    projectName: json['project_name'] as String,
    ownerName: json['owner_name'] as String,
    queuedAt: DateTime.parse(json['queued_at'] as String),
    // An item interrupted mid-send goes back to waiting.
    status: switch (OutboxStatus.values.byName(json['status'] as String)) {
      OutboxStatus.sending => OutboxStatus.waiting,
      final s => s,
    },
    sentAt: json['sent_at'] == null
        ? null
        : DateTime.parse(json['sent_at'] as String),
    outcome: json['outcome'] == null
        ? null
        : EvidenceStatus.fromApi(json['outcome']),
    error: json['error'] as String?,
  );

  @override
  List<Object?> get props => [
    id,
    draft,
    milestoneTitle,
    projectName,
    ownerName,
    queuedAt,
    status,
    sentAt,
    outcome,
    error,
  ];
}
