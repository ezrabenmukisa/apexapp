import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/mock/mock_api_server.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/utils/json.dart';
import '../../domain/entities/app_notification.dart';
import '../models/notification_model.dart';

/// `/notifications` and `/devices/push-token`.
abstract interface class NotificationsDataSource {
  Future<List<AppNotification>> list({bool unreadOnly = false});
  Future<void> markRead(String notificationId, {required bool isRead});
  Future<void> registerPushToken(String token, DevicePlatform platform);
}

@lazySingleton
class NotificationsDataSourceRemote implements NotificationsDataSource {
  const NotificationsDataSourceRemote(this._dio);

  final Dio _dio;

  @override
  Future<List<AppNotification>> list({bool unreadOnly = false}) async {
    final res = await _dio.get<Object>(
      ApiEndpoints.notifications,
      queryParameters: {if (unreadOnly) 'unread_only': true},
    );
    return Json.items(res.data).map(NotificationModel.fromJson).toList();
  }

  @override
  Future<void> markRead(String notificationId, {required bool isRead}) =>
      _dio.patch<void>(
        ApiEndpoints.notification(notificationId),
        data: {'is_read': isRead},
      );

  @override
  Future<void> registerPushToken(String token, DevicePlatform platform) =>
      _dio.put<void>(
        ApiEndpoints.pushToken,
        data: {'fcm_token': token, 'platform': platform.apiValue},
      );
}

@lazySingleton
class NotificationsDataSourceMock implements NotificationsDataSource {
  const NotificationsDataSourceMock(this._server);

  final MockApiServer _server;

  @override
  Future<List<AppNotification>> list({bool unreadOnly = false}) async {
    await _server.ready();
    return _server
        .listNotifications(unreadOnly: unreadOnly)
        .map(NotificationModel.fromJson)
        .toList();
  }

  @override
  Future<void> markRead(String notificationId, {required bool isRead}) async {
    await _server.ready();
    _server.markNotification(notificationId, isRead);
  }

  @override
  Future<void> registerPushToken(String token, DevicePlatform platform) async {
    await _server.ready();
    _server.registerPushToken(token, platform.apiValue);
  }
}
