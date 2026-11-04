import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/mock/mock_api_server.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../domain/entities/evidence.dart';
import '../models/evidence_model.dart';

/// `/milestones/{id}/evidence` and `/evidence/{id}/reviews`.
abstract interface class EvidenceDataSource {
  /// Null when nothing has been submitted for the milestone yet.
  Future<Evidence?> getEvidence(String milestoneId);

  /// One multipart payload: text fields, site media and receipts together.
  Future<Evidence> submitEvidence(EvidenceDraft draft);

  Future<String> reviewEvidence(
    String evidenceId,
    ReviewDecision decision,
    String comment,
  );
}

@lazySingleton
class EvidenceDataSourceRemote implements EvidenceDataSource {
  const EvidenceDataSourceRemote(this._dio);

  final Dio _dio;

  @override
  Future<Evidence?> getEvidence(String milestoneId) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.milestoneEvidence(milestoneId),
      );
      return EvidenceModel.fromJson(res.data!);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }

  @override
  Future<Evidence> submitEvidence(EvidenceDraft draft) async {
    Future<MultipartFile> file(String? path, String what) async {
      if (path == null) {
        throw ServerException('$what is missing from this phone.');
      }
      return MultipartFile.fromFile(path);
    }

    final form = FormData.fromMap(EvidenceModel.draftFields(draft));
    for (final m in draft.siteMedia) {
      form.files.add(
        MapEntry('site_media', await file(m.localPath, 'A site photo')),
      );
    }
    for (final r in draft.receipts) {
      form.files.add(
        MapEntry('receipt_media', await file(r.localPath, 'A receipt')),
      );
    }
    final res = await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.milestoneEvidence(draft.milestoneId),
      data: form,
      options: Options(
        contentType: Headers.multipartFormDataContentType,
        // Video over slow site connections.
        sendTimeout: const Duration(minutes: 10),
      ),
    );
    return EvidenceModel.fromJson(res.data!);
  }

  @override
  Future<String> reviewEvidence(
    String evidenceId,
    ReviewDecision decision,
    String comment,
  ) async {
    final res = await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.evidenceReviews(evidenceId),
      data: {'decision': decision.apiValue, 'comment': comment},
    );
    return res.data?['message'] as String? ?? 'Review recorded';
  }
}

@lazySingleton
class EvidenceDataSourceMock implements EvidenceDataSource {
  const EvidenceDataSourceMock(this._server);

  final MockApiServer _server;

  @override
  Future<Evidence?> getEvidence(String milestoneId) async {
    await _server.ready();
    try {
      return EvidenceModel.fromJson(_server.getEvidence(milestoneId));
    } on ServerException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  @override
  Future<Evidence> submitEvidence(EvidenceDraft draft) async {
    // Simulated upload time for the multipart payload.
    await Future<void>.delayed(const Duration(seconds: 2));
    String slug(String? s, String fallback) =>
        (s ?? fallback).toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-');
    return EvidenceModel.fromJson(
      _server.submitEvidence(
        draft.milestoneId,
        EvidenceModel.draftFields(draft),
        siteMedia: [
          for (final m in draft.siteMedia)
            m.kind == MediaKind.video
                ? 'video-${slug(m.label, m.id)}'
                : slug(m.label, m.id),
        ],
        receipts: [for (final r in draft.receipts) r.name],
      ),
    );
  }

  @override
  Future<String> reviewEvidence(
    String evidenceId,
    ReviewDecision decision,
    String comment,
  ) async {
    await _server.ready();
    return _server.reviewEvidence(
          evidenceId,
          decision.apiValue,
          comment,
        )['message']
        as String;
  }
}
