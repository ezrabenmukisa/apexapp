import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../features/evidence/presentation/bloc/evidence_cubits.dart';
import '../../features/notifications/presentation/bloc/inbox_cubit.dart';
import '../../features/projects/presentation/bloc/project_cubits.dart';
import '../router/app_routes.dart';
import 'widgets/bottom_nav_bar.dart';

/// Owner tabs: Projects · Review · Inbox · Account.
class OwnerShell extends StatelessWidget {
  const OwnerShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final reviews = context.select(
      (DashboardCubit c) => c.state.data?.pendingReviews.length ?? 0,
    );
    final unread = context.select(
      (InboxCubit c) => c.state.data?.where((n) => !n.isRead).length ?? 0,
    );
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: BottomNavBar(
        currentIndex: navigationShell.currentIndex,
        onTap: (i) => navigationShell.goBranch(
          i,
          initialLocation: i == navigationShell.currentIndex,
        ),
        items: [
          const NavItem('Projects', Icons.home_outlined),
          NavItem('Review', Icons.fact_check_outlined, count: reviews),
          NavItem('Inbox', Icons.notifications_none, count: unread),
          const NavItem('Account', Icons.person_outline),
        ],
      ),
    );
  }
}

/// Site manager tabs: Today · [capture] · Queue.
class SiteShell extends StatelessWidget {
  const SiteShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final pending = context.select((OutboxCubit c) => c.state.pending.length);
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: SiteBottomBar(
        currentIndex: navigationShell.currentIndex,
        queueCount: pending,
        onTap: (i) => navigationShell.goBranch(
          i,
          initialLocation: i == navigationShell.currentIndex,
        ),
        onCapture: () => openCapture(context),
      ),
    );
  }
}

/// Opens the camera for the site manager's current milestone.
void openCapture(BuildContext context) {
  final site = context.read<SiteCubit>().state;
  final current = site.data?.assignment?.current;
  if (current == null || !current.status.acceptsEvidence) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            current == null
                ? 'There\'s no milestone to capture evidence for yet.'
                : '${current.title} is waiting for review. You can capture again if changes are requested.',
          ),
        ),
      );
    return;
  }
  context.read<EvidenceDraftCubit>().startFor(current.milestoneId);
  context.push(AppRoutes.siteCapture);
}
