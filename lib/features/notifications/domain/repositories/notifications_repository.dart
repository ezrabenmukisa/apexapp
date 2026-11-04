import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/app_notification.dart';

abstract interface class NotificationsRepository {
  /// Newest first.
  Future<Either<Failure, List<AppNotification>>> list({
    bool unreadOnly = false,
  });

  /// Called when a notification is opened.
  Future<Either<Failure, Unit>> markRead(String notificationId);

  /// Links this phone's FCM token to the signed-in user (on start-up).
  Future<Either<Failure, Unit>> registerThisDevice();
}
