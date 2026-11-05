import 'package:app/features/projects/data/models/project_model.dart';
import 'package:app/features/projects/domain/entities/project.dart';
import 'package:flutter_test/flutter_test.dart';

/// `ProjectResponse` exactly as https://apex.pntr.dev/openapi.json defines it.
Map<String, dynamic> projectJson({
  String status = 'ACTIVE',
  String? role = 'owner',
}) => {
  'project_id': 'prj-1',
  'project_name': 'Four-bedroom house',
  'description': null,
  'latitude': 0.4,
  'longitude': 32.5,
  'location_name': 'Wakiso, Uganda',
  'planned_budget': 120000000,
  'currency': 'UGX',
  'target_completion_date': '2027-03-01',
  'status': status,
  'created_at': '2026-11-04T10:00:00Z',
  'current_user_role': role,
};

void main() {
  group('ProjectRole (API: owner / manager / member)', () {
    test('parses the lowercase roles the API returns', () {
      expect(ProjectRole.fromApi('owner'), ProjectRole.owner);
      expect(ProjectRole.fromApi('manager'), ProjectRole.projectManager);
      expect(ProjectRole.fromApi('member'), ProjectRole.member);
    });

    test('sends the lowercase API values', () {
      expect(ProjectRole.owner.apiValue, 'owner');
      expect(ProjectRole.projectManager.apiValue, 'manager');
      expect(ProjectRole.member.apiValue, 'member');
    });

    test('an unknown role gets the least access, not manager rights', () {
      expect(ProjectRole.fromApi('auditor'), ProjectRole.member);
    });
  });

  group('ProjectStatus (API: ACTIVE / COMPLETED / SUSPENDED)', () {
    test('parses SUSPENDED', () {
      expect(ProjectStatus.fromApi('SUSPENDED'), ProjectStatus.suspended);
    });

    test('pausing a project sends SUSPENDED', () {
      final json = ProjectModel.draftToJson(
        const ProjectDraft(status: ProjectStatus.suspended),
      );
      expect(json, {'status': 'SUSPENDED'});
    });
  });

  group('ProjectModel.fromJson', () {
    test('an owner sees the project as theirs', () {
      final project = ProjectModel.fromJson(projectJson());
      expect(project.currentUserRole, ProjectRole.owner);
      expect(project.isOwner, isTrue);
    });

    test('a suspended project reads as suspended', () {
      final project = ProjectModel.fromJson(projectJson(status: 'SUSPENDED'));
      expect(project.status, ProjectStatus.suspended);
    });
  });

  group('ProjectMemberModel.fromJson', () {
    test('reads a ProjectMemberResponse', () {
      final member = ProjectMemberModel.fromJson({
        'project_id': 'prj-1',
        'user_id': 'usr-2',
        'user_role': 'manager',
        'first_name': 'Kato',
        'last_name': 'Builders',
        'contact_email': 'kato@example.com',
      });
      expect(member.displayName, 'Kato Builders');
      expect(member.role, ProjectRole.projectManager);
      expect(member.contactEmail, 'kato@example.com');
    });
  });
}
