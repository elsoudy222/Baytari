/// Root widget. Wires theme, locale, routing and the three Cubits
/// together. No feature logic lives here.
///
/// How it works:
/// - `BaytariApp` is a [StatefulWidget] (not stateless) because it
///   OWNS three long-lived objects: the app-wide [AuthCubit], the
///   [OnboardingCubit] and the [GoRouter]. All are created once in
///   `initState` and disposed in `dispose` — creating the router in
///   `build` would rebuild it (and reset navigation) on every
///   theme/language change.
/// - [AppCubit] (theme + locale) is provided with `BlocProvider`
///   `create`, as in M0; [AuthCubit] is provided with
///   `BlocProvider.value` because the state object already owns the
///   instance and must close it itself in `dispose`.
/// - `checkSession()` runs once at startup so a returning user is
///   authenticated again from the persisted Supabase session.
/// - `BlocBuilder` rebuilds `MaterialApp.router` whenever the
///   [AppState] changes — that is how a language or theme change
///   instantly redraws the app.
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/app_constants.dart';
import '../core/localization/generated/app_localizations.dart';
import '../core/routing/app_router.dart';
import '../core/services/supabase_service.dart';
import '../core/theme/app_theme.dart';
import '../features/auth/presentation/cubit/auth_cubit.dart';
import '../features/onboarding/presentation/cubit/onboarding_cubit.dart';
import '../injection_container.dart';
import 'app_cubit.dart';
import 'app_state.dart';

class BaytariApp extends StatefulWidget {
  const BaytariApp({super.key});

  @override
  State<BaytariApp> createState() => _BaytariAppState();
}

class _BaytariAppState extends State<BaytariApp> {
  /// The single app-wide auth Cubit. Created from GetIt (factory:
  /// a fresh Cubit per request) and closed here in [dispose].
  late final AuthCubit _authCubit;

  /// The single app-wide onboarding Cubit (seen flag + guest mode).
  /// Created from GetIt and closed here, like [_authCubit].
  late final OnboardingCubit _onboardingCubit;

  /// The router, built once for [_authCubit] and [_onboardingCubit]
  /// so its redirect can read both states and re-run on changes.
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _authCubit = sl<AuthCubit>()..checkSession();
    _onboardingCubit = sl<OnboardingCubit>();
    _router = AppRouter.create(
      authCubit: _authCubit,
      onboardingCubit: _onboardingCubit,
      supabaseConfigured: sl<SupabaseService>().isConfigured,
    );
  }

  @override
  void dispose() {
    _router.dispose();
    _authCubit.close();
    _onboardingCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AuthCubit>.value(
      value: _authCubit,
      child: BlocProvider<OnboardingCubit>.value(
        value: _onboardingCubit,
        child: BlocProvider<AppCubit>(
          create: (_) => sl<AppCubit>()..load(),
          child: BlocBuilder<AppCubit, AppState>(
            builder: (context, state) {
            return MaterialApp.router(
              debugShowCheckedModeBanner: false,
              routerConfig: _router,
              theme: AppTheme.light,
              darkTheme: AppTheme.dark,
              themeMode: state.themeMode,
              locale: state.locale,
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              onGenerateTitle: (context) =>
                  AppLocalizations.of(context)?.appTitle ??
                  AppConstants.appName,
            );
          },
        ),
        ),
      ),
    );
  }
}
