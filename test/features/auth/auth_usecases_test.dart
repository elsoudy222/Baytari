/// Unit tests for the auth use cases.
///
/// Use cases are thin (one repository call each), so these tests
/// prove the wiring, not logic: a success from the repository
/// reaches the caller as a [Success], and a failure reaches it as
/// a [FailureResult] with the same [Failure]. The repository here
/// is the fake in `fake_auth_repository.dart` — no Supabase, no
/// network, no widgets.
library;

import 'package:baytari/core/errors/failures.dart';
import 'package:baytari/core/errors/result.dart';
import 'package:baytari/features/auth/domain/entities/profile.dart';
import 'package:baytari/features/auth/domain/entities/user_role.dart';
import 'package:baytari/features/auth/domain/usecases/get_current_profile_usecase.dart';
import 'package:baytari/features/auth/domain/usecases/sign_in_usecase.dart';
import 'package:baytari/features/auth/domain/usecases/sign_out_usecase.dart';
import 'package:baytari/features/auth/domain/usecases/sign_up_usecase.dart';
import 'package:baytari/features/auth/domain/usecases/update_profile_usecase.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_auth_repository.dart';

void main() {
  late FakeAuthRepository repository;

  setUp(() {
    repository = FakeAuthRepository()
      ..profileToReturn = testProfile
      ..signUpProfile = testProfile;
  });

  test('signIn returns the profile on success', () async {
    final Result<Profile> result = await SignInUseCase(repository)(
      email: 'test@example.com',
      password: 'password123',
    );

    expect(result.isSuccess, isTrue);
    expect(result.valueOrNull, testProfile);
    expect(repository.calls, contains('signIn'));
  });

  test('signIn returns the failure when the repository fails', () async {
    repository.failure = const AuthFailure('Invalid login credentials');

    final Result<Profile> result = await SignInUseCase(repository)(
      email: 'test@example.com',
      password: 'wrong',
    );

    expect(result.isFailure, isTrue);
    expect(result.failureOrNull, isA<AuthFailure>());
    expect(result.failureOrNull?.message, 'Invalid login credentials');
  });

  test('signUp returns the profile when the session starts at once',
      () async {
    final Result<Profile?> result = await SignUpUseCase(repository)(
      email: 'new@example.com',
      password: 'password123',
      fullName: 'New User',
      role: UserRole.vet,
    );

    expect(result.isSuccess, isTrue);
    expect(result.valueOrNull, testProfile);
  });

  test('signUp returns null when email confirmation is required',
      () async {
    repository.signUpProfile = null;

    final Result<Profile?> result = await SignUpUseCase(repository)(
      email: 'new@example.com',
      password: 'password123',
      fullName: 'New User',
      role: UserRole.owner,
    );

    expect(result.isSuccess, isTrue);
    expect(result.valueOrNull, isNull);
  });

  test('signOut succeeds', () async {
    final Result<void> result = await SignOutUseCase(repository)();
    expect(result.isSuccess, isTrue);
  });

  test('getCurrentProfile returns null when nobody is signed in',
      () async {
    repository.profileToReturn = null;

    final Result<Profile?> result =
        await GetCurrentProfileUseCase(repository)();

    expect(result.isSuccess, isTrue);
    expect(result.valueOrNull, isNull);
  });

  test('updateProfile returns the profile with the new name', () async {
    final Result<Profile> result = await UpdateProfileUseCase(repository)(
      fullName: 'Renamed User',
      phone: '01000000000',
    );

    expect(result.isSuccess, isTrue);
    expect(result.valueOrNull?.fullName, 'Renamed User');
    expect(result.valueOrNull?.phone, '01000000000');
  });
}
