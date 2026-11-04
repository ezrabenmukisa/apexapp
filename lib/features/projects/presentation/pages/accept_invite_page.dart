import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/router/auth_redirect.dart';
import '../../../../core/router/pending_invite.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../auth/domain/entities/user_role.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../bloc/accept_invite_cubit.dart';

/// Opened from an emailed `https://apex.pntr.dev/invite?token=…` link (the
/// router sends signed-out users through sign-in first). Accepts the invite,
/// then opens the project.
class AcceptInvitePage extends StatelessWidget {
  const AcceptInvitePage({super.key, required this.token});

  final String token;

  @override
  Widget build(BuildContext context) {
    // The token is in hand; stop the router from reopening this page.
    getIt<PendingInvite>().token = null;
    return BlocProvider(
      create: (_) => getIt<AcceptInviteCubit>()..accept(token),
      child: const _AcceptInviteView(),
    );
  }
}

class _AcceptInviteView extends StatelessWidget {
  const _AcceptInviteView();

  void _openProject(BuildContext context, String projectId) {
    final role = context.read<AuthBloc>().state.user?.userRole;
    // Site managers work from Today, which shows their assigned project.
    context.go(
      role == UserRole.manager
          ? AppRoutes.siteToday
          : AppRoutes.project(projectId),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AcceptInviteCubit, AcceptInviteState>(
      listenWhen: (_, s) => s.status == AcceptInviteStatus.accepted,
      listener: (context, s) => _openProject(context, s.projectId!),
      builder: (context, s) => Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: s.status == AcceptInviteStatus.failed
                ? _Failed(message: s.error!)
                : const _Joining(),
          ),
        ),
      ),
    );
  }
}

class _Joining extends StatelessWidget {
  const _Joining();

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const CircularProgressIndicator(),
        const SizedBox(height: 16),
        Text('Joining the project…', style: AppTextStyles.body),
      ],
    ),
  );
}

class _Failed extends StatelessWidget {
  const _Failed({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final role = context.read<AuthBloc>().state.user?.userRole;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text("We couldn't open this invite", style: AppTextStyles.displayL),
        const SizedBox(height: 12),
        Text(message, style: AppTextStyles.body),
        const SizedBox(height: 8),
        Text(
          'Invites work once, for the email address they were sent to. '
          'Ask the project owner to send a new one if it has expired.',
          style: AppTextStyles.caption.copyWith(color: AppColors.ink2),
        ),
        const SizedBox(height: 24),
        PrimaryButton(
          label: 'Go to my projects',
          onPressed: () => context.go(homeFor(role)),
        ),
      ],
    );
  }
}
