/// Widget tests for the M0 shell: the home screen and the settings screen.
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

  // Proves the defaults end-to-end: Arabic strings on screen
  // (title, welcome), the demo-mode banner (no Supabase keys in
  // tests), and the entry point to Settings. The Arabic strings are
  // asserted literally — if the ARB files or the default locale
  // break, this test fails.
  testWidgets('home shell renders with Arabic default', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const BaytariApp());
    await tester.pumpAndSettle();

    // Arabic default: the app title and welcome text in Arabic.
    expect(find.text('بيطري'), findsWidgets);
    expect(find.text('أهلاً بك في بيطري'), findsOneWidget);
    // Supabase is not configured in tests — the demo-mode banner shows.
    expect(find.text('لم يتم إعداد Supabase بعد. التطبيق يعمل في وضع العرض.'),
        findsOneWidget);
    // Settings entry point is present.
    expect(find.text('الإعدادات'), findsOneWidget);
  });

  // Proves navigation works: tapping the Settings button opens the
  // settings screen, which must show both the language and the theme
  // controls (Arabic label, light/dark options).
  testWidgets('settings screen opens and shows language and theme',
      (WidgetTester tester) async {
    await tester.pumpWidget(const BaytariApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('الإعدادات'));
    await tester.pumpAndSettle();

    expect(find.text('اللغة'), findsOneWidget);
    expect(find.text('المظهر'), findsOneWidget);
    expect(find.text('العربية'), findsOneWidget);
    expect(find.text('فاتح'), findsOneWidget);
    expect(find.text('داكن'), findsOneWidget);
  });
}
