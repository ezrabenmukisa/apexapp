import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/account/presentation/bloc/settings_cubit.dart';
import '../../features/auth/domain/entities/app_user.dart';
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
/// Rebuilt from scratch for every sign-in, so nothing leaks between
/// sessions or accounts.
///
/// On sign-out the router redirects to sign-in, but the outgoing shell is
/// still built while its page animates away, and it reads these cubits. So
/// the ending session's cubits stay mounted for [_linger] before they close.
class SessionScope extends StatefulWidget {
  const SessionScope({super.key, required this.child});

  final Widget child;

  @override
  State<SessionScope> createState() => _SessionScopeState();
}

class _SessionScopeState extends State<SessionScope> {
  static const _linger = Duration(seconds: 2);

  /// The user whose cubits are mounted (the signed-in user, or the one who
  /// just signed out while [_closing] runs).
  AppUser? _user;

  /// Bumped for every new session, so a sign-in gets fresh cubits even when
  /// it is the same account signing back in.
  int _session = 0;
  Timer? _closing;

  static AppUser? _signedIn(AuthState s) =>
      s.status == AuthStatus.authenticated ? s.user : null;

  @override
  void initState() {
    super.initState();
    _user = _signedIn(context.read<AuthBloc>().state);
  }

  void _onAuthChanged(BuildContext context, AuthState state) {
    final user = _signedIn(state);
    if (user == null) {
      if (_user != null && _closing == null) {
        _closing = Timer(_linger, () {
          if (mounted) setState(() => _user = null);
        });
      }
      return;
    }
    final resumed = _user != null && _closing == null;
    final sameAccount =
        _user?.userId == user.userId && _user?.userRole == user.userRole;
    _closing?.cancel();
    _closing = null;
    setState(() {
      // A profile edit keeps the session; a new sign-in or role starts one.
      if (!(resumed && sameAccount)) _session++;
      _user = user;
    });
  }

  @override
  void dispose() {
    _closing?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BlocListener<AuthBloc, AuthState>(
    listenWhen: (a, b) => _signedIn(a) != _signedIn(b),
    listener: _onAuthChanged,
    child: _scoped(_user),
  );

  Widget _scoped(AppUser? user) {
    if (user == null) return widget.child;
    final isManager = user.userRole == UserRole.manager;
    return KeyedSubtree(
      key: ValueKey(_session),
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
        child: _RegisterDevice(child: widget.child),
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
