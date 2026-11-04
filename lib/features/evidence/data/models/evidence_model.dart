import '../../../../core/utils/json.dart';
import '../../domain/entities/evidence.dart';

abstract final class EvidenceModel {
  static Evidence fromJson(Map<String, dynamic> json) => Evidence(
    evidenceId: json['evidence_id'] as String,
    milestoneId: json['milestone_id'] as String,
    description: json['description'] as String? ?? '',
    capturedLatitude: Json.toDouble(json['captured_latitude']) ?? 0,
    capturedLongitude: Json.toDouble(json['captured_longitude']) ?? 0,
    capturedAt: Json.parseDateTime(json['captured_at']),
    siteMediaUrls: Json.stringList(json['site_media_urls']),
    expenditureNotes: Json.blankToNull(json['expenditure_notes']),
    totalCostSpent: Json.toDouble(json['total_cost_spent']),
    receiptMediaUrls: Json.stringList(json['receipt_media_urls']),
    status: EvidenceStatus.fromApi(json['status']),
    submittedAt: Json.parseDateTime(json['submitted_at']),
    latestReview: switch (json['latest_review']) {
      final Map<String, dynamic> r => ReviewSummary(
        decision: ReviewDecision.fromApi(r['decision']),
        comment: r['comment'] as String? ?? '',
        reviewedAt: Json.parseDateTime(r['reviewed_at']),
      ),
      _ => null,
    },
  );

  /// Text fields of the multipart submission; files are added separately.
  static Map<String, dynamic> draftFields(EvidenceDraft d) => {
    'description': d.description,
    'captured_latitude': d.fix.latitude,
    'captured_longitude': d.fix.longitude,
    'captured_at': d.fix.timestamp.toUtc().toIso8601String(),
    'expenditure_notes': ?d.expenditureNotes,
    'total_cost_spent': ?d.totalCostSpent,
  };
}
