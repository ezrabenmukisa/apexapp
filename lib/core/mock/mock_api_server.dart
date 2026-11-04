import 'dart:convert';
import 'dart:math';

import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/auth/data/datasources/firebase_auth_data_source.dart';
import '../../features/auth/data/datasources/role_local_data_source.dart';
import '../../features/auth/data/datasources/session_local_data_source.dart';
import '../config/app_config.dart';
import '../error/exceptions.dart';
import '../utils/json.dart';

typedef JsonMap = Map<String, dynamic>;

/// In-app stand-in for Apex endpoints the live backend doesn't have yet
/// (used by features whose `LIVE_*` switch in `.env` is false).
///
/// Stores rows in the same snake_case JSON shapes as the API contract, so
/// mock data sources parse responses with the same models as the Dio ones.
/// Enforces the documented rules (owner-only writes, immutable evidence)
/// and persists per Firebase user in shared preferences. The first time a
/// user opens the app it is seeded with the prototype's sample project,
/// from the point of view of their `user_role`.
///
/// Identity comes from the real signed-in user: Firebase uid, the profile
/// cached from `GET /users/me` and the role remembered on this phone.
@lazySingleton
class MockApiServer {
  MockApiServer(this._auth, this._session, this._roles, this._prefs);

  final FirebaseAuthDataSource _auth;
  final SessionLocalDataSource _session;
  final RoleLocalDataSource _roles;
  final SharedPreferences _prefs;
  JsonMap? _profile;
  String? _userId;
  final _random = Random();

  String? _loadedUid;
  late Map<String, List<JsonMap>> _db;

  static const _tables = [
    'projects',
    'members',
    'milestones',
    'evidence',
    'notifications',
  ];

  // ---------------------------------------------------------------- infra

  /// Simulated latency, then loads the signed-in user's data (seeding it on
  /// first use). Every mock data source call awaits this first.
  Future<void> ready() async {
    await Future<void>.delayed(AppConfig.mockLatency);
    final uid = _auth.currentUid;
    if (uid == null) {
      throw const ServerException('Not authenticated', statusCode: 401);
    }
    if (_loadedUid == uid) return;
    final user = await _session.cachedUser(uid: uid);
    _userId = user?.userId ?? 'usr_$uid';
    _profile = {
      'first_name': user?.firstName ?? 'You',
      'last_name': user?.lastName ?? '',
      'contact_email': user?.contactEmail ?? '',
      'user_role': (_roles.read(uid) ?? user?.userRole)?.apiValue,
    };
    _load(uid);
  }

  String get _uid => _loadedUid!;
  String get _me => _userId!;

  List<JsonMap> _table(String name) {
    if (_loadedUid == null) {
      throw StateError('MockApiServer.ready() must be awaited first');
    }
    return _db[name]!;
  }

  void _load(String uid) {
    final raw = _prefs.getString(_key(uid));
    if (raw != null) {
      final decoded = jsonDecode(raw) as JsonMap;
      _db = {
        for (final t in _tables)
          t: [
            for (final r in decoded[t] as List? ?? []) JsonMap.from(r as Map),
          ],
      };
    } else {
      _db = {for (final t in _tables) t: <JsonMap>[]};
      _loadedUid = uid;
      _seed();
    }
    _loadedUid = uid;
    _save();
  }

  String _key(String uid) => 'mock_api.db.v1.$uid';

  void _save() => _prefs.setString(_key(_uid), jsonEncode(_db));

  String _id(String prefix) =>
      '${prefix}_${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}'
      '${_random.nextInt(1 << 16).toRadixString(36)}';

  JsonMap _copy(JsonMap row) => jsonDecode(jsonEncode(row)) as JsonMap;

  Never _notFound(String what) =>
      throw ServerException('$what not found', statusCode: 404);

  Never _forbidden() => throw const ServerException(
    'Only the project owner can do this.',
    statusCode: 403,
  );

  String? _roleOn(String projectId) {
    for (final m in _table('members')) {
      if (m['project_id'] == projectId && m['user_id'] == _me) {
        return m['user_role'] as String;
      }
    }
    return null;
  }

  void _requireMember(String projectId) {
    if (_roleOn(projectId) == null) _notFound('Project');
  }

  void _requireOwner(String projectId) {
    _requireMember(projectId);
    if (_roleOn(projectId) != 'OWNER') _forbidden();
  }

  JsonMap _projectRow(String id) => _table('projects').firstWhere(
    (p) => p['project_id'] == id,
    orElse: () => _notFound('Project'),
  );

  JsonMap _milestoneRow(String id) => _table('milestones').firstWhere(
    (m) => m['milestone_id'] == id,
    orElse: () => _notFound('Milestone'),
  );

  void _notify(String title, String body) => _table('notifications').insert(0, {
    'notification_id': _id('ntf'),
    'title': title,
    'body': body,
    'is_read': false,
    'created_at': DateTime.now().toUtc().toIso8601String(),
  });

  // ------------------------------------------------------------- projects

  List<JsonMap> listProjects({String? status}) => [
    for (final p in _table('projects'))
      if (_roleOn(p['project_id'] as String) != null &&
          (status == null || p['status'] == status))
        _copy(p),
  ];

  JsonMap getProject(String id) {
    _requireMember(id);
    return {..._copy(_projectRow(id)), 'current_user_role': _roleOn(id)};
  }

  JsonMap createProject(JsonMap body) {
    for (final f in [
      'project_name',
      'latitude',
      'longitude',
      'location_name',
    ]) {
      if (body[f] == null || body[f] == '') {
        throw ServerException('$f is required', statusCode: 422);
      }
    }
    final row = {
      'project_id': _id('prj'),
      'description': null,
      'planned_budget': null,
      'currency': 'UGX',
      'target_completion_date': null,
      ...body,
      'status': 'ACTIVE',
      'created_at': DateTime.now().toUtc().toIso8601String(),
    };
    _table('projects').add(row);
    _table('members').add(
      _member(
        row['project_id'] as String,
        _me,
        _myNameParts,
        _profile?['contact_email'] as String? ?? '',
        'OWNER',
      ),
    );
    _save();
    return _copy(row);
  }

  JsonMap updateProject(String id, JsonMap body) {
    _requireOwner(id);
    final row = _projectRow(id)..addAll(body);
    _save();
    return _copy(row);
  }

  // -------------------------------------------------------------- members

  (String, String) get _myNameParts => (
    _profile?['first_name'] as String? ?? 'You',
    _profile?['last_name'] as String? ?? '',
  );

  JsonMap _member(
    String projectId,
    String userId,
    (String, String) name,
    String email,
    String role,
  ) => {
    'project_id': projectId,
    'user_id': userId,
    'first_name': name.$1,
    'last_name': name.$2,
    'contact_email': email,
    'user_role': role,
  };

  List<JsonMap> listMembers(String projectId) {
    _requireMember(projectId);
    return [
      for (final m in _table('members'))
        if (m['project_id'] == projectId) _copy(m),
    ];
  }

  JsonMap inviteMember(String projectId, String email, String role) {
    _requireOwner(projectId);
    final members = _table('members');
    if (members.any(
      (m) => m['project_id'] == projectId && m['contact_email'] == email,
    )) {
      throw const ServerException(
        'That person is already on this project.',
        statusCode: 409,
      );
    }
    final local = email.split('@').first.replaceAll(RegExp(r'[._-]+'), ' ');
    final words = [
      for (final w in local.split(' '))
        if (w.isNotEmpty) '${w[0].toUpperCase()}${w.substring(1)}',
    ];
    members.add(
      _member(
        projectId,
        _id('usr'),
        (words.isEmpty ? email : words.first, words.skip(1).join(' ')),
        email,
        role,
      ),
    );
    _save();
    return {'message': 'Invitation sent to $email'};
  }

  JsonMap removeMember(String projectId, String userId) {
    _requireOwner(projectId);
    if (userId == _me) {
      throw const ServerException(
        'You can\'t remove yourself as owner.',
        statusCode: 400,
      );
    }
    _table('members').removeWhere(
      (m) => m['project_id'] == projectId && m['user_id'] == userId,
    );
    _save();
    return {'message': 'Member removed'};
  }

  // ----------------------------------------------------------- milestones

  List<JsonMap> listMilestones(String projectId) {
    _requireMember(projectId);
    return [
      for (final m in _table('milestones'))
        if (m['project_id'] == projectId) _copy(m),
    ]..sort((a, b) => (a['sequence'] as int).compareTo(b['sequence'] as int));
  }

  JsonMap getMilestone(String id) {
    final row = _milestoneRow(id);
    _requireMember(row['project_id'] as String);
    return _copy(row);
  }

  JsonMap createMilestone(String projectId, JsonMap body) {
    _requireOwner(projectId);
    for (final f in ['title', 'sequence', 'start_date']) {
      if (body[f] == null) {
        throw ServerException('$f is required', statusCode: 422);
      }
    }
    final row = {
      'milestone_id': _id('mst'),
      'project_id': projectId,
      'description': null,
      'due_date': null,
      'planned_budget': null,
      ...body,
      'status': 'NOT_STARTED',
    };
    _table('milestones').add(row);
    _resequence(
      projectId,
      row['milestone_id'] as String,
      row['sequence'] as int,
    );
    _save();
    return _copy(row);
  }

  JsonMap updateMilestone(String id, JsonMap body) {
    final row = _milestoneRow(id);
    final projectId = row['project_id'] as String;
    _requireOwner(projectId);
    row.addAll(body);
    if (body['sequence'] case final int seq) _resequence(projectId, id, seq);
    _save();
    return _copy(row);
  }

  /// Keeps sequences 1..n, placing [movedId] at [target].
  void _resequence(String projectId, String movedId, int target) {
    final rows =
        _table('milestones')
            .where(
              (m) =>
                  m['project_id'] == projectId && m['milestone_id'] != movedId,
            )
            .toList()
          ..sort(
            (a, b) => (a['sequence'] as int).compareTo(b['sequence'] as int),
          );
    final moved = _milestoneRow(movedId);
    rows.insert((target - 1).clamp(0, rows.length), moved);
    for (var i = 0; i < rows.length; i++) {
      rows[i]['sequence'] = i + 1;
    }
  }

  // ------------------------------------------------------------- evidence

  JsonMap getEvidence(String milestoneId) {
    final milestone = getMilestone(milestoneId);
    final rows = _table(
      'evidence',
    ).where((e) => e['milestone_id'] == milestone['milestone_id']).toList();
    if (rows.isEmpty) _notFound('Evidence');
    rows.sort(
      (a, b) =>
          (b['submitted_at'] as String).compareTo(a['submitted_at'] as String),
    );
    return _copy(rows.first);
  }

  JsonMap submitEvidence(
    String milestoneId,
    JsonMap fields, {
    required List<String> siteMedia,
    required List<String> receipts,
  }) {
    final milestone = _milestoneRow(milestoneId);
    final projectId = milestone['project_id'] as String;
    if (_roleOn(projectId) != 'PROJECT_MANAGER') {
      throw const ServerException(
        'Only the site manager can submit evidence.',
        statusCode: 403,
      );
    }
    if (siteMedia.isEmpty) {
      throw const ServerException(
        'At least one site photo or video is required.',
        statusCode: 422,
      );
    }
    final now = DateTime.now().toUtc().toIso8601String();
    final row = {
      'evidence_id': _id('evd'),
      'milestone_id': milestoneId,
      ...fields,
      'site_media_urls': [for (final m in siteMedia) 'mock://site/$m'],
      'receipt_media_urls': [for (final r in receipts) 'mock://receipt/$r'],
      'status': 'SUBMITTED',
      'submitted_at': now,
    };
    _table('evidence').add(row);
    milestone['status'] = 'SUBMITTED';
    _notify(
      '${milestone['title']} evidence submitted',
      'You submitted ${milestone['title']} evidence at '
          '${_clock(DateTime.now())}. '
          '${_ownerName(projectId)} will review it.',
    );
    _save();
    return _copy(row);
  }

  JsonMap reviewEvidence(String evidenceId, String decision, String comment) {
    final evidence = _table('evidence').firstWhere(
      (e) => e['evidence_id'] == evidenceId,
      orElse: () => _notFound('Evidence'),
    );
    final milestone = _milestoneRow(evidence['milestone_id'] as String);
    final projectId = milestone['project_id'] as String;
    _requireOwner(projectId);
    if (evidence['status'] != 'SUBMITTED') {
      throw const ServerException(
        'This evidence has already been reviewed.',
        statusCode: 409,
      );
    }
    if (comment.trim().isEmpty) {
      throw const ServerException('comment is required', statusCode: 422);
    }
    final (status, verb) = switch (decision) {
      'APPROVE' => ('APPROVED', 'approved'),
      'REQUEST_CHANGES' => ('CHANGES_REQUESTED', 'requested changes on'),
      'FLAG' => ('FLAGGED', 'flagged'),
      _ => throw const ServerException('Unknown decision', statusCode: 422),
    };
    evidence
      ..['status'] = status
      ..['latest_review'] = {
        'decision': decision,
        'comment': comment,
        'reviewed_at': DateTime.now().toUtc().toIso8601String(),
      };
    milestone['status'] = status;
    final title = milestone['title'];
    _notify(switch (decision) {
      'APPROVE' => '$title approved',
      'REQUEST_CHANGES' => 'Changes requested on $title',
      _ => '$title flagged',
    }, 'You $verb $title at ${_clock(DateTime.now())}: "$comment"');
    _save();
    return {
      'evidence_id': evidenceId,
      'decision': decision,
      'comment': comment,
      'message': 'Review recorded',
    };
  }

  String _ownerName(String projectId) {
    final owner = _table('members').firstWhere(
      (m) => m['project_id'] == projectId && m['user_role'] == 'OWNER',
      orElse: () => {'first_name': 'The owner'},
    );
    return owner['first_name'] as String;
  }

  // -------------------------------------------------------- notifications

  List<JsonMap> listNotifications({bool unreadOnly = false}) => [
    for (final n in _table('notifications'))
      if (!unreadOnly || n['is_read'] != true) _copy(n),
  ];

  JsonMap markNotification(String id, bool isRead) {
    final row = _table('notifications').firstWhere(
      (n) => n['notification_id'] == id,
      orElse: () => _notFound('Notification'),
    );
    row['is_read'] = isRead;
    _save();
    return {'notification_id': id, 'is_read': isRead};
  }

  JsonMap registerPushToken(String token, String platform) => {
    'message': 'Push token registered',
  };

  // ----------------------------------------------------------------- seed

  static String _clock(DateTime d) {
    final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final m = d.minute.toString().padLeft(2, '0');
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '$h:$m ${d.hour < 12 ? 'AM' : 'PM'}, ${d.day} ${months[d.month - 1]}';
  }

  /// The prototype's sample project, dated relative to today so "17 days
  /// left" stays true whenever the app is first opened.
  void _seed() {
    final role = _profile?['user_role'] as String?;
    final isManager = role == 'MANAGER' || role == 'PROJECT_MANAGER';
    final now = DateTime.now();
    DateTime day(int offset) => DateTime(now.year, now.month, now.day + offset);
    String date(int offset) => Json.date(day(offset))!;
    String at(int offset, int hour, int minute) => DateTime(
      now.year,
      now.month,
      now.day + offset,
      hour,
      minute,
    ).toUtc().toIso8601String();

    const pid = 'prj_sample';
    const lat = 0.40441, lng = 32.45940;
    _db['projects']!.add({
      'project_id': pid,
      'project_name': 'Four-bedroom house',
      'description': 'Family home, plans approved',
      'latitude': lat,
      'longitude': lng,
      'location_name': 'Wakiso, near Nansana trading centre',
      'planned_budget': 140000000,
      'currency': 'UGX',
      'target_completion_date': date(82),
      'status': 'ACTIVE',
      'created_at': at(-44, 9, 0),
    });

    final email = _profile?['contact_email'] as String? ?? '';
    final members = _db['members']!;
    if (isManager) {
      members
        ..add(
          _member(
            pid,
            'usr_sarah',
            ('Sarah', 'Namuli'),
            'sarah@example.com',
            'OWNER',
          ),
        )
        ..add(_member(pid, _me, _myNameParts, email, 'PROJECT_MANAGER'));
    } else {
      members
        ..add(_member(pid, _me, _myNameParts, email, 'OWNER'))
        ..add(
          _member(
            pid,
            'usr_kato',
            ('Kato', 'Builders'),
            'kato@example.com',
            'PROJECT_MANAGER',
          ),
        );
    }

    JsonMap milestone(
      String id,
      int seq,
      String title,
      String brief,
      int start,
      int due,
      num budget,
      String status,
    ) => {
      'milestone_id': id,
      'project_id': pid,
      'title': title,
      'sequence': seq,
      'description': brief,
      'start_date': date(start),
      'due_date': date(due),
      'planned_budget': budget,
      'status': status,
    };
    _db['milestones']!.addAll([
      milestone(
        'mst_foundation',
        1,
        'Foundation',
        'Footings, blockwork to plinth and damp-proof course. Show each side and a DPC close-up.',
        -44,
        -14,
        35000000,
        'APPROVED',
      ),
      milestone(
        'mst_walling',
        2,
        'Walling',
        'All four walls up to ring beam, ring beam cast. Please show each wall, a ring beam close-up and a short walk-through.',
        -13,
        16,
        28000000,
        isManager ? 'IN_PROGRESS' : 'SUBMITTED',
      ),
      milestone(
        'mst_roofing',
        3,
        'Roofing',
        'Trusses fixed and iron sheets on. Show the trusses before sheeting and the finished roof from each side.',
        17,
        37,
        32000000,
        'NOT_STARTED',
      ),
      milestone(
        'mst_finishing',
        4,
        'Finishing',
        'Plaster, floors, windows, doors and paint. A walk-through of every room.',
        38,
        82,
        45000000,
        'NOT_STARTED',
      ),
    ]);

    final evidence = _db['evidence']!;
    evidence.add({
      'evidence_id': 'evd_foundation_2',
      'milestone_id': 'mst_foundation',
      'description':
          'Footings and blockwork to plinth complete on all sides. DPC laid; close-up added as requested.',
      'captured_latitude': lat + 0.00011,
      'captured_longitude': lng + 0.00008,
      'captured_at': at(-15, 15, 50),
      'site_media_urls': [
        'mock://site/front-footing',
        'mock://site/side-footing',
        'mock://site/dpc-close-up',
        'mock://site/video-walkthrough',
      ],
      'expenditure_notes':
          'Cement, sand, aggregate and blocks; labour weeks 1–4.',
      'total_cost_spent': 34200000,
      'receipt_media_urls': [
        'mock://receipt/hardware-invoice.pdf',
        'mock://receipt/blocks-receipt.jpg',
      ],
      'status': 'APPROVED',
      'submitted_at': at(-15, 16, 15),
      'latest_review': {
        'decision': 'APPROVE',
        'comment': 'Good, thanks for the DPC close-up.',
        'reviewed_at': at(-14, 21, 14),
      },
    });
    if (!isManager) {
      evidence.add({
        'evidence_id': 'evd_walling_1',
        'milestone_id': 'mst_walling',
        'description':
            'All four walls are up to ring beam. Ring beam cast on east and north; west wall reaches lintel level this week.',
        'captured_latitude': lat + 0.00012,
        'captured_longitude': lng + 0.00010,
        'captured_at': at(-2, 10, 42),
        'site_media_urls': [
          'mock://site/east-wall-ring-beam',
          'mock://site/video-walkthrough',
          'mock://site/north-wall',
          'mock://site/west-wall',
          'mock://site/south-wall',
          'mock://site/ring-beam-close-up',
          'mock://site/lintel-level',
          'mock://site/scaffolding',
          'mock://site/materials-on-site',
          'mock://site/site-overview',
        ],
        'expenditure_notes':
            'Bricks for all four walls, cement and steel for the ring beam, labour weeks 5–8.',
        'total_cost_spent': 27450000,
        'receipt_media_urls': [
          'mock://receipt/bricks-invoice.pdf',
          'mock://receipt/steel-receipt.jpg',
          'mock://receipt/cement-receipt.jpg',
        ],
        'status': 'SUBMITTED',
        'submitted_at': at(-2, 10, 58),
      });
    }

    JsonMap note(String title, String body, bool read, String created) => {
      'notification_id': _id('ntf'),
      'title': title,
      'body': body,
      'is_read': read,
      'created_at': created,
    };
    final dueText = _clock(day(16)).split(', ').last;
    _db['notifications']!.addAll(
      isManager
          ? [
              note(
                'Walling is due $dueText',
                '16 days left on Four-bedroom house.',
                false,
                at(0, 8, 0),
              ),
              note(
                'Foundation approved',
                'Sarah approved Foundation at ${_clock(day(-14).add(const Duration(hours: 21, minutes: 14)))}: "Good, thanks for the DPC close-up."',
                false,
                at(-14, 21, 14),
              ),
              note(
                'Changes requested on Foundation',
                'Sarah asked: "Please add a close-up of the damp-proof course."',
                true,
                at(-16, 9, 30),
              ),
            ]
          : [
              note(
                'Walling evidence submitted',
                'Kato Builders uploaded Walling evidence at ${_clock(day(-2).add(const Duration(hours: 10, minutes: 58)))}.',
                false,
                at(-2, 10, 58),
              ),
              note(
                'Walling is due $dueText',
                '16 days left on Four-bedroom house.',
                false,
                at(0, 8, 0),
              ),
              note(
                'Foundation approved',
                'You approved Foundation at ${_clock(day(-14).add(const Duration(hours: 21, minutes: 14)))}: "Good, thanks for the DPC close-up."',
                true,
                at(-14, 21, 14),
              ),
              note(
                'Changes requested on Foundation',
                'You asked Kato Builders: "Please add a close-up of the damp-proof course."',
                true,
                at(-16, 9, 30),
              ),
              note(
                'Foundation evidence submitted',
                'Kato Builders uploaded Foundation evidence at ${_clock(day(-18).add(const Duration(hours: 16, minutes: 15)))}.',
                true,
                at(-18, 16, 15),
              ),
            ],
    );
  }
}
