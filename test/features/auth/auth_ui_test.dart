/// Tests for the auth-UI rebuild (feature/auth-ui): the new use
/// cases, the new [AuthCubit] OTP / reset / profile-completion
/// actions, the forgot-password flow navigation, and the sign-up
/// wizard step advance.
///
/// Everything runs against [FakeAuthRepository] — no Supabase, no
/// network. The widget tests pump real screens with a real
/// [AuthCubit] and a real [AppCubit] (demo mode, since Supabase
/// is not configured in tests).
library;

import 'package:baytari/app/app_cubit.dart';
import 'package:baytari/core/errors/failures.dart';
import 'package:baytari/core/errors/result.dart';
import 'package:baytari/core/localization/generated/app_localizations.dart';
import 'package:baytari/core/services/app_settings_service.dart';
import 'package:baytari/core/services/supabase_service.dart';
import 'package:baytari/features/auth/domain/entities/profile.dart';
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
import 'package:baytari/features/auth/domain/usecases/get_current_profile_usecase.dart';
import 'package:baytari/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:baytari/features/auth/presentation/cubit/auth_state.dart';
import 'package:baytari/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:baytari/features/auth/presentation/screens/register_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_auth_repository.dart';

AuthCubit buildFullCubit(FakeAuthRepository repository) {
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
  group('new auth use cases', () {
    late FakeAuthRepository repository;

    setUp(() {
      repository = FakeAuthRepository()
        ..profileToReturn = testProfile
        ..signUpProfile = testProfile;
    });

    test('request signup OTP succeeds and records the call', () async {
      final Result<void> result = await RequestOtpUseCase(repository)(
        email: 'new@example.com',
        purpose: OtpPurpose.signup,
      );
      expect(result.isSuccess, isTrue);
      expect(repository.calls, contains('requestSignupOtp'));
    });

    test('request recovery OTP succeeds and records the call', () async {
      final Result<void> result = await RequestOtpUseCase(repository)(
        email: 'test@example.com',
        purpose: OtpPurpose.recovery,
      );
      expect(result.isSuccess, isTrue);
      expect(repository.calls, contains('requestPasswordReset'));
    });

    test('request OTP failure is returned as a failure', () async {
      repository.failure = const AuthFailure('Email rate limit exceeded');
      final Result<void> result = await RequestOtpUseCase(repository)(
        email: 'test@example.com',
        purpose: OtpPurpose.recovery,
      );
      expect(result.isFailure, isTrue);
      expect(
        result.failureOrNull?.message,
        'Email rate limit exceeded',
      );
    });

    test('verify signup OTP returns the signed-in profile', () async {
      final Result<Profile?> result = await VerifyOtpUseCase(repository)(
        email: 'new@example.com',
        token: '1234',
        purpose: OtpPurpose.signup,
      );
      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull, testProfile);
      expect(repository.calls, contains('verifySignupOtp'));
    });

    test('verify recovery OTP succeeds', () async {
      final Result<Profile?> result = await VerifyOtpUseCase(repository)(
        email: 'test@example.com',
        token: '1234',
        purpose: OtpPurpose.recovery,
      );
      expect(result.isSuccess, isTrue);
      expect(repository.calls, contains('verifyRecoveryOtp'));
    });

    test('reset password succeeds', () async {
      final Result<void> result = await ResetPasswordUseCase(repository)(
        newPassword: 'NewPass123',
      );
      expect(result.isSuccess, isTrue);
      expect(repository.calls, contains('resetPassword'));
    });

    test('update username and avatar returns the updated profile',
        () async {
      final Result<Profile> result =
          await UpdateUsernameAndAvatarUseCase(repository)(
            username: 'testuser',
            avatarUrl: 'https://example.com/avatar.jpg',
          );
      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull?.username, 'testuser');
      expect(
        result.valueOrNull?.avatarUrl,
        'https://example.com/avatar.jpg',
      );
    });

    test('upload license returns a storage path', () async {
      final Result<String> result = await UploadLicenseUseCase(repository)(
        <int>[1, 2, 3],
      );
      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull, contains('licenses/'));
    });

    test('upload avatar returns a public URL', () async {
      final Result<String> result = await UploadAvatarUseCase(repository)(
        <int>[1, 2, 3],
      );
      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull, startsWith('https://'));
    });
  });

  group('AuthCubit OTP / reset actions', () {
    late FakeAuthRepository repository;
    late AuthCubit cubit;

    setUp(() {
      repository = FakeAuthRepository()
        ..profileToReturn = testProfile
        ..signUpProfile = testProfile;
      cubit = buildFullCubit(repository);
    });

    tearDown(() async {
      await cubit.close();
    });

    test('requestPasswordReset emits otpSent', () async {
      await cubit.requestPasswordReset(email: 'test@example.com');
      expect(cubit.state.action, AuthAction.otpSent);
      expect(cubit.state.errorMessage, isNull);
      expect(repository.calls, contains('requestPasswordReset'));
    });

    test('verifyRecoveryOtp emits otpVerified', () async {
      await cubit.verifyRecoveryOtp(
        email: 'test@example.com',
        token: '1234',
      );
      expect(cubit.state.action, AuthAction.otpVerified);
      expect(cubit.state.errorMessage, isNull);
    });

    test('resetPassword emits passwordReset', () async {
      await cubit.resetPassword(newPassword: 'NewPass123');
      expect(cubit.state.action, AuthAction.passwordReset);
      expect(cubit.state.profile, isNull);
    });

    test('verifySignupOtp authenticates and emits otpVerified', () async {
      await cubit.verifySignupOtp(
        email: 'new@example.com',
        token: '1234',
      );
      expect(cubit.state.status, AuthStatus.authenticated);
      expect(cubit.state.action, AuthAction.otpVerified);
      expect(cubit.state.profile, testProfile);
    });

    test('a wrong OTP keeps the error message in state', () async {
      repository.failure = const AuthFailure('Token has expired');
      await cubit.verifyRecoveryOtp(
        email: 'test@example.com',
        token: '0000',
      );
      expect(cubit.state.action, AuthAction.none);
      expect(cubit.state.errorMessage, 'Token has expired');
    });
  });

  group('forgot-password flow widget', () {
    late FakeAuthRepository repository;
    late AuthCubit authCubit;
    late AppCubit appCubit;

    setUp(() async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      repository = FakeAuthRepository()..profileToReturn = testProfile;
      authCubit = buildFullCubit(repository);
      appCubit = AppCubit(AppSettingsService(prefs), SupabaseService());
    });

    tearDown(() async {
      await authCubit.close();
      await appCubit.close();
    });

    Future<void> pumpForgotPassword(WidgetTester tester) async {
      final GoRouter router = GoRouter(
        initialLocation: '/forgot-password',
        routes: <RouteBase>[
          GoRoute(
            path: '/forgot-password',
            builder: (context, state) => const ForgotPasswordScreen(
              step: ForgotPasswordStep.request,
            ),
          ),
          GoRoute(
            path: '/forgot-password/verify',
            builder: (context, state) => ForgotPasswordScreen(
              step: ForgotPasswordStep.verify,
              email: state.extra as String?,
            ),
          ),
          GoRoute(
            path: '/forgot-password/new-password',
            builder: (context, state) => ForgotPasswordScreen(
              step: ForgotPasswordStep.newPassword,
              email: state.extra as String?,
            ),
          ),
          GoRoute(
            path: '/forgot-password/success',
            builder: (context, state) => const ForgotPasswordScreen(
              step: ForgotPasswordStep.success,
            ),
          ),
          GoRoute(
            path: '/login',
            builder: (context, state) => const SizedBox.shrink(),
          ),
        ],
      );
      await tester.pumpWidget(
        MultiBlocProvider(
          providers: <BlocProvider<dynamic>>[
            BlocProvider<AuthCubit>.value(value: authCubit),
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
      await tester.pumpAndSettle();
    }

    testWidgets('sending the OTP navigates to the verify step',
        (WidgetTester tester) async {
      await pumpForgotPassword(tester);

      expect(find.text('إعادة تعيين كلمة المرور'), findsOneWidget);
      await tester.enterText(
        find.widgetWithText(
          TextFormField,
          'البريد الإلكتروني أو رقم الهاتف',
        ),
        'test@example.com',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'إرسال الرمز'));
      await tester.pumpAndSettle();

      expect(repository.calls, contains('requestPasswordReset'));
      expect(find.text('أدخل رمز التحقق'), findsOneWidget);
    });

    testWidgets('a wrong code shows the red wrong-code state',
        (WidgetTester tester) async {
      await pumpForgotPassword(tester);

      // Request the code first (fake succeeds), reaching the verify step.
      await tester.enterText(
        find.widgetWithText(
          TextFormField,
          'البريد الإلكتروني أو رقم الهاتف',
        ),
        'test@example.com',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'إرسال الرمز'));
      await tester.pumpAndSettle();
      expect(find.text('أدخل رمز التحقق'), findsOneWidget);

      // Now every call fails: entering a code and verifying it must
      // show the red "Wrong Code" state from the design.
      repository.failure = const AuthFailure('Token has expired');
      // Six boxes (Supabase OTP length): fill all of them.
      for (int i = 0; i < 6; i++) {
        await tester.enterText(find.byType(TextField).at(i), '0');
        await tester.pump();
      }
      await tester.tap(find.widgetWithText(FilledButton, 'تأكيد الرمز'));
      await tester.pumpAndSettle();

      expect(repository.calls, contains('verifyRecoveryOtp'));
      expect(
        find.text('رمز خاطئ. حاول مرة أخرى أو أعد تعيين الرمز.'),
        findsOneWidget,
      );
    });
  });

  group('sign-up wizard widget', () {
    late FakeAuthRepository repository;
    late AuthCubit authCubit;
    late AppCubit appCubit;

    setUp(() async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      repository = FakeAuthRepository()
        ..profileToReturn = testProfile
        ..signUpProfile = testProfile;
      authCubit = buildFullCubit(repository);
      appCubit = AppCubit(AppSettingsService(prefs), SupabaseService());
    });

    tearDown(() async {
      await authCubit.close();
      await appCubit.close();
    });

    Future<void> pumpRegister(WidgetTester tester) async {
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
            home: const RegisterScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('picking a role advances to the information step',
        (WidgetTester tester) async {
      await pumpRegister(tester);

      // Role step: the three Figma cards.
      expect(find.text('عضو في المجتمع'), findsOneWidget);
      expect(find.text('طبيب بيطري'), findsOneWidget);
      expect(find.text('ملجأ'), findsOneWidget);

      await tester.tap(find.text('عضو في المجتمع'));
      await tester.pumpAndSettle();

      expect(find.text('معلومات الحساب'), findsOneWidget);
      expect(find.text('الاسم الأول'), findsOneWidget);
    });

    testWidgets('valid information advances to the password step',
        (WidgetTester tester) async {
      await pumpRegister(tester);

      await tester.tap(find.text('عضو في المجتمع'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'الاسم الأول'),
        'Ahmed',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'اسم العائلة'),
        'Mohamed',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'البريد الإلكتروني'),
        'new@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'رقم الهاتف'),
        '1001234567',
      );
      final Finder nextButton = find.widgetWithText(FilledButton, 'التالي');
      // The form is taller than the 600px test viewport: scroll the
      // button into view before tapping it.
      await tester.ensureVisible(nextButton);
      await tester.pumpAndSettle();
      await tester.tap(nextButton);
      await tester.pumpAndSettle();

      expect(find.text('عيّن كلمة المرور'), findsOneWidget);
    });

    /// Drives the wizard from the role step to the password step
    /// for [roleLabel], filling the information form on the way.
    Future<void> driveToPasswordStep(
      WidgetTester tester, {
      required String roleLabel,
    }) async {
      await pumpRegister(tester);

      await tester.tap(find.text(roleLabel));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'الاسم الأول'),
        'Ahmed',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'اسم العائلة'),
        'Mohamed',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'البريد الإلكتروني'),
        'new@example.com',
      );
      final Finder nextButton = find.widgetWithText(FilledButton, 'التالي');
      await tester.ensureVisible(nextButton);
      await tester.pumpAndSettle();
      await tester.tap(nextButton);
      await tester.pumpAndSettle();

      expect(find.text('عيّن كلمة المرور'), findsOneWidget);
    }

    /// Fills a strong password, confirms it, and submits — this
    /// creates the account (the fake returns null to simulate
    /// email confirmation ON: no session yet).
    Future<void> submitPassword(WidgetTester tester) async {
      await tester.enterText(
        find.widgetWithText(TextFormField, 'أنشئ كلمة المرور'),
        'Password123',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'تأكيد كلمة المرور'),
        'Password123',
      );
      final Finder nextButton = find.widgetWithText(FilledButton, 'التالي');
      await tester.ensureVisible(nextButton);
      await tester.pumpAndSettle();
      await tester.tap(nextButton);
      await tester.pumpAndSettle();
    }

    testWidgets('vet under Confirm ON goes to the licence step before OTP',
        (WidgetTester tester) async {
      // Confirmation ON: sign-up returns no session.
      repository.signUpProfile = null;

      await driveToPasswordStep(tester, roleLabel: 'طبيب بيطري');
      await submitPassword(tester);

      // Before the fix the wizard jumped straight to the OTP boxes
      // and the licence was never asked for under Confirm ON.
      expect(find.text('تحقق من رخصتك'), findsOneWidget);
      expect(
        find.text(
          'أرسلنا رمز تحقق إلى بريدك الإلكتروني. أدخل الرمز بالأسفل لتأكيد بريدك',
        ),
        findsNothing,
      );
      expect(repository.calls, contains('signUp'));
      // The OTP is requested only from the licence step's Next.
      expect(repository.calls, isNot(contains('requestSignupOtp')));
    });

    testWidgets('community member under Confirm ON goes straight to OTP',
        (WidgetTester tester) async {
      repository.signUpProfile = null;

      await driveToPasswordStep(tester, roleLabel: 'عضو في المجتمع');
      await submitPassword(tester);

      // No licence for community members: the OTP boxes show.
      expect(
        find.text(
          'أرسلنا رمز تحقق إلى بريدك الإلكتروني. أدخل الرمز بالأسفل لتأكيد بريدك',
        ),
        findsOneWidget,
      );
      expect(find.text('تحقق من رخصتك'), findsNothing);
      expect(repository.calls, contains('requestSignupOtp'));
    });
  });
}
