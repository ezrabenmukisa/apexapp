import 'dart:io';

import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:file_picker/file_picker.dart';
import 'package:injectable/injectable.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../network/auth_interceptor.dart';

/// A receipt or other document to show in the in-app viewer: a link from
/// the API (presigned S3 URL) or a file still on this phone.
class DocumentRef extends Equatable {
  const DocumentRef({required this.name, this.url, this.localPath})
    : assert(url != null || localPath != null);

  /// From an API link: the file name is the last path segment, e.g.
  /// `…/2eb61fca-….pdf?X-Amz-Signature=…` → `2eb61fca-….pdf`.
  factory DocumentRef.fromUrl(String url) => DocumentRef(
    name: Uri.tryParse(url)?.pathSegments.lastOrNull ?? url,
    url: url,
  );

  final String name;
  final String? url;
  final String? localPath;

  String get _ext {
    final dot = name.lastIndexOf('.');
    return dot < 0 ? '' : name.substring(dot + 1).toLowerCase();
  }

  bool get isPdf => _ext == 'pdf';
  bool get isImage =>
      const {'jpg', 'jpeg', 'png', 'webp', 'heic', 'gif'}.contains(_ext);

  String get mimeType => switch (_ext) {
    'pdf' => 'application/pdf',
    'jpg' || 'jpeg' => 'image/jpeg',
    'png' => 'image/png',
    'webp' => 'image/webp',
    'heic' => 'image/heic',
    'gif' => 'image/gif',
    _ => 'application/octet-stream',
  };

  @override
  List<Object?> get props => [name, url, localPath];
}

class DocumentException implements Exception {
  const DocumentException(this.message);

  final String message;

  @override
  String toString() => 'DocumentException: $message';
}

/// Downloads documents once into the app's cache so they can be rendered,
/// shared and saved. Keyed by the URL's path: presigned query strings change
/// on every API call, the file behind them doesn't.
@lazySingleton
class DocumentCache {
  DocumentCache(this._dio);

  final Dio _dio;

  Future<File> fetch(DocumentRef doc) async {
    final local = doc.localPath;
    if (local != null) {
      final file = File(local);
      if (await file.exists()) return file;
      throw const DocumentException('This file is no longer on the phone.');
    }
    final uri = Uri.tryParse(doc.url ?? '');
    if (uri == null || !uri.isScheme('https') && !uri.isScheme('http')) {
      throw const DocumentException(
        'This is sample data — there is no real file to open.',
      );
    }

    final dir = Directory('${(await getTemporaryDirectory()).path}/documents');
    await dir.create(recursive: true);
    final key = uri.path.replaceAll(RegExp(r'[^A-Za-z0-9._-]+'), '_');
    final file = File('${dir.path}/$key');
    if (await file.exists() && await file.length() > 0) return file;

    final partial = File('${file.path}.part');
    try {
      await _dio.download(
        uri.toString(),
        partial.path,
        // Presigned S3 link: no Firebase token (S3 rejects a second auth
        // scheme, and the token must never leave the Apex API).
        options: Options(
          extra: {AuthInterceptor.skipAuthKey: true},
          receiveTimeout: const Duration(minutes: 2),
        ),
      );
      return await partial.rename(file.path);
    } on DioException catch (e) {
      if (await partial.exists()) await partial.delete();
      throw DocumentException(switch (e.response?.statusCode) {
        403 => 'This link has expired. Go back and open the evidence again.',
        404 => 'The file is no longer available.',
        _ when e.response == null =>
          'No connection. Check your signal and try again.',
        _ => 'Couldn\'t download the file.',
      });
    }
  }
}

/// Secondary actions on an opened document.
@lazySingleton
class DocumentActions {
  /// The system share sheet (WhatsApp, email, Drive, "Save to Files"…).
  Future<void> share(File file, DocumentRef doc) => SharePlus.instance.share(
    ShareParams(
      files: [XFile(file.path, mimeType: doc.mimeType, name: doc.name)],
      title: doc.name,
    ),
  );

  /// Lets the user pick where to save a copy (Downloads, Drive…). Returns
  /// false if they cancel.
  Future<bool> save(File file, DocumentRef doc) async {
    final saved = await FilePicker.saveFile(
      fileName: doc.name,
      bytes: await file.readAsBytes(),
      mimeType: doc.mimeType,
      dialogTitle: 'Save ${doc.name}',
    );
    return saved != null;
  }
}
