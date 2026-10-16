import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/bloc/load_cubit.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/sync/data_changes.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/usecases/notification_usecases.dart';

/// Inbox list, held in memory; opening one marks it read without another
/// fetch (the body is already here).
@injectable
class InboxCubit extends LoadCubit<List<AppNotification>> {
  InboxCubit(this._list, this._markRead, DataChanges changes)
    : super(changes, {DataTopic.notifications});

  final ListNotifications _list;
  final MarkNotificationRead _markRead;

  int get unreadCount => state.data?.where((n) => !n.isRead).length ?? 0;

  @override
  Future<Either<Failure, List<AppNotification>>> fetch() =>
      _list(const NoParams());

  Future<void> open(AppNotification n) async {
    if (n.isRead) return;
    // Optimistic: update the in-memory list immediately.
    final items = state.data;
    if (items != null) {
      emit(
        state.copyWith(
          data: [
            for (final i in items)
              i.notificationId == n.notificationId
                  ? i.copyWith(isRead: true)
                  : i,
          ],
        ),
      );
    }
    await _markRead(n.notificationId);
  }
}
