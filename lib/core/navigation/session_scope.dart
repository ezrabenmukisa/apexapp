import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/account/presentation/bloc/settings_cubit.dart';
import '../../features/auth/domain/entities/user_role.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/evidence/presentation/bloc/evidence_cubits.dart';
import '../../features/notifications/domain/usecases/notification_usecases.dart';
import '../../features/notifications/presentation/bloc/inbox_cubit.dart';
import '../../features/projects/presentation/bloc/project_cubits.dart';
import '../di/injection.dart';
import '../usecase/usecase.dart';

/// Cubits that live for the whole signed-in session and are shared across
/// tabs and full-screen pages (badges, the evidence draft, the outbox).
/// Rebuilt from scratch when the user changes, so nothing leaks between
/// accounts.
class SessionScope extends StatelessWidget {
  const SessionScope({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final user = context.select((AuthBloc b) => b.state.user);
    if (user == null) return child;
    final isManager = user.userRole == UserRole.manager;
    return KeyedSubtree(
      key: ValueKey('${user.userId}/${user.userRole}'),
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => getIt<SettingsCubit>()),
          BlocProvider(create: (_) => getIt<InboxCubit>()..load()),
          if (isManager) ...[
            BlocProvider(create: (_) => getIt<SiteCubit>()..load()),
            BlocProvider(create: (_) => getIt<OutboxCubit>()..start()),
            BlocProvider(create: (_) => getIt<EvidenceDraftCubit>()),
          ] else
            BlocProvider(create: (_) => getIt<DashboardCubit>()..load()),
        ],
        child: _RegisterDevice(child: child),
      ),
    );
  }
}

/// `PUT /devices/push-token` once per session start.
class _RegisterDevice extends StatefulWidget {
  const _RegisterDevice({required this.child});

  final Widget child;

  @override
  State<_RegisterDevice> createState() => _RegisterDeviceState();
}

class _RegisterDeviceState extends State<_RegisterDevice> {
  @override
  void initState() {
    super.initState();
    getIt<RegisterPushToken>()(const NoParams());
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
