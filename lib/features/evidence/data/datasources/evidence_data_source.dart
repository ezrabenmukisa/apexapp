import 'dart:io';

import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/mock/mock_api_server.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/auth_interceptor.dart';
import '../../domain/entities/evidence.dart';
import '../models/evidence_model.dart';

/// `/milestones/{id}/evidence` and `/evidence/{id}/reviews`.
abstract interface class EvidenceDataSource {
  /// Null when nothing has been submitted for the milestone yet.
  Future<Evidence?> getEvidence(String milestoneId);

  /// Uploads the draft's site media and receipts, then submits it.
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

  /// 1. `POST …/evidence/upload-urls` per folder (site_media, receipt_media)
  /// 2. `PUT` each file to its presigned S3 URL (shared Dio, no token)
  /// 3. `POST …/evidence` as JSON with the returned file keys
  @override
  Future<Evidence> submitEvidence(EvidenceDraft draft) async {
    final site = [
      for (final m in draft.siteMedia) _localFile(m.localPath, 'A site photo'),
    ];
    final receipts = [
      for (final r in draft.receipts) _localFile(r.localPath, 'A receipt'),
    ];
    final siteKeys = await _upload(draft.milestoneId, 'site_media', site);
    final receiptKeys = receipts.isEmpty
        ? null
        : await _upload(draft.milestoneId, 'receipt_media', receipts);
    final res = await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.milestoneEvidence(draft.milestoneId),
      data: EvidenceModel.draftToJson(
        draft,
        siteMediaKeys: siteKeys,
        receiptMediaKeys: receiptKeys,
      ),
    );
    return EvidenceModel.fromJson(res.data!);
  }

  static File _localFile(String? path, String what) {
    if (path == null || !File(path).existsSync()) {
      throw ServerException('$what is missing from this phone.');
    }
    return File(path);
  }

  /// Uploads [files] to S3 and returns their keys, in the same order.
  Future<List<String>> _upload(
    String milestoneId,
    String folder,
    List<File> files,
  ) async {
    final res = await _dio.post<List<dynamic>>(
      ApiEndpoints.evidenceUploadUrls(milestoneId),
      data: {
        'filenames': [for (final f in files) _basename(f.path)],
        'folder': folder,
      },
    );
    final targets = [
      for (final t in res.data ?? const []) Map<String, dynamic>.from(t as Map),
    ];
    if (targets.length < files.length) {
      throw const ServerException('The server did not return upload links.');
    }
    final keys = <String>[];
    for (var i = 0; i < files.length; i++) {
      final file = files[i];
      await _dio.put<void>(
        targets[i]['upload_url'] as String,
        data: file.openRead(),
        options: Options(
          contentType: _contentType(file.path),
          headers: {Headers.contentLengthHeader: file.lengthSync()},
          responseType: ResponseType.plain,
          extra: {AuthInterceptor.skipAuthKey: true},
          // Video over slow site connections.
          sendTimeout: const Duration(minutes: 10),
        ),
      );
      keys.add(targets[i]['file_key'] as String);
    }
    return keys;
  }

  static String _basename(String path) =>
      path.split(Platform.pathSeparator).last;

  static String _contentType(String path) =>
      switch (path.split('.').last.toLowerCase()) {
        'jpg' || 'jpeg' => 'image/jpeg',
        'png' => 'image/png',
        'heic' => 'image/heic',
        'webp' => 'image/webp',
        'mp4' => 'video/mp4',
        'mov' => 'video/quicktime',
        'pdf' => 'application/pdf',
        _ => 'application/octet-stream',
      };

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
    // Simulated upload time.
    await Future<void>.delayed(const Duration(seconds: 2));
    String slug(String? s, String fallback) =>
        (s ?? fallback).toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-');
    return EvidenceModel.fromJson(
      _server.submitEvidence(
        draft.milestoneId,
        EvidenceModel.draftToJson(draft),
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
