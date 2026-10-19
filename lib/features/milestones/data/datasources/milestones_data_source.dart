import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/mock/mock_api_server.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/utils/json.dart';
import '../../domain/entities/milestone.dart';
import '../models/milestone_model.dart';

/// `/projects/{id}/milestones` and `/milestones/{id}`.
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
    return Json.items(res.data).map(MilestoneModel.fromJson).toList();
  }

  @override
  Future<Milestone> getMilestone(String milestoneId) async {
    final res = await _dio.get<Map<String, dynamic>>(
      ApiEndpoints.milestone(milestoneId),
    );
    return MilestoneModel.fromJson(res.data!);
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
    return MilestoneModel.fromJson(res.data!);
  }
}

@lazySingleton
class MilestonesDataSourceMock implements MilestonesDataSource {
  const MilestonesDataSourceMock(this._server);

  final MockApiServer _server;

  @override
  Future<List<Milestone>> listMilestones(String projectId) async {
    await _server.ready();
    return _server
        .listMilestones(projectId)
        .map(MilestoneModel.fromJson)
        .toList();
  }

  @override
  Future<Milestone> getMilestone(String milestoneId) async {
    await _server.ready();
    return MilestoneModel.fromJson(_server.getMilestone(milestoneId));
  }

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
    return MilestoneModel.fromJson(
      _server.updateMilestone(milestoneId, MilestoneModel.draftToJson(draft)),
    );
  }
}
