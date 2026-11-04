import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/app_notification.dart';
import '../repositories/notifications_repository.dart';

@injectable
class ListNotifications implements UseCase<List<AppNotification>, NoParams> {
  const ListNotifications(this._repository);

  final NotificationsRepository _repository;

  @override
  Future<Either<Failure, List<AppNotification>>> call(NoParams params) =>
      _repository.list();
}

@injectable
class MarkNotificationRead implements UseCase<Unit, String> {
  const MarkNotificationRead(this._repository);

  final NotificationsRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(String notificationId) =>
      _repository.markRead(notificationId);
}

/// `PUT /devices/push-token` on app start-up.
@injectable
class RegisterPushToken implements UseCase<Unit, NoParams> {
  const RegisterPushToken(this._repository);

  final NotificationsRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(NoParams params) =>
      _repository.registerThisDevice();
}
