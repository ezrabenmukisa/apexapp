import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/mock/mock_api_server.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/utils/json.dart';
import '../../domain/entities/milestone.dart';
import '../models/milestone_model.dart';

/// `/projects/{id}/milestones` and `/milestones/{id}`.
///
/// Reads return the display status, which needs each milestone's latest
/// evidence (`GET /milestones/{id}/evidence`, 404 when there is none), so
/// a list costs one extra request per milestone.
abstract interface class MilestonesDataSource {
  Future<List<Milestone>> listMilestones(String projectId);
  Future<Milestone> getMilestone(String milestoneId);
  Future<Milestone> createMilestone(String projectId, MilestoneDraft draft);
  Future<Milestone> updateMilestone(String milestoneId, MilestoneDraft draft);
}

@lazySingleton
class MilestonesDataSourceRemote implements MilestonesDataSource {
  const MilestonesDataSourceRemote(this._dio);

  final Dio _dio;

  @override
  Future<List<Milestone>> listMilestones(String projectId) async {
    final res = await _dio.get<Object>(
      ApiEndpoints.projectMilestones(projectId),
    );
    return Future.wait(Json.items(res.data).map(_withEvidence));
  }

  @override
  Future<Milestone> getMilestone(String milestoneId) async {
    final res = await _dio.get<Map<String, dynamic>>(
      ApiEndpoints.milestone(milestoneId),
    );
    return _withEvidence(res.data!);
  }

  Future<Milestone> _withEvidence(Map<String, dynamic> json) async =>
      MilestoneModel.fromJson(
        json,
        evidenceStatus: await _evidenceStatus(json['milestone_id'] as String),
      );

  Future<String?> _evidenceStatus(String milestoneId) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.milestoneEvidence(milestoneId),
      );
      return res.data?['status'] as String?;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }

  @override
  Future<Milestone> createMilestone(
    String projectId,
    MilestoneDraft draft,
  ) async {
    final res = await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.projectMilestones(projectId),
      data: MilestoneModel.draftToJson(draft),
    );
    return MilestoneModel.fromJson(res.data!);
  }

  @override
  Future<Milestone> updateMilestone(
    String milestoneId,
    MilestoneDraft draft,
  ) async {
    final res = await _dio.patch<Map<String, dynamic>>(
      ApiEndpoints.milestone(milestoneId),
      data: MilestoneModel.draftToJson(draft),
    );
    return _withEvidence(res.data!);
  }
}

@lazySingleton
class MilestonesDataSourceMock implements MilestonesDataSource {
  const MilestonesDataSourceMock(this._server);

  final MockApiServer _server;

  @override
  Future<List<Milestone>> listMilestones(String projectId) async {
    await _server.ready();
    return _server.listMilestones(projectId).map(_withEvidence).toList();
  }

  @override
  Future<Milestone> getMilestone(String milestoneId) async {
    await _server.ready();
    return _withEvidence(_server.getMilestone(milestoneId));
  }

  Milestone _withEvidence(Map<String, dynamic> json) => MilestoneModel.fromJson(
    json,
    evidenceStatus: _server.latestEvidenceStatus(
      json['milestone_id'] as String,
    ),
  );

  @override
  Future<Milestone> createMilestone(
    String projectId,
    MilestoneDraft draft,
  ) async {
    await _server.ready();
    return MilestoneModel.fromJson(
      _server.createMilestone(projectId, MilestoneModel.draftToJson(draft)),
    );
  }

  @override
  Future<Milestone> updateMilestone(
    String milestoneId,
    MilestoneDraft draft,
  ) async {
    await _server.ready();
    return _withEvidence(
      _server.updateMilestone(milestoneId, MilestoneModel.draftToJson(draft)),
    );
  }
}
