import '../../domain/entities/app_notification.dart';

abstract final class NotificationModel {
  static AppNotification fromJson(Map<String, dynamic> json) => AppNotification(
    notificationId: json['notification_id'] as String,
    title: json['title'] as String? ?? '',
    body: json['body'] as String? ?? '',
    isRead: json['is_read'] as bool? ?? false,
    createdAt: json['created_at'] is String
        ? DateTime.tryParse(json['created_at'] as String)?.toLocal()
        : null,
  );
}
