/// App routes. Route names are centralized here so screens navigate
/// with `context.go(AppRoutes.login)` and never invent a path string.
///
/// [AppRouter.create] builds a fresh [GoRouter] for one [AuthCubit]
/// and one [OnboardingCubit] instance (created once by `BaytariApp`).
/// It is a factory, not a static router, because the redirect needs
/// to read those Cubits' state — and because a static router would
/// keep listening to a Cubit's stream across tests and app restarts.
/// `supabaseConfigured` is passed in (read from [SupabaseService] by
/// `BaytariApp`) so the router never reaches into GetIt itself.
///
/// FLOW (splash -> onboarding -> get-started -> auth -> home):
/// - `/splash` is the initial route. The splash screen itself
///   decides the next step after ~2 seconds (onboarding if never
///   seen, home if signed in / guest, get-started otherwise).
/// - `/onboarding`, `/get-started`, `/login`, `/register` are public
///   routes: the auth guard never redirects away from them.
/// - Guest mode ([OnboardingCubit.guestMode]) lets an unauthenticated
///   user reach Home without signing in; no guest account is created.
///
/// REDIRECT RULES (the auth guard):
/// - Supabase NOT configured (demo mode, M0 behaviour): no redirect
///   at all — every route is reachable, and auth actions fail with a
///   "not configured" message instead of crashing.
/// - Status `initial` / `loading` (session check still running):
///   no redirect yet — redirecting now would flash the login screen
///   at every app start while the session is being restored.
/// - `unauthenticated` / `awaitingConfirmation`: any route except the
///   public ones redirects to `/login` — unless the user is a guest.
/// - `authenticated`: `/login`, `/register` and `/get-started`
///   redirect to `/` (a signed-in user has no business on those).
///
/// The router re-evaluates the redirect whenever either Cubit's
/// state changes: [_CubitRefresh] forwards each Cubit's stream to
/// GoRouter's `refreshListenable`, merged with [Listenable.merge].
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
import '../../features/onboarding/presentation/cubit/onboarding_cubit.dart';
import '../../features/onboarding/presentation/screens/get_started_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/onboarding/presentation/screens/splash_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';

/// Forwards a Cubit's state stream to GoRouter: every new state
/// calls [notifyListeners], and GoRouter re-runs its redirect
/// function. The subscription is cancelled in [dispose].
class _CubitRefresh extends ChangeNotifier {
  _CubitRefresh(Stream<dynamic> stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

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
  static const String splash = '/splash';
  static const String onboarding = '/onboarding';
  static const String getStarted = '/get-started';
}

abstract final class AppRouter {
  static GoRouter create({
    required AuthCubit authCubit,
    required OnboardingCubit onboardingCubit,
    required bool supabaseConfigured,
  }) {
    return GoRouter(
      initialLocation: AppRoutes.splash,
      // Re-run `redirect` on every auth or onboarding state change.
      refreshListenable: Listenable.merge(<Listenable>[
        _CubitRefresh(authCubit.stream),
        _CubitRefresh(onboardingCubit.stream),
      ]),
      redirect: (context, state) {
        // Demo mode: Supabase not configured — no guard at all.
        if (!supabaseConfigured) {
          return null;
        }
        final String location = state.matchedLocation;
        // Public routes: the guard never redirects away from them.
        final bool isPublic =
            location == AppRoutes.splash ||
            location == AppRoutes.onboarding ||
            location == AppRoutes.getStarted ||
            location == AppRoutes.login ||
            location == AppRoutes.register;
        final bool onAuthRoute =
            location == AppRoutes.login || location == AppRoutes.register;
        return switch (authCubit.state.status) {
          // Session check still running: do not redirect yet.
          AuthStatus.initial || AuthStatus.loading => null,
          AuthStatus.authenticated =>
            onAuthRoute || location == AppRoutes.getStarted
                ? AppRoutes.home
                : null,
          AuthStatus.unauthenticated ||
          AuthStatus.awaitingConfirmation =>
            // Guests may browse Home without signing in.
            onboardingCubit.state.guestMode || isPublic
                ? null
                : AppRoutes.login,
        };
      },
      routes: <RouteBase>[
        GoRoute(
          path: AppRoutes.splash,
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: AppRoutes.onboarding,
          builder: (context, state) => const OnboardingScreen(),
        ),
        GoRoute(
          path: AppRoutes.getStarted,
          builder: (context, state) => const GetStartedScreen(),
        ),
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
