/// Widget tests for the app shell: splash -> onboarding -> home.
///
/// Unlike the unit tests in `app_cubit_test.dart`, these tests build
/// the real [BaytariApp] widget tree (`pumpWidget`) and interact with
/// it like a user (`tap`, `pumpAndSettle`). `setUp` registers the
/// dependencies in GetIt first — without it, `BaytariApp` would fail
/// to find its [AppCubit]. `tearDown` calls `sl.reset()` so the
/// singleton registrations do not leak from one test into the next
/// (GetIt keeps its registrations for the whole test run otherwise).
library;

import 'package:baytari/app/app.dart';
import 'package:baytari/injection_container.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await configureDependencies(prefs);
  });

  tearDown(() async {
    await sl.reset();
  });

  // Proves the first-run flow end-to-end: the splash screen shows,
  // then (after its ~2s timer) the user lands on onboarding in
  // Arabic (the default locale), with the Figma titles and Skip.
  testWidgets('first run shows splash then onboarding', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const BaytariApp());
    // pumpAndSettle alone does not advance the splash Timer, so
    // advance fake time explicitly, then settle the navigation.
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    expect(find.text('مساعدة الحيوانات الضالة'), findsOneWidget);
    expect(find.text('تخطي'), findsOneWidget);
    expect(find.text('ابدأ'), findsOneWidget);
  });

  // Proves the guest flow: Skip onboarding -> Get Started ->
  // "Join as a guest" -> home (demo mode, no Supabase), where the
  // settings screen opens and shows both language and theme.
  testWidgets('guest flow reaches home and settings', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const BaytariApp());
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    await tester.tap(find.text('تخطي'));
    await tester.pumpAndSettle();
    expect(find.text('المتابعة كضيف'), findsOneWidget);

    await tester.tap(find.text('المتابعة كضيف'));
    await tester.pumpAndSettle();
    expect(find.text('أهلاً بك في بيطري'), findsOneWidget);

    await tester.tap(find.text('الإعدادات'));
    await tester.pumpAndSettle();

    expect(find.text('اللغة'), findsOneWidget);
    expect(find.text('المظهر'), findsOneWidget);
    expect(find.text('العربية'), findsOneWidget);
    expect(find.text('فاتح'), findsOneWidget);
    expect(find.text('داكن'), findsOneWidget);
  });
}
