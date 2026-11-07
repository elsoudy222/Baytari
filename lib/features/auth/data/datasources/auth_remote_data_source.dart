/// The auth data source CONTRACT (data layer).
///
/// The single place that talks to Supabase Auth + the `profiles`
/// table. The repository calls this; nobody else does. Methods
/// throw [AppException] subclasses on failure (the repository maps
/// them to domain [Failure]s) and return `null` only where "nothing
/// found" is a normal result (no signed-in user / no session yet).
library;

import '../../domain/entities/user_role.dart';
import '../models/profile_model.dart';

abstract class AuthRemoteDataSource {
  /// Creates the auth account. Returns the created profile when the
  /// user is signed in immediately (email confirmation OFF), or
  /// null when the user must confirm their email first (the profile
  /// row is then created on the first sign-in, see [getCurrentProfile]).
  Future<ProfileModel?> signUp({
    required String email,
    required String password,
    required String fullName,
    required UserRole role,
    String? phone,
    String? workplaceNote,
  });

  /// Signs in and returns the profile.
  Future<ProfileModel> signIn({
    required String email,
    required String password,
  });

  /// Signs out (clears the stored session).
  Future<void> signOut();

  /// The profile of the currently signed-in user, or null when
  /// nobody is signed in. Creates the profile row first if the
  /// auth user exists but the row is missing (first sign-in after
  /// email confirmation).
  Future<ProfileModel?> getCurrentProfile();

  /// Updates the current user's profile and returns the new row.
  /// Only non-null fields are written (see `ProfileModel.toUpdateJson`).
  Future<ProfileModel> updateProfile({
    required String fullName,
    String? phone,
    String? username,
    String? avatarUrl,
    String? licenseUrl,
    String? workplaceNote,
  });

  /// Sends a 6-digit email OTP for sign-up verification.
  Future<void> requestSignupOtp({required String email});

  /// Verifies the sign-up OTP and returns the profile.
  Future<ProfileModel> verifySignupOtp({
    required String email,
    required String token,
  });

  /// Sends a 6-digit email OTP for password recovery.
  Future<void> requestPasswordReset({required String email});

  /// Verifies the recovery OTP (creates a recovery session).
  Future<void> verifyRecoveryOtp({
    required String email,
    required String token,
  });

  /// Sets the new password for the recovery session, then signs out.
  Future<void> resetPassword({required String newPassword});

  /// Uploads an avatar photo to the `avatars` bucket, returns the
  /// public URL.
  Future<String> uploadAvatar(List<int> bytes);

  /// Uploads a licence photo to the private `licenses` bucket,
  /// returns the storage path.
  Future<String> uploadLicense(List<int> bytes);
}
