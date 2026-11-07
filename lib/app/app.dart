/// Root widget. Wires theme, locale, routing and the [AppCubit] together.
/// No feature logic lives here.
///
/// How it works: `BlocProvider` creates the [AppCubit] from GetIt and
/// calls `load()` once, so the persisted theme/language are read before
/// the first frame. `BlocBuilder` then rebuilds the whole
/// `MaterialApp.router` whenever the [AppState] changes — that is how a
/// language or theme change in Settings instantly redraws the app.
/// `onGenerateTitle` falls back to the constant app name if the
/// localization delegate has not loaded yet (it never shows raw text).
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../core/constants/app_constants.dart';
import '../core/localization/generated/app_localizations.dart';
import '../core/routing/app_router.dart';
import '../core/theme/app_theme.dart';
import '../injection_container.dart';
import 'app_cubit.dart';
import 'app_state.dart';
class BaytariApp extends StatelessWidget {
  const BaytariApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AppCubit>(
      create: (_) => sl<AppCubit>()..load(),
      child: BlocBuilder<AppCubit, AppState>(
        builder: (context, state) {
          return MaterialApp.router(
            debugShowCheckedModeBanner: false,
            routerConfig: AppRouter.router,
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
    );
  }
}
