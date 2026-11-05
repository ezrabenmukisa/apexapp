import 'package:app/features/notifications/data/datasources/notifications_data_source.dart';
import 'package:app/features/notifications/domain/entities/app_notification.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_http.dart';

void main() {
  test('registers the push token with a lowercase platform', () async {
    final http = FakeHttp()
      ..on('PUT', '/api/v1/devices/push-token', 200, {
        'message': 'Push token successfully registered.',
        'fcm_token': 'tok',
      });

    await NotificationsDataSourceRemote(
      http.dio(),
    ).registerPushToken('tok', DevicePlatform.android);

    expect(http.requests.single.data, {
      'fcm_token': 'tok',
      'platform': 'android',
    });
  });

  test('lists unread only with the unread_only filter', () async {
    final http = FakeHttp()
      ..on('GET', '/api/v1/notifications', 200, {
        'items': [
          {
            'notification_id': 'n1',
            'title': 'Walling approved',
            'body': 'Sarah approved Walling.',
            'is_read': false,
            'created_at': '2026-11-05T10:00:00Z',
          },
        ],
      });

    final list = await NotificationsDataSourceRemote(
      http.dio(),
    ).list(unreadOnly: true);

    expect(http.requests.single.uri.queryParameters, {'unread_only': 'true'});
    expect(list.single.title, 'Walling approved');
    expect(list.single.isRead, isFalse);
  });

  test('marks a notification read with PATCH {is_read}', () async {
    final http = FakeHttp()
      ..on('PATCH', '/api/v1/notifications/n1', 200, {
        'notification_id': 'n1',
        'title': 't',
        'body': 'b',
        'is_read': true,
        'created_at': '2026-11-05T10:00:00Z',
      });

    await NotificationsDataSourceRemote(
      http.dio(),
    ).markRead('n1', isRead: true);

    expect(http.requests.single.data, {'is_read': true});
  });
}
