import 'package:equatable/equatable.dart';

enum EvidenceStatus {
  submitted('SUBMITTED'),
  approved('APPROVED'),
  changesRequested('CHANGES_REQUESTED'),
  flagged('FLAGGED');

  const EvidenceStatus(this.apiValue);

  final String apiValue;

  static EvidenceStatus fromApi(Object? value) =>
      values.firstWhere((s) => s.apiValue == value, orElse: () => submitted);
}

/// The owner's decision on a submission (`POST /evidence/{id}/reviews`).
enum ReviewDecision {
  approve('APPROVE'),
  requestChanges('REQUEST_CHANGES'),
  flag('FLAG');

  const ReviewDecision(this.apiValue);

  final String apiValue;

  static ReviewDecision fromApi(Object? value) =>
      values.firstWhere((d) => d.apiValue == value, orElse: () => approve);
}

/// The owner's decision on a submission. Not in the initial contract:
/// read from an optional `latest_review` object on the evidence response.
class ReviewSummary extends Equatable {
  const ReviewSummary({
    required this.decision,
    required this.comment,
    required this.reviewedAt,
  });

  final ReviewDecision decision;
  final String comment;
  final DateTime reviewedAt;

  @override
  List<Object?> get props => [decision, comment, reviewedAt];
}

/// A submitted, immutable progress report (`/milestones/{id}/evidence`).
class Evidence extends Equatable {
  const Evidence({
    required this.evidenceId,
    required this.milestoneId,
    required this.description,
    required this.capturedLatitude,
    required this.capturedLongitude,
    required this.capturedAt,
    required this.siteMediaUrls,
    required this.receiptMediaUrls,
    required this.status,
    required this.submittedAt,
    this.expenditureNotes,
    this.totalCostSpent,
    this.latestReview,
  });

  final String evidenceId;
  final String milestoneId;
  final String description;
  final double capturedLatitude;
  final double capturedLongitude;
  final DateTime capturedAt;
  final List<String> siteMediaUrls;
  final String? expenditureNotes;
  final double? totalCostSpent;
  final List<String> receiptMediaUrls;
  final EvidenceStatus status;
  final DateTime submittedAt;
  final ReviewSummary? latestReview;

  int get videoCount => siteMediaUrls.where(isVideoUrl).length;
  int get photoCount => siteMediaUrls.length - videoCount;

  static bool isVideoUrl(String url) {
    final u = url.toLowerCase();
    return u.contains('video') || u.endsWith('.mp4') || u.endsWith('.mov');
  }

  @override
  List<Object?> get props => [
    evidenceId,
    milestoneId,
    description,
    capturedLatitude,
    capturedLongitude,
    capturedAt,
    siteMediaUrls,
    expenditureNotes,
    totalCostSpent,
    receiptMediaUrls,
    status,
    submittedAt,
    latestReview,
  ];
}

/// A GPS reading taken from device sensors.
class GeoFix extends Equatable {
  const GeoFix({
    required this.latitude,
    required this.longitude,
    required this.accuracyMetres,
    required this.timestamp,
  });

  final double latitude;
  final double longitude;
  final double accuracyMetres;
  final DateTime timestamp;

  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
    'accuracy': accuracyMetres,
    'timestamp': timestamp.toIso8601String(),
  };

  static GeoFix fromJson(Map<String, dynamic> json) => GeoFix(
    latitude: (json['latitude'] as num).toDouble(),
    longitude: (json['longitude'] as num).toDouble(),
    accuracyMetres: (json['accuracy'] as num).toDouble(),
    timestamp: DateTime.parse(json['timestamp'] as String),
  );

  @override
  List<Object?> get props => [latitude, longitude, accuracyMetres, timestamp];
}

enum MediaKind { photo, video }

/// A photo or video taken with the in-app camera, with the GPS fix and time
/// frozen at the moment the shutter was pressed.
class CapturedMedia extends Equatable {
  const CapturedMedia({
    required this.id,
    required this.kind,
    required this.fix,
    this.localPath,
    this.label,
    this.durationSeconds,
  });

  final String id;
  final MediaKind kind;
  final GeoFix fix;

  /// File on this phone; null for simulated captures.
  final String? localPath;

  /// Placeholder caption for simulated captures ("east wall").
  final String? label;
  final int? durationSeconds;

  Map<String, dynamic> toJson() => {
    'id': id,
    'kind': kind.name,
    'fix': fix.toJson(),
    'local_path': localPath,
    'label': label,
    'duration_seconds': durationSeconds,
  };

  static CapturedMedia fromJson(Map<String, dynamic> json) => CapturedMedia(
    id: json['id'] as String,
    kind: MediaKind.values.byName(json['kind'] as String),
    fix: GeoFix.fromJson(json['fix'] as Map<String, dynamic>),
    localPath: json['local_path'] as String?,
    label: json['label'] as String?,
    durationSeconds: json['duration_seconds'] as int?,
  );

  @override
  List<Object?> get props => [id, kind, fix, localPath, label, durationSeconds];
}

/// A receipt or invoice: a photo or PDF, gallery allowed.
class ReceiptFile extends Equatable {
  const ReceiptFile({required this.id, required this.name, this.localPath});

  final String id;
  final String name;
  final String? localPath;

  bool get isPdf => name.toLowerCase().endsWith('.pdf');

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'local_path': localPath,
  };

  static ReceiptFile fromJson(Map<String, dynamic> json) => ReceiptFile(
    id: json['id'] as String,
    name: json['name'] as String,
    localPath: json['local_path'] as String?,
  );

  @override
  List<Object?> get props => [id, name, localPath];
}

/// Everything a site manager sends in one unified submission.
class EvidenceDraft extends Equatable {
  const EvidenceDraft({
    required this.milestoneId,
    required this.description,
    required this.siteMedia,
    this.receipts = const [],
    this.expenditureNotes,
    this.totalCostSpent,
  });

  final String milestoneId;
  final String description;
  final List<CapturedMedia> siteMedia;
  final List<ReceiptFile> receipts;
  final String? expenditureNotes;
  final double? totalCostSpent;

  /// The fix of the first capture is the submission's location and time.
  GeoFix get fix => siteMedia.first.fix;

  bool get hasVideo => siteMedia.any((m) => m.kind == MediaKind.video);

  Map<String, dynamic> toJson() => {
    'milestone_id': milestoneId,
    'description': description,
    'site_media': [for (final m in siteMedia) m.toJson()],
    'receipts': [for (final r in receipts) r.toJson()],
    'expenditure_notes': expenditureNotes,
    'total_cost_spent': totalCostSpent,
  };

  static EvidenceDraft fromJson(Map<String, dynamic> json) => EvidenceDraft(
    milestoneId: json['milestone_id'] as String,
    description: json['description'] as String,
    siteMedia: [
      for (final m in json['site_media'] as List)
        CapturedMedia.fromJson(m as Map<String, dynamic>),
    ],
    receipts: [
      for (final r in json['receipts'] as List)
        ReceiptFile.fromJson(r as Map<String, dynamic>),
    ],
    expenditureNotes: json['expenditure_notes'] as String?,
    totalCostSpent: (json['total_cost_spent'] as num?)?.toDouble(),
  );

  @override
  List<Object?> get props => [
    milestoneId,
    description,
    siteMedia,
    receipts,
    expenditureNotes,
    totalCostSpent,
  ];
}
