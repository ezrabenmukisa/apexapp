import 'package:flutter/foundation.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/device/device_services.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/repository_guard.dart';
import '../../../../core/sync/data_changes.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notifications_repository.dart';
import '../datasources/notifications_data_source.dart';

@LazySingleton(as: NotificationsRepository)
class NotificationsRepositoryImpl
    with RepositoryGuard
    implements NotificationsRepository {
  NotificationsRepositoryImpl(this._source, this._push, this._changes);

  final NotificationsDataSource _source;
  final PushTokenProvider _push;
  final DataChanges _changes;

  @override
  Future<Either<Failure, List<AppNotification>>> list({
    bool unreadOnly = false,
  }) => guard(() async {
    final items = await _source.list(unreadOnly: unreadOnly);
    return [...items]..sort(
      (a, b) =>
          (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)),
    );
  });

  @override
  Future<Either<Failure, Unit>> markRead(String notificationId) =>
      guard(() async {
        await _source.markRead(notificationId, isRead: true);
        _changes.publish(DataTopic.notifications);
        return unit;
      });

  @override
  Future<Either<Failure, Unit>> registerThisDevice() => guard(() async {
    final token = await _push.token();
    if (token == null) return unit;
    await _source.registerPushToken(
      token,
      defaultTargetPlatform == TargetPlatform.iOS
          ? DevicePlatform.ios
          : DevicePlatform.android,
    );
    return unit;
  });
}
