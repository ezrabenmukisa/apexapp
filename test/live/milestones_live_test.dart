// Runs the app's real milestone, evidence and notification data sources
// against the live backend. Skipped unless APEX_LIVE_TOKENS is set (see
// projects_live_test.dart for the file format).
//
//   APEX_LIVE_TOKENS=/path/tokens.json flutter test test/live
@Tags(['live'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:app/core/error/error_mapper.dart';
import 'package:app/features/evidence/data/datasources/evidence_data_source.dart';
import 'package:app/features/evidence/domain/entities/evidence.dart';
import 'package:app/features/milestones/data/datasources/milestones_data_source.dart';
import 'package:app/features/milestones/domain/entities/milestone.dart';
import 'package:app/features/notifications/data/datasources/notifications_data_source.dart';
import 'package:app/features/notifications/domain/entities/app_notification.dart';
import 'package:app/features/projects/data/datasources/projects_data_source.dart';
import 'package:app/features/projects/domain/entities/project.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

const _baseUrl = 'https://apex.pntr.dev/api/v1';

void main() {
  final tokensPath = Platform.environment['APEX_LIVE_TOKENS'];
  final skip = tokensPath == null ? 'Set APEX_LIVE_TOKENS to run' : false;
  late Dio dio;
  late MilestonesDataSourceRemote milestones;
  late EvidenceDataSourceRemote evidence;
  late NotificationsDataSourceRemote notifications;
  late String projectId;
  late String milestoneId;

  setUpAll(() async {
    if (tokensPath == null) return;
    final tokens =
        jsonDecode(File(tokensPath).readAsStringSync()) as Map<String, dynamic>;
    final idToken = tokens['owner']['id_token'] as String;
    dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        headers: {'Authorization': 'Bearer $idToken'},
      ),
    );
    await dio.post<Object>('/auth/firebase', data: {'id_token': idToken});
    milestones = MilestonesDataSourceRemote(dio);
    evidence = EvidenceDataSourceRemote(dio);
    notifications = NotificationsDataSourceRemote(dio);
    final project = await ProjectsDataSourceRemote(dio).createProject(
      ProjectDraft(
        projectName: 'LIVE TEST milestones ${DateTime.now().toIso8601String()}',
        description: 'Created by the app\'s live API test; safe to delete.',
        latitude: 0.40441,
        longitude: 32.45940,
        locationName: 'Wakiso',
        plannedBudget: 1000000,
        currency: 'UGX',
        targetCompletionDate: DateTime(2027, 3, 1),
      ),
    );
    projectId = project.projectId;
  });

  test('owner creates a milestone; it starts as Not started', () async {
    final m = await milestones.createMilestone(
      projectId,
      MilestoneDraft(
        title: 'Foundation',
        sequence: 1,
        description: 'Footings and DPC',
        startDate: DateTime(2026, 11, 1),
        dueDate: DateTime(2026, 12, 1),
        plannedBudget: 350000,
      ),
    );
    milestoneId = m.milestoneId;
    expect(m.status, MilestoneStatus.notStarted);
    expect(m.plannedBudget, 350000);
    expect(m.dueDate, DateTime(2026, 12, 1));
  }, skip: skip);

  test('list and get work with no evidence yet (404 → none)', () async {
    final list = await milestones.listMilestones(projectId);
    expect(list.single.milestoneId, milestoneId);
    expect(list.single.status, MilestoneStatus.notStarted);
    final one = await milestones.getMilestone(milestoneId);
    expect(one.title, 'Foundation');
    expect(await evidence.getEvidence(milestoneId), isNull);
  }, skip: skip);

  test('owner edits the milestone', () async {
    final m = await milestones.updateMilestone(
      milestoneId,
      const MilestoneDraft(title: 'Foundation and DPC', plannedBudget: 400000),
    );
    expect(m.title, 'Foundation and DPC');
    expect(m.plannedBudget, 400000);
  }, skip: skip);

  test('the owner can\'t ask for upload URLs (managers only)', () async {
    final dir = Directory.systemTemp.createTempSync('apex_live');
    final photo = File('${dir.path}/east.jpg')..writeAsBytesSync([1, 2, 3]);
    final failure = await evidence
        .submitEvidence(
          EvidenceDraft(
            milestoneId: milestoneId,
            description: 'Should be refused',
            siteMedia: [
              CapturedMedia(
                id: 'c1',
                kind: MediaKind.photo,
                localPath: photo.path,
                fix: GeoFix(
                  latitude: 0.4,
                  longitude: 32.4,
                  accuracyMetres: 5,
                  timestamp: DateTime.now(),
                ),
              ),
            ],
          ),
        )
        .then<Object>((e) => e, onError: (Object e) => mapErrorToFailure(e));
    dir.deleteSync(recursive: true);
    // ignore: avoid_print
    print('owner submit → $failure');
    expect(failure, isNot(isA<Evidence>()));
    expect(failure.toString(), contains('403'));
  }, skip: skip);

  test('notifications list, unread filter and push token', () async {
    final all = await notifications.list();
    final unread = await notifications.list(unreadOnly: true);
    expect(unread.every((n) => !n.isRead), isTrue);
    expect(unread.length, lessThanOrEqualTo(all.length));
    await notifications.registerPushToken(
      'live-test-token',
      DevicePlatform.android,
    );
  }, skip: skip);
}
