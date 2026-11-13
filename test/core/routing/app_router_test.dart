/// Widget tests for the router guard ([AppRouter.create]).
///
/// The sign-up wizard lives on `/register` and emits
/// `authenticated` mid-flow, so the guard must NOT redirect an
/// authenticated user away from `/register` until the wizard
/// itself marks the profile complete (B1). A signed-in user whose
/// profile IS complete must still be sent from the auth routes to
/// Home.
///
/// The tests drive a real [AuthCubit] (fake repository) to the
/// wanted state, pump the real router, then navigate with
/// `router.go(...)` and assert which screen is showing — no
/// Supabase, no network.
library;

import 'package:baytari/app/app_cubit.dart';
import 'package:baytari/core/localization/generated/app_localizations.dart';
import 'package:baytari/core/routing/app_router.dart';
import 'package:baytari/core/services/app_settings_service.dart';
import 'package:baytari/core/services/supabase_service.dart';
import 'package:baytari/features/auth/domain/usecases/get_current_profile_usecase.dart';
import 'package:baytari/features/auth/domain/usecases/request_otp_usecase.dart';
import 'package:baytari/features/auth/domain/usecases/reset_password_usecase.dart';
import 'package:baytari/features/auth/domain/usecases/sign_in_usecase.dart';
import 'package:baytari/features/auth/domain/usecases/sign_out_usecase.dart';
import 'package:baytari/features/auth/domain/usecases/sign_up_usecase.dart';
import 'package:baytari/features/auth/domain/usecases/update_profile_usecase.dart';
import 'package:baytari/features/auth/domain/usecases/update_username_and_avatar_usecase.dart';
import 'package:baytari/features/auth/domain/usecases/upload_avatar_usecase.dart';
import 'package:baytari/features/auth/domain/usecases/upload_license_usecase.dart';
import 'package:baytari/features/auth/domain/usecases/verify_otp_usecase.dart';
import 'package:baytari/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:baytari/features/auth/presentation/cubit/auth_state.dart';
import 'package:baytari/features/auth/presentation/screens/login_screen.dart';
import 'package:baytari/features/auth/presentation/screens/register_screen.dart';
import 'package:baytari/features/home/presentation/screens/home_screen.dart';
import 'package:baytari/features/onboarding/presentation/cubit/onboarding_cubit.dart';
import 'package:baytari/features/onboarding/presentation/screens/get_started_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/auth/fake_auth_repository.dart';

AuthCubit _buildCubit(FakeAuthRepository repository) {
  return AuthCubit(
    signUpUseCase: SignUpUseCase(repository),
    signInUseCase: SignInUseCase(repository),
    signOutUseCase: SignOutUseCase(repository),
    getCurrentProfileUseCase: GetCurrentProfileUseCase(repository),
    updateProfileUseCase: UpdateProfileUseCase(repository),
    requestOtpUseCase: RequestOtpUseCase(repository),
    verifyOtpUseCase: VerifyOtpUseCase(repository),
    resetPasswordUseCase: ResetPasswordUseCase(repository),
    updateUsernameAndAvatarUseCase: UpdateUsernameAndAvatarUseCase(
      repository,
    ),
    uploadLicenseUseCase: UploadLicenseUseCase(repository),
    uploadAvatarUseCase: UploadAvatarUseCase(repository),
  );
}

void main() {
  late FakeAuthRepository repository;
  late AuthCubit authCubit;
  late OnboardingCubit onboardingCubit;
  late AppCubit appCubit;
  late GoRouter router;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final AppSettingsService settings = AppSettingsService(prefs);
    repository = FakeAuthRepository()
      ..profileToReturn = testProfile
      ..signUpProfile = testProfile;
    authCubit = _buildCubit(repository);
    onboardingCubit = OnboardingCubit(settings);
    appCubit = AppCubit(settings, SupabaseService());
    router = AppRouter.create(
      authCubit: authCubit,
      onboardingCubit: onboardingCubit,
      // The guard is active in these tests (configured Supabase);
      // demo mode (unconfigured) disables the guard entirely.
      supabaseConfigured: true,
    );
  });

  tearDown(() async {
    router.dispose();
    await authCubit.close();
    await onboardingCubit.close();
    await appCubit.close();
  });

  Future<void> pumpRouter(WidgetTester tester) async {
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: <BlocProvider<dynamic>>[
          BlocProvider<AuthCubit>.value(value: authCubit),
          BlocProvider<OnboardingCubit>.value(value: onboardingCubit),
          BlocProvider<AppCubit>.value(value: appCubit),
        ],
        child: MaterialApp.router(
          locale: const Locale('ar'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          routerConfig: router,
        ),
      ),
    );
    // Let the splash screen's ~2s timer run out, then settle.
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  }

  testWidgets('authenticated with incomplete profile stays on /register',
      (WidgetTester tester) async {
    // Sign-up with an immediate session (confirmation OFF): the
    // wizard just started, username not picked yet.
    await authCubit.signUp(
      email: 'new@example.com',
      password: 'password123',
      fullName: 'New User',
      role: testProfile.role,
    );
    expect(authCubit.state.profileCompleted, isFalse);

    await pumpRouter(tester);
    router.go(AppRoutes.register);
    await tester.pumpAndSettle();

    // Before the fix the guard sent the user to Home here,
    // skipping the licence / username / confirmation steps.
    expect(find.byType(RegisterScreen), findsOneWidget);
    expect(find.byType(HomeScreen), findsNothing);
  });

  testWidgets('markProfileCompleted redirects /register to home',
      (WidgetTester tester) async {
    await authCubit.signUp(
      email: 'new@example.com',
      password: 'password123',
      fullName: 'New User',
      role: testProfile.role,
    );
    await pumpRouter(tester);
    router.go(AppRoutes.register);
    await tester.pumpAndSettle();
    expect(find.byType(RegisterScreen), findsOneWidget);

    // The wizard calls this when the user leaves the confirmation
    // step ("Go to Home") — only now may the guard redirect.
    authCubit.markProfileCompleted();
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(RegisterScreen), findsNothing);
  });

  testWidgets('authenticated with complete profile leaves /login',
      (WidgetTester tester) async {
    repository.profileToReturn = testProfile.copyWith(
      username: 'testuser',
    );
    await authCubit.signIn(
      email: 'test@example.com',
      password: 'password123',
    );
    expect(authCubit.state.profileCompleted, isTrue);

    await pumpRouter(tester);
    router.go(AppRoutes.login);
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(LoginScreen), findsNothing);
  });

  testWidgets('authenticated with complete profile leaves /get-started',
      (WidgetTester tester) async {
    repository.profileToReturn = testProfile.copyWith(
      username: 'testuser',
    );
    await authCubit.signIn(
      email: 'test@example.com',
      password: 'password123',
    );
    expect(authCubit.state.profileCompleted, isTrue);

    await pumpRouter(tester);
    router.go(AppRoutes.getStarted);
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(GetStartedScreen), findsNothing);
  });

  testWidgets('unauthenticated user can stay on /register',
      (WidgetTester tester) async {
    repository.profileToReturn = null;
    await authCubit.checkSession();
    expect(authCubit.state.status, AuthStatus.unauthenticated);

    await pumpRouter(tester);
    router.go(AppRoutes.register);
    await tester.pumpAndSettle();

    expect(find.byType(RegisterScreen), findsOneWidget);
  });
}
