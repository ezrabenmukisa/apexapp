import 'dart:io';

import 'package:app/core/files/documents.dart';
import 'package:app/core/network/auth_interceptor.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import '../../helpers/fake_http.dart';

class _TempPaths extends PathProviderPlatform with MockPlatformInterfaceMixin {
  _TempPaths(this.dir);

  final Directory dir;

  @override
  Future<String?> getTemporaryPath() async => dir.path;
}

void main() {
  const receiptUrl =
      'https://apex-media.s3.amazonaws.com/evidence/receipt_media/'
      '2eb61fca-8382-450c-a2f1-9d2b.pdf?X-Amz-Signature=abc&X-Amz-Expires=3600';

  group('DocumentRef', () {
    test(
      'takes the file name from a presigned URL, ignoring the signature',
      () {
        final doc = DocumentRef.fromUrl(receiptUrl);
        expect(doc.name, '2eb61fca-8382-450c-a2f1-9d2b.pdf');
        expect(doc.isPdf, isTrue);
        expect(doc.mimeType, 'application/pdf');
      },
    );

    test('recognises photo receipts', () {
      final doc = DocumentRef.fromUrl('https://x.test/r/receipt.JPG?sig=1');
      expect(doc.isImage, isTrue);
      expect(doc.isPdf, isFalse);
      expect(doc.mimeType, 'image/jpeg');
    });
  });

  group('DocumentCache', () {
    late Directory tmp;
    late FakeHttp http;
    late DocumentCache cache;

    setUp(() async {
      tmp = await Directory.systemTemp.createTemp('apex_docs_test');
      PathProviderPlatform.instance = _TempPaths(tmp);
      http = FakeHttp();
      final dio = http.dio(baseUrl: 'https://api.test/api/v1');
      // A real Firebase token must never be sent to S3.
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (o, h) {
            if (o.extra[AuthInterceptor.skipAuthKey] != true) {
              o.headers['Authorization'] = 'Bearer secret';
            }
            h.next(o);
          },
        ),
      );
      cache = DocumentCache(dio);
    });

    tearDown(() => tmp.delete(recursive: true));

    const path = '/evidence/receipt_media/2eb61fca-8382-450c-a2f1-9d2b.pdf';

    test(
      'downloads once without the Firebase token, then serves the cache',
      () async {
        http.on('GET', path, 200, '%PDF-1.4 receipt');

        final first = await cache.fetch(DocumentRef.fromUrl(receiptUrl));
        // A fresh presigned link to the same file: no second download.
        final second = await cache.fetch(
          DocumentRef.fromUrl(receiptUrl.replaceFirst('abc', 'xyz')),
        );

        expect(await first.readAsString(), contains('%PDF-1.4 receipt'));
        expect(second.path, first.path);
        expect(http.where('GET', path), hasLength(1));
        expect(
          http.requests.single.options.headers['Authorization'],
          isNull,
          reason: 'presigned S3 links must go without the Firebase token',
        );
      },
    );

    test('an expired link (403) explains what to do', () async {
      http.on('GET', path, 403, {'Code': 'AccessDenied'});

      await expectLater(
        cache.fetch(DocumentRef.fromUrl(receiptUrl)),
        throwsA(
          isA<DocumentException>().having(
            (e) => e.message,
            'message',
            contains('expired'),
          ),
        ),
      );
      expect(
        Directory('${tmp.path}/documents').listSync(),
        isEmpty,
        reason: 'no half-downloaded file is left behind',
      );
    });

    test('sample data has no file to open', () async {
      await expectLater(
        cache.fetch(DocumentRef.fromUrl('mock://receipt/bricks-invoice.pdf')),
        throwsA(isA<DocumentException>()),
      );
    });

    test('opens a receipt that is still on the phone', () async {
      final local = File('${tmp.path}/picked.pdf')..writeAsStringSync('%PDF');
      final file = await cache.fetch(
        DocumentRef(name: 'picked.pdf', localPath: local.path),
      );
      expect(file.path, local.path);
      expect(http.requests, isEmpty);
    });
  });
}
