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
  /// the updated profile.
  Future<Result<Profile>> updateProfile({
    required String fullName,
    String? phone,
  });
}
