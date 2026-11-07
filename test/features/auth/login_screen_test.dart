/// Widget test for the login screen.
///
/// Pumps only the [LoginScreen] (not the whole app) with a real
/// [AuthCubit] backed by the fake repository, plus a real
/// [AppCubit] for the demo-mode banner. Proves the form renders
/// in Arabic, empty fields show validation errors, and a valid
/// submit reaches the Cubit (the fake records the `signIn` call).
library;

import 'package:baytari/app/app_cubit.dart';
import 'package:baytari/core/localization/generated/app_localizations.dart';
import 'package:baytari/core/services/app_settings_service.dart';
import 'package:baytari/core/services/supabase_service.dart';
import 'package:baytari/features/auth/domain/usecases/get_current_profile_usecase.dart';
import 'package:baytari/features/auth/domain/usecases/sign_in_usecase.dart';
import 'package:baytari/features/auth/domain/usecases/sign_out_usecase.dart';
import 'package:baytari/features/auth/domain/usecases/sign_up_usecase.dart';
import 'package:baytari/features/auth/domain/usecases/update_profile_usecase.dart';
import 'package:baytari/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:baytari/features/auth/presentation/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_auth_repository.dart';

void main() {
  late FakeAuthRepository repository;
  late AuthCubit authCubit;
  late AppCubit appCubit;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    repository = FakeAuthRepository()..profileToReturn = testProfile;
    authCubit = AuthCubit(
      signUpUseCase: SignUpUseCase(repository),
      signInUseCase: SignInUseCase(repository),
      signOutUseCase: SignOutUseCase(repository),
      getCurrentProfileUseCase: GetCurrentProfileUseCase(repository),
      updateProfileUseCase: UpdateProfileUseCase(repository),
    );
    appCubit = AppCubit(AppSettingsService(prefs), SupabaseService());
  });

  tearDown(() async {
    await authCubit.close();
    await appCubit.close();
  });

  Future<void> pumpLogin(WidgetTester tester) async {
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: <BlocProvider<dynamic>>[
          BlocProvider<AuthCubit>.value(value: authCubit),
          BlocProvider<AppCubit>.value(value: appCubit),
        ],
        child: MaterialApp(
          locale: const Locale('ar'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const LoginScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('login form renders in Arabic with a demo-mode note',
      (WidgetTester tester) async {
    await pumpLogin(tester);

    expect(find.text('تسجيل الدخول'), findsWidgets);
    expect(find.text('البريد الإلكتروني'), findsOneWidget);
    expect(find.text('كلمة المرور'), findsOneWidget);
    // Supabase is not configured in tests: the demo-mode note shows.
    expect(
      find.text(
        'لم يتم إعداد Supabase، لذلك تسجيل الدخول غير متاح في وضع العرض.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('empty submit shows validation errors', (
    WidgetTester tester,
  ) async {
    await pumpLogin(tester);

    await tester.tap(find.widgetWithText(FilledButton, 'تسجيل الدخول'));
    await tester.pump();

    expect(find.text('أدخل بريداً إلكترونياً صحيحاً'), findsOneWidget);
    expect(
      find.text('كلمة المرور يجب أن تكون 6 أحرف على الأقل'),
      findsOneWidget,
    );
    expect(repository.calls, isNot(contains('signIn')));
  });

  testWidgets('valid submit calls signIn on the Cubit', (
    WidgetTester tester,
  ) async {
    await pumpLogin(tester);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'البريد الإلكتروني'),
      'test@example.com',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'كلمة المرور'),
      'password123',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'تسجيل الدخول'));
    await tester.pumpAndSettle();

    expect(repository.calls, contains('signIn'));
  });
}
