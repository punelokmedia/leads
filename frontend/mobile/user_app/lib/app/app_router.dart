import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:user_app/features/home/presentation/home_screen.dart';
import 'package:user_app/features/leads/presentation/leads_screen.dart';
import 'package:user_app/features/profile/presentation/profile_screen.dart';
import 'package:user_app/features/shell/presentation/main_shell.dart';

abstract final class AppRouter {
  static const String homePath = '/';
  static const String leadsPath = '/leads';
  static const String profilePath = '/profile';

  static final GoRouter router = GoRouter(
    initialLocation: homePath,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (BuildContext context, GoRouterState state,
            StatefulNavigationShell navigationShell) {
          return MainShell(navigationShell: navigationShell);
        },
        branches: <StatefulShellBranch>[
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: homePath,
                builder: (BuildContext context, GoRouterState state) =>
                    const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: leadsPath,
                builder: (BuildContext context, GoRouterState state) =>
                    const LeadsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: profilePath,
                builder: (BuildContext context, GoRouterState state) =>
                    const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
