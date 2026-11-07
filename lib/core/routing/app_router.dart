import 'package:go_router/go_router.dart';

import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';

/// App routes. Feature screens are added here as their features land
/// (M1 auth, M2 pets, ...). Route names are centralized here.
///
/// The router is a single static `GoRouter` so every screen navigates
/// the same way (`context.go(AppRoutes.settings)`) and no screen invents
/// its own path string — a typo in a path would otherwise fail silently
/// at runtime. In M0 there are only two routes; deep links and route
/// guards (e.g. "login first") are added in M1 with auth.
abstract final class AppRoutes {
  static const String home = '/';
  static const String settings = '/settings';
}

abstract final class AppRouter {
  static final GoRouter router = GoRouter(
    routes: <RouteBase>[
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );
}
