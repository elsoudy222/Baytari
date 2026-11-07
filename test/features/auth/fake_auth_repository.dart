/// A fake [AuthRepository] for tests: no Supabase, no network.
///
/// The behaviour is controlled by setting its fields before the
/// test runs: [profileToReturn] is what sign-in / session restore
/// return, [signUpProfile] is what sign-up returns (null means
/// "email confirmation required"), and [failure] makes every call
/// fail with that failure. [calls] records which methods ran, so a
/// test can assert the Cubit actually called the use case.
library;

import 'package:baytari/core/errors/failures.dart';
import 'package:baytari/core/errors/result.dart';
import 'package:baytari/features/auth/domain/entities/profile.dart';
import 'package:baytari/features/auth/domain/entities/user_role.dart';
import 'package:baytari/features/auth/domain/repositories/auth_repository.dart';

class FakeAuthRepository implements AuthRepository {
  Profile? profileToReturn;
  Profile? signUpProfile;
  Failure? failure;
  final List<String> calls = <String>[];

  @override
  Future<Result<Profile?>> signUp({
    required String email,
    required String password,
    required String fullName,
    required UserRole role,
    String? phone,
    String? workplaceNote,
  }) async {
    calls.add('signUp');
    if (failure != null) {
      return FailureResult<Profile?>(failure!);
    }
    return Success<Profile?>(signUpProfile);
  }

  @override
  Future<Result<Profile>> signIn({
    required String email,
    required String password,
  }) async {
    calls.add('signIn');
    if (failure != null) {
      return FailureResult<Profile>(failure!);
    }
    return Success<Profile>(profileToReturn!);
  }

  @override
  Future<Result<void>> signOut() async {
    calls.add('signOut');
    if (failure != null) {
      return FailureResult<void>(failure!);
    }
    return const Success<void>(null);
  }

  @override
  Future<Result<Profile?>> getCurrentProfile() async {
    calls.add('getCurrentProfile');
    if (failure != null) {
      return FailureResult<Profile?>(failure!);
    }
    return Success<Profile?>(profileToReturn);
  }

  @override
  Future<Result<Profile>> updateProfile({
    required String fullName,
    String? phone,
    String? username,
    String? avatarUrl,
    String? licenseUrl,
    String? workplaceNote,
  }) async {
    calls.add('updateProfile');
    if (failure != null) {
      return FailureResult<Profile>(failure!);
    }
    return Success<Profile>(
      profileToReturn!.copyWith(
        fullName: fullName,
        phone: phone,
        username: username,
        avatarUrl: avatarUrl,
        licenseUrl: licenseUrl,
        workplaceNote: workplaceNote,
      ),
    );
  }

  @override
  Future<Result<void>> requestSignupOtp({required String email}) async {
    calls.add('requestSignupOtp');
    if (failure != null) {
      return FailureResult<void>(failure!);
    }
    return const Success<void>(null);
  }

  @override
  Future<Result<Profile>> verifySignupOtp({
    required String email,
    required String token,
  }) async {
    calls.add('verifySignupOtp');
    if (failure != null) {
      return FailureResult<Profile>(failure!);
    }
    return Success<Profile>(profileToReturn!);
  }

  @override
  Future<Result<void>> requestPasswordReset({required String email}) async {
    calls.add('requestPasswordReset');
    if (failure != null) {
      return FailureResult<void>(failure!);
    }
    return const Success<void>(null);
  }

  @override
  Future<Result<void>> verifyRecoveryOtp({
    required String email,
    required String token,
  }) async {
    calls.add('verifyRecoveryOtp');
    if (failure != null) {
      return FailureResult<void>(failure!);
    }
    return const Success<void>(null);
  }

  @override
  Future<Result<void>> resetPassword({required String newPassword}) async {
    calls.add('resetPassword');
    if (failure != null) {
      return FailureResult<void>(failure!);
    }
    return const Success<void>(null);
  }

  @override
  Future<Result<Profile>> updateUsernameAndAvatar({
    String? username,
    String? avatarUrl,
  }) async {
    calls.add('updateUsernameAndAvatar');
    if (failure != null) {
      return FailureResult<Profile>(failure!);
    }
    return Success<Profile>(
      profileToReturn!.copyWith(username: username, avatarUrl: avatarUrl),
    );
  }

  @override
  Future<Result<String>> uploadLicense(List<int> bytes) async {
    calls.add('uploadLicense');
    if (failure != null) {
      return FailureResult<String>(failure!);
    }
    return const Success<String>('licenses/user-id-1/license.jpg');
  }

  @override
  Future<Result<String>> uploadAvatar(List<int> bytes) async {
    calls.add('uploadAvatar');
    if (failure != null) {
      return FailureResult<String>(failure!);
    }
    return const Success<String>('https://example.com/avatar.jpg');
  }
}

/// One reusable profile for the tests: an owner called "Test User".
const Profile testProfile = Profile(
  id: 'user-id-1',
  email: 'test@example.com',
  fullName: 'Test User',
  role: UserRole.owner,
);
