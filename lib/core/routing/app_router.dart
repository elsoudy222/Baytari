/// App routes. Route names are centralized here so screens navigate
/// with `context.go(AppRoutes.login)` and never invent a path string.
///
/// [AppRouter.create] builds a fresh [GoRouter] for one [AuthCubit]
/// instance (created once by `BaytariApp`). It is a factory, not a
/// static router, because the redirect needs to read that Cubit's
/// state — and because a static router would keep listening to a
/// Cubit's stream across tests and app restarts. `supabaseConfigured`
/// is passed in (read from [SupabaseService] by `BaytariApp`) so the
/// router never reaches into GetIt itself.
///
/// REDIRECT RULES (the auth guard):
/// - Supabase NOT configured (demo mode, M0 behaviour): no redirect
///   at all — every route is reachable, and auth actions fail with a
///   "not configured" message instead of crashing.
/// - Status `initial` / `loading` (session check still running):
///   no redirect yet — redirecting now would flash the login screen
///   at every app start while the session is being restored.
/// - `unauthenticated` / `awaitingConfirmation`: any route except
///   `/login` and `/register` redirects to `/login`.
/// - `authenticated`: `/login` and `/register` redirect to `/`
///   (a signed-in user has no business on the login screen).
///
/// The router re-evaluates the redirect whenever the Cubit's state
/// changes: [_CubitRefresh] is a [ChangeNotifier] that forwards the
/// Cubit's stream to GoRouter's `refreshListenable`. That is how a
/// sign-in immediately sends the user home without any screen
/// calling `context.go('/')` itself (screens still may, after a
/// successful action, but the redirect is the safety net).
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../features/auth/presentation/cubit/auth_state.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/profile_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';

/// Forwards a Cubit's state stream to GoRouter: every new
/// [AuthState] calls [notifyListeners], and GoRouter re-runs its
/// redirect function. The subscription is cancelled in [dispose].
class _CubitRefresh extends ChangeNotifier {
  _CubitRefresh(Stream<AuthState> stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<AuthState> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

abstract final class AppRoutes {
  static const String home = '/';
  static const String settings = '/settings';
  static const String login = '/login';
  static const String register = '/register';
  static const String profile = '/profile';
}

abstract final class AppRouter {
  static GoRouter create({
    required AuthCubit authCubit,
    required bool supabaseConfigured,
  }) {
    return GoRouter(
      // Re-run `redirect` on every auth state change.
      refreshListenable: _CubitRefresh(authCubit.stream),
      redirect: (context, state) {
        // Demo mode: Supabase not configured — no guard at all.
        if (!supabaseConfigured) {
          return null;
        }
        final String location = state.matchedLocation;
        final bool onAuthRoute =
            location == AppRoutes.login || location == AppRoutes.register;
        return switch (authCubit.state.status) {
          // Session check still running: do not redirect yet.
          AuthStatus.initial || AuthStatus.loading => null,
          AuthStatus.authenticated =>
            onAuthRoute ? AppRoutes.home : null,
          AuthStatus.unauthenticated ||
          AuthStatus.awaitingConfirmation => onAuthRoute ? null : AppRoutes.login,
        };
      },
      routes: <RouteBase>[
        GoRoute(
          path: AppRoutes.home,
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: AppRoutes.settings,
          builder: (context, state) => const SettingsScreen(),
        ),
        GoRoute(
          path: AppRoutes.login,
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: AppRoutes.register,
          builder: (context, state) => const RegisterScreen(),
        ),
        GoRoute(
          path: AppRoutes.profile,
          builder: (context, state) => const ProfileScreen(),
        ),
      ],
    );
  }
}
