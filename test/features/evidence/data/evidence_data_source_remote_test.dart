import 'dart:io';

import 'package:app/core/network/auth_interceptor.dart';
import 'package:app/features/evidence/data/datasources/evidence_data_source.dart';
import 'package:app/features/evidence/data/models/evidence_model.dart';
import 'package:app/features/evidence/domain/entities/evidence.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_http.dart';

const _s3 = 'https://apex-bucket.s3.test';

Map<String, dynamic> _evidenceJson(String status) => {
  'evidence_id': 'e1',
  'milestone_id': 'm1',
  'description': 'Walls up',
  'captured_latitude': 0.4,
  'captured_longitude': 32.4,
  'captured_at': '2026-11-05T10:00:00Z',
  'site_media_urls': ['https://cdn.test/site_media/k1.jpg'],
  'expenditure_notes': null,
  'total_cost_spent': null,
  'receipt_media_urls': <String>[],
  'status': status,
  'submitted_at': '2026-11-05T10:05:00Z',
};

void main() {
  late Directory tmp;
  final fix = GeoFix(
    latitude: 0.40441,
    longitude: 32.4594,
    accuracyMetres: 4,
    timestamp: DateTime.utc(2026, 11, 5, 10),
  );

  setUp(() => tmp = Directory.systemTemp.createTempSync('apex_evidence'));
  tearDown(() => tmp.deleteSync(recursive: true));

  String file(String name, String contents) =>
      (File('${tmp.path}/$name')..writeAsStringSync(contents)).path;

  group('API enums', () {
    test('evidence status reads REQUEST_CHANGES', () {
      expect(
        EvidenceStatus.fromApi('REQUEST_CHANGES'),
        EvidenceStatus.changesRequested,
      );
      expect(
        EvidenceModel.fromJson(_evidenceJson('FLAGGED')).status,
        EvidenceStatus.flagged,
      );
    });

    test('review decisions use the API values', () {
      expect(ReviewDecision.values.map((d) => d.apiValue), [
        'APPROVED',
        'REQUEST_CHANGES',
        'FLAGGED',
      ]);
    });
  });

  group('submitEvidence', () {
    FakeHttp routed() => FakeHttp()
      ..on('POST', '/api/v1/milestones/m1/evidence/upload-urls', 200, [
        {'file_key': 'site_media/k1.jpg', 'upload_url': '$_s3/k1?sig=1'},
        {'file_key': 'site_media/k2.mp4', 'upload_url': '$_s3/k2?sig=2'},
      ])
      ..on('PUT', '/k1', 200)
      ..on('PUT', '/k2', 200)
      ..on(
        'POST',
        '/api/v1/milestones/m1/evidence',
        201,
        _evidenceJson('SUBMITTED'),
      );

    EvidenceDraft draft({List<ReceiptFile> receipts = const []}) =>
        EvidenceDraft(
          milestoneId: 'm1',
          description: 'Walls up',
          siteMedia: [
            CapturedMedia(
              id: 'c1',
              kind: MediaKind.photo,
              fix: fix,
              localPath: file('east.jpg', 'JPEGDATA'),
            ),
            CapturedMedia(
              id: 'c2',
              kind: MediaKind.video,
              fix: fix,
              localPath: file('walk.mp4', 'MP4DATA'),
            ),
          ],
          receipts: receipts,
          expenditureNotes: 'Bricks',
          totalCostSpent: 1200,
        );

    test('asks for site media upload URLs by file name', () async {
      final http = routed();
      await EvidenceDataSourceRemote(http.dio()).submitEvidence(draft());

      final ask = http.where(
        'POST',
        '/api/v1/milestones/m1/evidence/upload-urls',
      );
      expect(ask.single.data, {
        'filenames': ['east.jpg', 'walk.mp4'],
        'folder': 'site_media',
      });
    });

    test('PUTs each file to S3 without the sign-in token', () async {
      final http = routed();
      await EvidenceDataSourceRemote(http.dio()).submitEvidence(draft());

      final puts = http.where('PUT').toList();
      expect(puts.map((p) => p.uri.toString()), [
        '$_s3/k1?sig=1',
        '$_s3/k2?sig=2',
      ]);
      expect(puts.map((p) => String.fromCharCodes(p.bytes!)), [
        'JPEGDATA',
        'MP4DATA',
      ]);
      expect(puts.map((p) => p.options.contentType), [
        'image/jpeg',
        'video/mp4',
      ]);
      for (final p in puts) {
        expect(p.options.extra[AuthInterceptor.skipAuthKey], isTrue);
      }
    });

    test('submits JSON with the returned file keys', () async {
      final http = routed();
      final evidence = await EvidenceDataSourceRemote(
        http.dio(),
      ).submitEvidence(draft());

      final submit = http
          .where('POST', '/api/v1/milestones/m1/evidence')
          .single;
      expect(submit.data, {
        'description': 'Walls up',
        'captured_latitude': 0.40441,
        'captured_longitude': 32.4594,
        'captured_at': '2026-11-05T10:00:00.000Z',
        'site_media_keys': ['site_media/k1.jpg', 'site_media/k2.mp4'],
        'expenditure_notes': 'Bricks',
        'total_cost_spent': 1200.0,
      });
      expect(evidence.status, EvidenceStatus.submitted);
    });

    test('uploads receipts to the receipt_media folder', () async {
      // Both upload-urls calls share one canned answer; only the request
      // bodies matter here.
      final http = routed();
      final remote = EvidenceDataSourceRemote(http.dio());
      await remote.submitEvidence(
        draft(
          receipts: [
            ReceiptFile(
              id: 'r1',
              name: 'invoice.pdf',
              localPath: file('invoice.pdf', 'PDF'),
            ),
          ],
        ),
      );

      final asks = http
          .where('POST', '/api/v1/milestones/m1/evidence/upload-urls')
          .map((r) => r.data)
          .toList();
      expect(asks.last, {
        'filenames': ['invoice.pdf'],
        'folder': 'receipt_media',
      });
      final submit = http
          .where('POST', '/api/v1/milestones/m1/evidence')
          .single;
      expect((submit.data! as Map)['receipt_media_keys'], isNotEmpty);
    });

    test('a capture missing from the phone fails before any upload', () async {
      final http = routed();
      final broken = EvidenceDraft(
        milestoneId: 'm1',
        description: 'x',
        siteMedia: [CapturedMedia(id: 'c1', kind: MediaKind.photo, fix: fix)],
      );

      await expectLater(
        EvidenceDataSourceRemote(http.dio()).submitEvidence(broken),
        throwsA(anything),
      );
      expect(http.requests, isEmpty);
    });

    test('an S3 failure stops before submitting', () async {
      final http = routed()
        ..on('PUT', '/k2', 403, {'error': 'SignatureDoesNotMatch'});

      await expectLater(
        EvidenceDataSourceRemote(http.dio()).submitEvidence(draft()),
        throwsA(isA<DioException>()),
      );
      expect(http.where('POST', '/api/v1/milestones/m1/evidence'), isEmpty);
    });
  });

  test('reviewEvidence posts an EvidenceReviewCreate body', () async {
    final http = FakeHttp()
      ..on('POST', '/api/v1/evidence/e1/reviews', 201, {
        'evidence_id': 'e1',
        'decision': 'REQUEST_CHANGES',
        'comment': 'Show the DPC',
        'message': 'Review submitted.',
      });

    final message = await EvidenceDataSourceRemote(
      http.dio(),
    ).reviewEvidence('e1', ReviewDecision.requestChanges, 'Show the DPC');

    expect(http.requests.single.data, {
      'decision': 'REQUEST_CHANGES',
      'comment': 'Show the DPC',
    });
    expect(message, 'Review submitted.');
  });
}
