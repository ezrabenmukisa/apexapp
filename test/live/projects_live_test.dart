// Runs the app's real projects data source against the live backend.
// Skipped unless APEX_LIVE_TOKENS points at a JSON file of Firebase ID
// tokens: {"owner": {"id_token": ...}, "invitee": {"id_token": ..., "email": ...}}
//
//   APEX_LIVE_TOKENS=/path/tokens.json flutter test test/live
@Tags(['live'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:app/core/error/error_mapper.dart';
import 'package:app/features/projects/data/datasources/projects_data_source.dart';
import 'package:app/features/projects/domain/entities/project.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

const _baseUrl = 'https://apex.pntr.dev/api/v1';

void main() {
  final tokensPath = Platform.environment['APEX_LIVE_TOKENS'];
  final skip = tokensPath == null ? 'Set APEX_LIVE_TOKENS to run' : false;
  late Map<String, dynamic> tokens;
  late Dio ownerDio;
  late Dio inviteeDio;
  late ProjectsDataSourceRemote owner;
  late ProjectsDataSourceRemote invitee;
  late String projectId;

  Dio dioFor(String who) => Dio(
    BaseOptions(
      baseUrl: _baseUrl,
      headers: {'Authorization': 'Bearer ${tokens[who]['id_token']}'},
    ),
  );

  setUpAll(() async {
    if (tokensPath == null) return;
    tokens =
        jsonDecode(File(tokensPath).readAsStringSync()) as Map<String, dynamic>;
    ownerDio = dioFor('owner');
    inviteeDio = dioFor('invitee');
    owner = ProjectsDataSourceRemote(ownerDio);
    invitee = ProjectsDataSourceRemote(inviteeDio);
    // Same session setup the app does after Firebase sign-in.
    for (final (dio, who, first) in [
      (ownerDio, 'owner', 'LiveTest Owner'),
      (inviteeDio, 'invitee', 'LiveTest Invitee'),
    ]) {
      final session = await dio.post<Map<String, dynamic>>(
        '/auth/firebase',
        data: {'id_token': tokens[who]['id_token']},
      );
      // ignore: avoid_print
      print('$who /auth/firebase → ${session.data}');
      if (session.data!['profile_complete'] != true) {
        await dio.patch<Object>(
          '/users/me',
          data: {
            'first_name': first,
            'last_name': 'Apex',
            'contact_email': tokens[who]['email'],
          },
        );
      }
    }
  });

  test('owner creates a project', () async {
    final project = await owner.createProject(
      ProjectDraft(
        projectName: 'LIVE TEST ${DateTime.now().toIso8601String()}',
        description: 'Created by the app\'s live API test; safe to delete.',
        latitude: 0.40441,
        longitude: 32.45940,
        locationName: 'Wakiso, near Nansana trading centre',
        plannedBudget: 140000000,
        currency: 'UGX',
        targetCompletionDate: DateTime(2027, 3, 1),
      ),
    );
    projectId = project.projectId;
    expect(project.projectName, startsWith('LIVE TEST'));
    expect(project.status, ProjectStatus.active);
    expect(project.plannedBudget, 140000000);
    expect(project.targetCompletionDate, DateTime(2027, 3, 1));
  }, skip: skip);

  test('it shows in the owner\'s list, also filtered by status', () async {
    final all = await owner.listProjects();
    expect(all.map((p) => p.projectId), contains(projectId));
    final active = await owner.listProjects(status: ProjectStatus.active);
    expect(active.map((p) => p.projectId), contains(projectId));
  }, skip: skip);

  test('details say the caller is the owner', () async {
    final project = await owner.getProject(projectId);
    expect(project.currentUserRole, ProjectRole.owner);
    expect(project.isOwner, isTrue);
  }, skip: skip);

  test('pause (SUSPENDED) and resume round-trip', () async {
    final paused = await owner.updateProject(
      projectId,
      const ProjectDraft(status: ProjectStatus.suspended),
    );
    expect(paused.status, ProjectStatus.suspended);
    final resumed = await owner.updateProject(
      projectId,
      const ProjectDraft(status: ProjectStatus.active),
    );
    expect(resumed.status, ProjectStatus.active);
  }, skip: skip);

  test('members list has the owner as owner', () async {
    final members = await owner.listMembers(projectId);
    expect(members, hasLength(1));
    expect(members.single.role, ProjectRole.owner);
  }, skip: skip);

  test('owner invites a site manager', () async {
    final email = tokens['invitee']['email'] as String;
    final message = await owner.inviteMember(
      projectId,
      email,
      ProjectRole.projectManager,
      message: "You've been invited to join a project on Apex.",
    );
    expect(message, 'Invitation sent to $email');
    // Not a member until they accept.
    final members = await owner.listMembers(projectId);
    expect(members.map((m) => m.contactEmail), isNot(contains(email)));
  }, skip: skip);

  test('the invitee can\'t see the project before accepting', () async {
    final failure = await invitee
        .getProject(projectId)
        .then<Object>((p) => p, onError: (Object e) => mapErrorToFailure(e));
    // ignore: avoid_print
    print('invitee GET project before accepting → $failure');
    expect(failure, isNot(isA<Project>()));
  }, skip: skip);

  test('a bad invite token is rejected with a readable reason', () async {
    final failure = await invitee
        .acceptInvitation('not-a-real-token')
        .then<Object>((id) => id, onError: (Object e) => mapErrorToFailure(e));
    // ignore: avoid_print
    print('accept bad token → $failure');
    expect(failure, isNot(isA<String>()));
  }, skip: skip);

  test('accepting a real invite joins the project', () async {
    final token = Platform.environment['APEX_INVITE_TOKEN'];
    if (token == null) {
      markTestSkipped('Set APEX_INVITE_TOKEN (from the invite email)');
      return;
    }
    final joined = await invitee.acceptInvitation(token);
    final project = await invitee.getProject(joined);
    expect(project.currentUserRole, ProjectRole.projectManager);
  }, skip: skip);
}
