/// The auth repository CONTRACT (domain layer).
///
/// An abstract class, not an implementation: the domain defines
/// *what* auth can do, the data layer (`AuthRepositoryImpl`) decides
/// *how* (Supabase). Cubits and use cases depend only on this
/// contract — they never import Supabase, Dio, or the data layer —
/// which is what makes them unit-testable with a fake repository
/// (see `test/features/auth/`).
///
/// Every method returns a [Result]: [Success] with the value, or
/// [FailureResult] with a domain [Failure]. Nothing here throws.
library;

import '../../../../core/errors/result.dart';
import '../entities/profile.dart';
import '../entities/user_role.dart';

abstract class AuthRepository {
  /// Creates an auth account (email + password) and its profile row.
  /// `fullName` and `role` are stored in the auth user's metadata
  /// at sign-up and then written into the `profiles` table.
  /// If Supabase email confirmation is ON, the returned profile is
  /// null and the user must confirm by email first — in that case
  /// the profile row is created on the first sign-in instead
  /// (see the data source's `_ensureProfile`).
  Future<Result<Profile?>> signUp({
    required String email,
    required String password,
    required String fullName,
    required UserRole role,
    String? phone,
    String? workplaceNote,
  });

  /// Signs in with email + password and returns the profile.
  Future<Result<Profile>> signIn({
    required String email,
    required String password,
  });

  /// Signs out (clears the locally stored session).
  Future<Result<void>> signOut();

  /// Returns the profile of the currently signed-in user, or null
  /// when nobody is signed in. Supabase persists the session on
  /// the device, so this is how the app knows the user is still
  /// logged in after a restart — no token is stored by the app.
  Future<Result<Profile?>> getCurrentProfile();

  /// Updates the current user's profile (name / phone) and returns
  /// the updated profile. The new fields are optional: only the
  /// ones passed are written (username / avatar / licence /
  /// workplace note are set by the sign-up wizard, see
  /// [updateUsernameAndAvatar]).
  Future<Result<Profile>> updateProfile({
    required String fullName,
    String? phone,
    String? username,
    String? avatarUrl,
    String? licenseUrl,
    String? workplaceNote,
  });

  /// Sends a 6-digit email OTP to [email] for a just-created
  /// account (sign-up verification). Used by the sign-up wizard
  /// after [signUp] returned "awaiting confirmation".
  /// `shouldCreateUser` is false: the account already exists, so
  /// this must never create a new one.
  Future<Result<void>> requestSignupOtp({required String email});

  /// Verifies the sign-up OTP. On success the user is signed in
  /// and the profile (created by `_ensureProfile`) is returned.
  Future<Result<Profile>> verifySignupOtp({
    required String email,
    required String token,
  });

  /// Sends a 6-digit email OTP to [email] for password recovery.
  /// `shouldCreateUser` is false: an unknown email must fail
  /// instead of silently creating an account.
  Future<Result<void>> requestPasswordReset({required String email});

  /// Verifies the recovery OTP. On success the user holds a
  /// recovery session, which is what allows [resetPassword] to
  /// set the new password.
  Future<Result<void>> verifyRecoveryOtp({
    required String email,
    required String token,
  });

  /// Sets the new password for the signed-in (recovery) session,
  /// then signs out — the user signs in again with the new
  /// password, as the Figma success screen expects.
  Future<Result<void>> resetPassword({required String newPassword});

  /// Sets the username and avatar of the current user's profile
  /// (the sign-up "Welcome To Baytari!" step) and returns the
  /// updated profile. Either field may be omitted.
  Future<Result<Profile>> updateUsernameAndAvatar({
    String? username,
    String? avatarUrl,
  });

  /// Uploads a licence photo (JPEG bytes) to the private `licenses`
  /// Storage bucket and returns its storage path. The path is
  /// stored on the profile as `license_url` by the caller (via
  /// [updateProfile]); this method only uploads.
  Future<Result<String>> uploadLicense(List<int> bytes);

  /// Uploads an avatar photo (JPEG bytes) to the public `avatars`
  /// Storage bucket and returns its public URL. The URL is stored
  /// on the profile as `avatar_url` by the caller.
  Future<Result<String>> uploadAvatar(List<int> bytes);
}
