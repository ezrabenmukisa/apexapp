import 'dart:convert';

import 'package:app/features/projects/data/datasources/projects_data_source.dart';
import 'package:app/features/projects/domain/entities/project.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// Records each request and answers with a canned JSON body.
class _RecordingAdapter implements HttpClientAdapter {
  _RecordingAdapter(this.status, this.body);

  final int status;
  final Object body;
  RequestOptions? last;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    last = options;
    return ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  ProjectsDataSourceRemote remoteFor(_RecordingAdapter adapter) =>
      ProjectsDataSourceRemote(
        Dio(BaseOptions(baseUrl: 'https://api.test/api/v1'))
          ..httpClientAdapter = adapter,
      );

  group('inviteMember', () {
    test('sends a ProjectInvitationCreate body', () async {
      final adapter = _RecordingAdapter(201, {
        'invitation_id': 'inv-1',
        'project_id': 'prj-1',
        'email': 'kato@example.com',
        'user_role': 'manager',
        'status': 'pending',
        'expires_at': '2026-11-11T10:00:00Z',
      });

      await remoteFor(adapter).inviteMember(
        'prj-1',
        'kato@example.com',
        ProjectRole.projectManager,
        message: 'Welcome aboard',
      );

      expect(adapter.last!.method, 'POST');
      expect(adapter.last!.uri.path, '/api/v1/projects/prj-1/members');
      expect(adapter.last!.data, {
        'contact_email': 'kato@example.com',
        'user_role': 'manager',
        'message': 'Welcome aboard',
      });
    });

    test('confirms with the invited email from the response', () async {
      final adapter = _RecordingAdapter(201, {
        'invitation_id': 'inv-1',
        'project_id': 'prj-1',
        'email': 'kato@example.com',
        'user_role': 'manager',
        'status': 'pending',
        'expires_at': '2026-11-11T10:00:00Z',
      });

      final message = await remoteFor(adapter).inviteMember(
        'prj-1',
        'kato@example.com',
        ProjectRole.projectManager,
        message: 'Hi',
      );

      expect(message, 'Invitation sent to kato@example.com');
    });
  });

  group('acceptInvitation', () {
    test('posts the token and returns the project to open', () async {
      final adapter = _RecordingAdapter(200, {
        'message': 'Invitation accepted',
        'project_id': 'prj-9',
      });

      final projectId = await remoteFor(adapter).acceptInvitation('tok-123');

      expect(adapter.last!.method, 'POST');
      expect(
        adapter.last!.uri.path,
        '/api/v1/projects/invitations/accept',
      );
      expect(adapter.last!.data, {'token': 'tok-123'});
      expect(projectId, 'prj-9');
    });
  });
}
