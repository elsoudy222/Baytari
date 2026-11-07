/// Widget tests for the onboarding flow.
///
/// Pumps the real screens inside a small test [GoRouter] (the
/// screens navigate with `context.go`, so a plain `MaterialApp`
/// would throw). Proves: Get Started advances pages, Skip finishes
/// onboarding (persists "seen") and lands on Get Started, and the
/// splash screen routes to onboarding after its delay on first run.
library;

import 'package:baytari/app/app.dart';
import 'package:baytari/core/localization/generated/app_localizations.dart';
import 'package:baytari/core/services/app_settings_service.dart';
import 'package:baytari/features/onboarding/presentation/cubit/onboarding_cubit.dart';
import 'package:baytari/features/onboarding/presentation/screens/get_started_screen.dart';
import 'package:baytari/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:baytari/features/onboarding/presentation/screens/splash_screen.dart';
import 'package:baytari/injection_container.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<OnboardingCubit> _makeCubit() async {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  return OnboardingCubit(AppSettingsService(prefs));
}

Widget _pumpOnboarding(OnboardingCubit cubit) {
  final GoRouter router = GoRouter(
    initialLocation: '/onboarding',
    routes: <RouteBase>[
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/get-started',
        builder: (context, state) => const GetStartedScreen(),
      ),
    ],
  );
  return BlocProvider<OnboardingCubit>.value(
    value: cubit,
    child: MaterialApp.router(
      routerConfig: router,
      locale: const Locale('ar'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    ),
  );
}

void main() {
  testWidgets('Get Started advances to page 2', (WidgetTester tester) async {
    final OnboardingCubit cubit = await _makeCubit();
    addTearDown(() async => cubit.close());

    await tester.pumpWidget(_pumpOnboarding(cubit));
    await tester.pumpAndSettle();

    expect(find.text('مساعدة الحيوانات الضالة'), findsOneWidget);
    await tester.tap(find.text('ابدأ'));
    await tester.pumpAndSettle();
    expect(find.text('عيادات بيطرية'), findsOneWidget);
  });

  testWidgets('Skip finishes onboarding and opens Get Started',
      (WidgetTester tester) async {
    final OnboardingCubit cubit = await _makeCubit();
    addTearDown(() async => cubit.close());

    await tester.pumpWidget(_pumpOnboarding(cubit));
    await tester.pumpAndSettle();

    await tester.tap(find.text('تخطي'));
    await tester.pumpAndSettle();

    expect(cubit.state.seen, isTrue);
    expect(find.text('المتابعة كضيف'), findsOneWidget);
  });

  testWidgets('splash routes to onboarding on first run',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await configureDependencies(prefs);
    addTearDown(() async => sl.reset());

    await tester.pumpWidget(const BaytariApp());
    // Splash shows the logo while the timer runs.
    expect(find.byType(SplashScreen), findsOneWidget);
    // pumpAndSettle alone does not advance the splash Timer, so
    // advance fake time explicitly, then settle the navigation.
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    // After ~2s the first-run user lands on onboarding.
    expect(find.text('مساعدة الحيوانات الضالة'), findsOneWidget);
  });
}
