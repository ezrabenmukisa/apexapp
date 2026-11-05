import 'package:app/features/milestones/data/datasources/milestones_data_source.dart';
import 'package:app/features/milestones/data/models/milestone_model.dart';
import 'package:app/features/milestones/domain/entities/milestone.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_http.dart';

Map<String, dynamic> _milestone(String id, String status, {int seq = 1}) => {
  'milestone_id': id,
  'project_id': 'prj-1',
  'title': 'Stage $id',
  'sequence': seq,
  'description': null,
  'start_date': '2026-11-01',
  'due_date': '2026-12-01',
  'planned_budget': 500.0,
  'status': status,
};

void main() {
  group('MilestoneModel display status', () {
    MilestoneStatus status(String api, [String? evidence]) =>
        MilestoneModel.fromJson(
          _milestone('m', api),
          evidenceStatus: evidence,
        ).status;

    test('without evidence it follows the milestone status', () {
      expect(status('PENDING'), MilestoneStatus.notStarted);
      expect(status('IN_PROGRESS'), MilestoneStatus.inProgress);
      expect(status('DELAYED'), MilestoneStatus.delayed);
      expect(status('COMPLETED'), MilestoneStatus.approved);
    });

    test('the latest evidence review state wins', () {
      expect(status('IN_PROGRESS', 'SUBMITTED'), MilestoneStatus.submitted);
      expect(
        status('IN_PROGRESS', 'REQUEST_CHANGES'),
        MilestoneStatus.changesRequested,
      );
      expect(status('DELAYED', 'FLAGGED'), MilestoneStatus.flagged);
      expect(status('IN_PROGRESS', 'APPROVED'), MilestoneStatus.approved);
    });

    test('a completed milestone is approved whatever the evidence says', () {
      expect(status('COMPLETED', 'SUBMITTED'), MilestoneStatus.approved);
    });

    test('unknown values fall back to not started', () {
      expect(status('SOMETHING_NEW'), MilestoneStatus.notStarted);
    });
  });

  group('MilestonesDataSourceRemote', () {
    test('lists milestones with each one\'s latest evidence status', () async {
      final http = FakeHttp()
        ..on('GET', '/api/v1/projects/prj-1/milestones', 200, {
          'items': [
            _milestone('m1', 'IN_PROGRESS', seq: 1),
            _milestone('m2', 'PENDING', seq: 2),
          ],
        })
        ..on('GET', '/api/v1/milestones/m1/evidence', 200, {
          'evidence_id': 'e1',
          'milestone_id': 'm1',
          'status': 'SUBMITTED',
        })
        ..on('GET', '/api/v1/milestones/m2/evidence', 404, {
          'detail': 'No evidence submitted for this milestone.',
        });

      final list = await MilestonesDataSourceRemote(
        http.dio(),
      ).listMilestones('prj-1');

      expect(list.map((m) => m.status), [
        MilestoneStatus.submitted,
        MilestoneStatus.notStarted,
      ]);
      expect(http.where('GET'), hasLength(3));
    });

    test('a failing evidence lookup (not 404) fails the list', () async {
      final http = FakeHttp()
        ..on('GET', '/api/v1/projects/prj-1/milestones', 200, {
          'items': [_milestone('m1', 'IN_PROGRESS')],
        })
        ..on('GET', '/api/v1/milestones/m1/evidence', 500, {'detail': 'boom'});

      expect(
        MilestonesDataSourceRemote(http.dio()).listMilestones('prj-1'),
        throwsA(anything),
      );
    });

    test('getMilestone also reads the evidence status', () async {
      final http = FakeHttp()
        ..on('GET', '/api/v1/milestones/m1', 200, _milestone('m1', 'DELAYED'))
        ..on('GET', '/api/v1/milestones/m1/evidence', 200, {
          'evidence_id': 'e1',
          'milestone_id': 'm1',
          'status': 'REQUEST_CHANGES',
        });

      final m = await MilestonesDataSourceRemote(http.dio()).getMilestone('m1');

      expect(m.status, MilestoneStatus.changesRequested);
    });

    test('creates with a MilestoneCreate body', () async {
      final http = FakeHttp()
        ..on(
          'POST',
          '/api/v1/projects/prj-1/milestones',
          201,
          _milestone('m9', 'PENDING'),
        );

      final m = await MilestonesDataSourceRemote(http.dio()).createMilestone(
        'prj-1',
        MilestoneDraft(
          title: 'Roofing',
          sequence: 3,
          startDate: DateTime(2026, 11, 1),
          plannedBudget: 500,
        ),
      );

      expect(http.requests.single.data, {
        'title': 'Roofing',
        'sequence': 3,
        'start_date': '2026-11-01',
        'planned_budget': 500.0,
      });
      expect(m.status, MilestoneStatus.notStarted);
    });
  });
}
