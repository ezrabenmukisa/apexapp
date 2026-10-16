import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/account/presentation/pages/edit_profile_page.dart';
import '../../features/account/presentation/pages/owner_account_page.dart';
import '../../features/account/presentation/pages/site_account_page.dart';
import '../../features/account/presentation/pages/site_join_page.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/pages/complete_profile_page.dart';
import '../../features/auth/presentation/pages/email_sign_in_page.dart';
import '../../features/auth/presentation/pages/phone_sign_in_page.dart';
import '../../features/auth/presentation/pages/session_error_page.dart';
import '../../features/auth/presentation/pages/sign_in_options_page.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/auth/presentation/pages/welcome_page.dart';
import '../../features/evidence/presentation/pages/capture_page.dart';
import '../../features/evidence/presentation/pages/queue_page.dart';
import '../../features/evidence/presentation/pages/review_evidence_page.dart';
import '../../features/evidence/presentation/pages/site_today_page.dart';
import '../../features/evidence/presentation/pages/submit_evidence_page.dart';
import '../../features/milestones/presentation/pages/edit_milestone_page.dart';
import '../../features/milestones/presentation/pages/milestone_plan_page.dart';
import '../../features/notifications/presentation/pages/inbox_page.dart';
import '../../features/projects/presentation/pages/add_site_manager_page.dart';
import '../../features/projects/presentation/pages/project_detail_page.dart';
import '../../features/projects/presentation/pages/project_form_page.dart';
import '../../features/projects/presentation/pages/project_settings_page.dart';
import '../../features/projects/presentation/pages/projects_page.dart';
import '../navigation/main_shell.dart';
import 'app_routes.dart';
import 'auth_redirect.dart';

final _rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');

GoRouter createAppRouter(AuthBloc authBloc) => GoRouter(
  navigatorKey: _rootKey,
  initialLocation: AppRoutes.splash,
  refreshListenable: _StreamListenable(authBloc.stream),
  redirect: (context, routerState) =>
      authRedirect(authBloc.state, routerState.matchedLocation),
  routes: [
    GoRoute(path: AppRoutes.splash, builder: (_, _) => const SplashPage()),
    GoRoute(path: AppRoutes.welcome, builder: (_, _) => const WelcomePage()),
    GoRoute(
      path: AppRoutes.signIn,
      builder: (_, _) => const SignInOptionsPage(),
      routes: [
        GoRoute(path: 'phone', builder: (_, _) => const PhoneSignInPage()),
        GoRoute(path: 'email', builder: (_, _) => const EmailSignInPage()),
      ],
    ),
    GoRoute(
      path: AppRoutes.completeProfile,
      builder: (_, _) => const CompleteProfilePage(),
    ),
    GoRoute(
      path: AppRoutes.sessionError,
      builder: (_, _) => const SessionErrorPage(),
    ),
    GoRoute(
      path: AppRoutes.editProfile,
      builder: (_, _) => const EditProfilePage(),
    ),
    ..._ownerRoutes,
    ..._siteRoutes,
  ],
);

String _param(GoRouterState s, String name) => s.pathParameters[name]!;
bool _setup(GoRouterState s) => s.uri.queryParameters['setup'] == '1';

/// Owner: four tabs. Project detail stays inside the Projects tab (it shows
/// the bottom nav); everything else opens full-screen on the root navigator.
final _ownerRoutes = <RouteBase>[
  StatefulShellRoute.indexedStack(
    builder: (_, _, shell) => OwnerShell(navigationShell: shell),
    branches: [
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: AppRoutes.ownerProjects,
            builder: (_, _) => const ProjectsPage(),
            routes: [
              GoRoute(
                path: 'new',
                parentNavigatorKey: _rootKey,
                builder: (_, _) => const ProjectFormPage(),
              ),
              GoRoute(
                path: ':projectId',
                builder: (_, s) =>
                    ProjectDetailPage(projectId: _param(s, 'projectId')),
                routes: [
                  GoRoute(
                    path: 'edit',
                    parentNavigatorKey: _rootKey,
                    builder: (_, s) =>
                        ProjectFormPage(projectId: _param(s, 'projectId')),
                  ),
                  GoRoute(
                    path: 'settings',
                    parentNavigatorKey: _rootKey,
                    builder: (_, s) =>
                        ProjectSettingsPage(projectId: _param(s, 'projectId')),
                  ),
                  GoRoute(
                    path: 'plan',
                    parentNavigatorKey: _rootKey,
                    builder: (_, s) => MilestonePlanPage(
                      projectId: _param(s, 'projectId'),
                      setup: _setup(s),
                    ),
                  ),
                  GoRoute(
                    path: 'team',
                    parentNavigatorKey: _rootKey,
                    builder: (_, s) => AddSiteManagerPage(
                      projectId: _param(s, 'projectId'),
                      setup: _setup(s),
                    ),
                  ),
                  GoRoute(
                    path: 'milestones/new',
                    parentNavigatorKey: _rootKey,
                    builder: (_, s) =>
                        EditMilestonePage(projectId: _param(s, 'projectId')),
                  ),
                  GoRoute(
                    path: 'milestones/:milestoneId',
                    parentNavigatorKey: _rootKey,
                    builder: (_, s) => EditMilestonePage(
                      projectId: _param(s, 'projectId'),
                      milestoneId: _param(s, 'milestoneId'),
                    ),
                  ),
                  GoRoute(
                    path: 'review/:milestoneId',
                    parentNavigatorKey: _rootKey,
                    builder: (_, s) => ReviewEvidencePage(
                      projectId: _param(s, 'projectId'),
                      milestoneId: _param(s, 'milestoneId'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: AppRoutes.ownerReview,
            builder: (_, _) => const ReviewQueuePage(),
          ),
        ],
      ),
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: AppRoutes.ownerInbox,
            builder: (_, _) => const InboxPage(),
          ),
        ],
      ),
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: AppRoutes.ownerAccount,
            builder: (_, _) => const OwnerAccountPage(),
          ),
        ],
      ),
    ],
  ),
];

/// Site manager: Today and Queue tabs, with capture in the middle.
final _siteRoutes = <RouteBase>[
  StatefulShellRoute.indexedStack(
    builder: (_, _, shell) => SiteShell(navigationShell: shell),
    branches: [
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: AppRoutes.siteToday,
            builder: (_, _) => const SiteTodayPage(),
          ),
        ],
      ),
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: AppRoutes.siteQueue,
            builder: (_, _) => const QueuePage(),
          ),
        ],
      ),
    ],
  ),
  GoRoute(path: AppRoutes.siteCapture, builder: (_, _) => const CapturePage()),
  GoRoute(
    path: AppRoutes.siteSubmit,
    builder: (_, _) => const SubmitEvidencePage(),
  ),
  GoRoute(
    path: AppRoutes.siteAccount,
    builder: (_, _) => const SiteAccountPage(),
  ),
  GoRoute(path: AppRoutes.siteJoin, builder: (_, _) => const SiteJoinPage()),
];

/// Re-runs GoRouter redirects whenever the auth state changes.
class _StreamListenable extends ChangeNotifier {
  _StreamListenable(Stream<Object?> stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<Object?> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
