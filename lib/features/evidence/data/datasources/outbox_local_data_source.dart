import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';

import '../../domain/entities/outbox_item.dart';

/// Queued and sent submissions, stored in the platform keystore-backed
/// secure storage (encrypted at rest) and keyed by Firebase uid.
@lazySingleton
class OutboxLocalDataSource {
  const OutboxLocalDataSource(this._storage);

  final FlutterSecureStorage _storage;

  String _key(String uid) => 'apex.outbox.v1.$uid';

  Future<List<OutboxItem>> read(String uid) async {
    final raw = await _storage.read(key: _key(uid));
    if (raw == null) return [];
    return [
      for (final e in jsonDecode(raw) as List)
        OutboxItem.fromJson(e as Map<String, dynamic>),
    ];
  }

  Future<void> write(String uid, List<OutboxItem> items) => _storage.write(
    key: _key(uid),
    value: jsonEncode([for (final i in items) i.toJson()]),
  );
}
