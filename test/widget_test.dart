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
