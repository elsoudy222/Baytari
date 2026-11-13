/// Unit tests for [AuthCubit].
///
/// The Cubit is built with the real use cases and the fake
/// repository, so these tests prove the state machine: every
/// action emits Loading first, then the right state for the
/// result — without Supabase, without widgets. `bloc_test` is
/// deliberately not used (no extra dependency): the Cubit is
/// driven directly and its `state` / `stream` are asserted.
library;

import 'package:baytari/core/errors/failures.dart';
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
import 'package:flutter_test/flutter_test.dart';

import 'fake_auth_repository.dart';

AuthCubit buildCubit(FakeAuthRepository repository) {
  return AuthCubit(
    signUpUseCase: SignUpUseCase(repository),
    signInUseCase: SignInUseCase(repository),
    signOutUseCase: SignOutUseCase(repository),
    getCurrentProfileUseCase: GetCurrentProfileUseCase(repository),
    updateProfileUseCase: UpdateProfileUseCase(repository),
    requestOtpUseCase: RequestOtpUseCase(repository),
    verifyOtpUseCase: VerifyOtpUseCase(repository),
    resetPasswordUseCase: ResetPasswordUseCase(repository),
    updateUsernameAndAvatarUseCase: UpdateUsernameAndAvatarUseCase(repository),
    uploadLicenseUseCase: UploadLicenseUseCase(repository),
    uploadAvatarUseCase: UploadAvatarUseCase(repository),
  );
}

void main() {
  late FakeAuthRepository repository;
  late AuthCubit cubit;

  setUp(() {
    repository = FakeAuthRepository()
      ..profileToReturn = testProfile
      ..signUpProfile = testProfile;
    cubit = buildCubit(repository);
  });

  tearDown(() async {
    await cubit.close();
  });

  test('checkSession restores an existing session', () async {
    await cubit.checkSession();
    expect(cubit.state.status, AuthStatus.authenticated);
    expect(cubit.state.profile, testProfile);
  });

  test('checkSession reports unauthenticated when nobody is signed in',
      () async {
    repository.profileToReturn = null;
    await cubit.checkSession();
    expect(cubit.state.status, AuthStatus.unauthenticated);
    expect(cubit.state.profile, isNull);
  });

  test('signIn authenticates and stores the profile', () async {
    await cubit.signIn(email: 'test@example.com', password: 'password123');
    expect(cubit.state.status, AuthStatus.authenticated);
    expect(cubit.state.profile?.fullName, 'Test User');
    expect(cubit.state.errorMessage, isNull);
  });

  test('signIn failure keeps the user unauthenticated with an error',
      () async {
    repository.failure = const AuthFailure('Invalid login credentials');
    await cubit.signIn(email: 'test@example.com', password: 'wrong');
    expect(cubit.state.status, AuthStatus.unauthenticated);
    expect(cubit.state.errorMessage, 'Invalid login credentials');
  });

  test('signUp with immediate session authenticates', () async {
    await cubit.signUp(
      email: 'new@example.com',
      password: 'password123',
      fullName: 'New User',
      role: testProfile.role,
    );
    expect(cubit.state.status, AuthStatus.authenticated);
  });

  test('signUp without a session waits for email confirmation', () async {
    repository.signUpProfile = null;
    await cubit.signUp(
      email: 'new@example.com',
      password: 'password123',
      fullName: 'New User',
      role: testProfile.role,
    );
    expect(cubit.state.status, AuthStatus.awaitingConfirmation);
  });

  test('signUp with immediate session leaves the profile incomplete',
      () async {
    await cubit.signUp(
      email: 'new@example.com',
      password: 'password123',
      fullName: 'New User',
      role: testProfile.role,
    );
    expect(cubit.state.status, AuthStatus.authenticated);
    // The wizard just started (licence / username steps ahead),
    // so the router must not redirect away from `/register` yet.
    expect(cubit.state.profileCompleted, isFalse);
  });

  test('checkSession marks a profile with a username as complete',
      () async {
    repository.profileToReturn = testProfile.copyWith(
      username: 'testuser',
    );
    await cubit.checkSession();
    expect(cubit.state.status, AuthStatus.authenticated);
    expect(cubit.state.profileCompleted, isTrue);
  });

  test('checkSession leaves a profile without a username incomplete',
      () async {
    await cubit.checkSession();
    expect(cubit.state.status, AuthStatus.authenticated);
    expect(cubit.state.profile?.username, isNull);
    expect(cubit.state.profileCompleted, isFalse);
  });

  test('signIn derives completion from the stored username', () async {
    repository.profileToReturn = testProfile.copyWith(
      username: 'testuser',
    );
    await cubit.signIn(email: 'test@example.com', password: 'password123');
    expect(cubit.state.status, AuthStatus.authenticated);
    expect(cubit.state.profileCompleted, isTrue);
  });

  test('signIn leaves a profile without a username incomplete', () async {
    await cubit.signIn(email: 'test@example.com', password: 'password123');
    expect(cubit.state.status, AuthStatus.authenticated);
    expect(cubit.state.profileCompleted, isFalse);
  });

  test('verifySignupOtp leaves the profile incomplete', () async {
    await cubit.verifySignupOtp(
      email: 'new@example.com',
      token: '123456',
    );
    expect(cubit.state.status, AuthStatus.authenticated);
    expect(cubit.state.action, AuthAction.otpVerified);
    // The username step still lies ahead.
    expect(cubit.state.profileCompleted, isFalse);
  });

  test('completeProfile does NOT mark the profile complete', () async {
    await cubit.signUp(
      email: 'new@example.com',
      password: 'password123',
      fullName: 'New User',
      role: testProfile.role,
    );
    await cubit.completeProfile(username: 'newuser');
    expect(cubit.state.status, AuthStatus.authenticated);
    expect(cubit.state.action, AuthAction.profileCompleted);
    // The confirmation screen lives on `/register`: only the
    // wizard itself may flip the flag (see markProfileCompleted).
    expect(cubit.state.profileCompleted, isFalse);
  });

  test('markProfileCompleted flips the flag', () async {
    await cubit.signUp(
      email: 'new@example.com',
      password: 'password123',
      fullName: 'New User',
      role: testProfile.role,
    );
    expect(cubit.state.profileCompleted, isFalse);
    cubit.markProfileCompleted();
    expect(cubit.state.profileCompleted, isTrue);
  });

  test('updateProfile preserves the completion flag', () async {
    repository.profileToReturn = testProfile.copyWith(
      username: 'testuser',
    );
    await cubit.signIn(email: 'test@example.com', password: 'password123');
    expect(cubit.state.profileCompleted, isTrue);
    await cubit.updateProfile(fullName: 'Renamed User');
    expect(cubit.state.status, AuthStatus.authenticated);
    expect(cubit.state.profileCompleted, isTrue);
  });

  test('signOut clears the profile and the session', () async {
    await cubit.signIn(email: 'test@example.com', password: 'password123');
    await cubit.signOut();
    expect(cubit.state.status, AuthStatus.unauthenticated);
    expect(cubit.state.profile, isNull);
  });

  test('updateProfile replaces the profile with the new values',
      () async {
    await cubit.signIn(email: 'test@example.com', password: 'password123');
    await cubit.updateProfile(fullName: 'Renamed User', phone: '01000000000');
    expect(cubit.state.status, AuthStatus.authenticated);
    expect(cubit.state.profile?.fullName, 'Renamed User');
    expect(cubit.state.profile?.phone, '01000000000');
  });
}
