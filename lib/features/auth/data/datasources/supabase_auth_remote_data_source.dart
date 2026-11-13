/// Supabase implementation of [AuthRemoteDataSource].
///
/// This is the ONLY file in the auth feature that imports Supabase.
/// Everything above it (repository, use cases, Cubit, UI) works
/// with plain [ProfileModel]/[Profile] objects and never sees a
/// Supabase type — that is the Clean Architecture boundary.
///
/// The Supabase import is prefixed (`supabase.`) on purpose: the
/// Supabase package also has a class called `AuthException`, and
/// the app has its own in `core/errors/exceptions.dart`. The prefix
/// keeps the two apart (`supabase.AuthException` vs ours).
///
/// SESSION PERSISTENCE: `supabase_flutter` stores the session on
/// the device itself (SharedPreferences). The app never saves or
/// reads a token — `getCurrentProfile` just asks Supabase who the
/// current user is, and after an app restart the answer is still
/// the same user until they sign out.
library;

import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../../../../core/constants/supabase_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/services/supabase_service.dart';
import '../../domain/entities/user_role.dart';
import '../models/profile_model.dart';
import 'auth_remote_data_source.dart';

class SupabaseAuthRemoteDataSource implements AuthRemoteDataSource {
  SupabaseAuthRemoteDataSource(this._supabaseService);

  final SupabaseService _supabaseService;

  /// The client. Throws [SupabaseNotConfiguredException] when the
  /// app was started without `--dart-define` keys — the repository
  /// turns that into a [NotConfiguredFailure] and the UI shows the
  /// demo-mode message instead of crashing.
  supabase.SupabaseClient get _client => _supabaseService.client;

  @override
  Future<ProfileModel?> signUp({
    required String email,
    required String password,
    required String fullName,
    required UserRole role,
    String? phone,
    String? workplaceNote,
  }) async {
    try {
      // `data:` becomes the auth user's metadata (user_metadata).
      // It is saved with the account, survives the email-confirmation
      // round-trip, and is the input for creating the profile row
      // (see _ensureProfile) — the app never asks the user twice.
      final supabase.AuthResponse response = await _client.auth.signUp(
        email: email,
        password: password,
        data: <String, dynamic>{
          'full_name': fullName,
          'role': role.value,
          'phone': phone,
          'workplace_note': workplaceNote,
        },
      );
      final supabase.User? user = response.user;
      if (user == null) {
        // Sign-up was rejected before creating a user (e.g. the
        // email is already registered) — Supabase reports that as
        // an error, so reaching here is unexpected; treat as auth.
        throw const AuthException('Sign-up did not create a user.');
      }
      if (response.session == null) {
        // Email confirmation is ON: the account exists, but there
        // is no session yet, so no profile row can be inserted
        // (RLS requires a logged-in user). The caller shows the
        // "check your email" message; the row is created on the
        // first sign-in by _ensureProfile.
        return null;
      }
      // Confirmation OFF: the user is signed in immediately, so
      // create the profile row now.
      return await _ensureProfile(user);
    } on supabase.AuthException catch (e) {
      // Wrong/duplicate email, weak password, ... — Supabase's own
      // message is technical; the repository maps it to a generic
      // AuthFailure and the UI shows a localized message.
      throw AuthException(e.message);
    } on supabase.PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }

  @override
  Future<ProfileModel> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final supabase.AuthResponse response = await _client.auth
          .signInWithPassword(email: email, password: password);
      final supabase.User? user = response.user;
      if (user == null) {
        throw const AuthException('Sign-in did not return a user.');
      }
      // A user who signed up before email confirmation has an auth
      // account but no profile row yet — create it now, from the
      // metadata saved at sign-up, instead of failing.
      return await _ensureProfile(user);
    } on supabase.AuthException catch (e) {
      throw AuthException(e.message);
    } on supabase.PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } on supabase.AuthException catch (e) {
      throw AuthException(e.message);
    }
  }

  @override
  Future<ProfileModel?> getCurrentProfile() async {
    // No session stored on the device -> nobody is signed in.
    // This is a normal result (not an error), so return null.
    final supabase.User? user = _client.auth.currentUser;
    if (user == null) {
      return null;
    }
    try {
      return await _ensureProfile(user);
    } on supabase.PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }

  @override
  Future<ProfileModel> updateProfile({
    required String fullName,
    String? phone,
    String? username,
    String? avatarUrl,
    String? licenseUrl,
    String? workplaceNote,
  }) async {
    final supabase.User? user = _client.auth.currentUser;
    if (user == null) {
      throw const AuthException('No signed-in user.');
    }
    try {
      // `.update(...).eq('id', ...).select().single()`: update this
      // user's row only, and return the updated row in one round
      // trip so the Cubit can show the new values immediately.
      // RLS also enforces "own row only" on the server side.
      // Null fields are dropped: an update of the name must never
      // wipe the username / avatar / licence that are already set.
      final Map<String, dynamic> changes =
          <String, dynamic>{
            'full_name': fullName,
            'phone': phone,
            'username': username,
            'avatar_url': avatarUrl,
            'license_url': licenseUrl,
            'workplace_note': workplaceNote,
          }..removeWhere((_, value) => value == null);
      final Map<String, dynamic> row = await _client
          .from(SupabaseConstants.profilesTable)
          .update(changes)
          .eq('id', user.id)
          .select()
          .single();
      return ProfileModel.fromJson(row);
    } on supabase.AuthException catch (e) {
      throw AuthException(e.message);
    } on supabase.PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }

  @override
  Future<void> requestSignupOtp({required String email}) async {
    try {
      // `shouldCreateUser: false` — the account already exists
      // (created by signUp); this must only send the code, never
      // create a second account. Supabase sends a 6-digit code to
      // the email when the project's email template uses the
      // `{{ .Token }}` variable (see the Arabic doc for the exact
      // Auth setting to check).
      await _client.auth.signInWithOtp(
        email: email,
        shouldCreateUser: false,
      );
    } on supabase.AuthException catch (e) {
      throw AuthException(e.message);
    }
  }

  @override
  Future<ProfileModel> verifySignupOtp({
    required String email,
    required String token,
  }) async {
    try {
      final supabase.AuthResponse response = await _client.auth.verifyOTP(
        email: email,
        token: token,
        type: supabase.OtpType.signup,
      );
      final supabase.User? user = response.user;
      if (user == null) {
        throw const AuthException('OTP verification did not return a user.');
      }
      // Now signed in: the profile row is created from the sign-up
      // metadata, exactly like the first sign-in after a link.
      return await _ensureProfile(user);
    } on supabase.AuthException catch (e) {
      throw AuthException(e.message);
    } on supabase.PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }

  @override
  Future<void> requestPasswordReset({required String email}) async {
    try {
      // `resetPasswordForEmail` issues a RECOVERY token — the only
      // token `verifyOTP(type: OtpType.recovery)` accepts. The
      // previous call used `signInWithOtp`, which issues an
      // email/magic-link token, so recovery verification always
      // failed. The sign-up OTP keeps `signInWithOtp` (paired
      // with `OtpType.signup`) — only the recovery pairing was
      // wrong.
      //
      // Unknown emails: GoTrue answers the /recover endpoint with
      // success even when the address has no account — it never
      // reveals whether an address is registered. The flow
      // therefore advances to the code step either way, and an
      // unknown address simply never receives a code. That is the
      // standard password-reset behaviour, not an error to show.
      await _client.auth.resetPasswordForEmail(email);
    } on supabase.AuthException catch (e) {
      throw AuthException(e.message);
    }
  }

  @override
  Future<void> verifyRecoveryOtp({
    required String email,
    required String token,
  }) async {
    try {
      // `OtpType.recovery`: Supabase issues a recovery session
      // (AuthChangeEvent.passwordRecovery). That session is what
      // authorizes `updateUser` in resetPassword below.
      await _client.auth.verifyOTP(
        email: email,
        token: token,
        type: supabase.OtpType.recovery,
      );
    } on supabase.AuthException catch (e) {
      throw AuthException(e.message);
    }
  }

  @override
  Future<void> resetPassword({required String newPassword}) async {
    try {
      await _client.auth.updateUser(
        supabase.UserAttributes(password: newPassword),
      );
      // The password is changed: sign out, so the user signs in
      // again with the new password (Figma success screen flow).
      await _client.auth.signOut();
    } on supabase.AuthException catch (e) {
      throw AuthException(e.message);
    }
  }

  @override
  Future<String> uploadAvatar(List<int> bytes) async {
    final supabase.User? user = _client.auth.currentUser;
    if (user == null) {
      throw const AuthException('No signed-in user.');
    }
    return _uploadFile(
      bucket: 'avatars',
      path: '${user.id}/avatar.jpg',
      bytes: bytes,
      publicUrl: true,
    );
  }

  @override
  Future<String> uploadLicense(List<int> bytes) async {
    final supabase.User? user = _client.auth.currentUser;
    if (user == null) {
      throw const AuthException('No signed-in user.');
    }
    // Private bucket: return the storage path, not a public URL
    // (a public URL would not open without a signed URL).
    return _uploadFile(
      bucket: 'licenses',
      path:
          '${user.id}/license_${DateTime.now().millisecondsSinceEpoch}.jpg',
      bytes: bytes,
      publicUrl: false,
    );
  }

  /// Uploads [bytes] to [bucket]/[path] (overwriting a previous
  /// file at the same path) and returns the public URL for a public
  /// bucket, or the storage path for a private one.
  Future<String> _uploadFile({
    required String bucket,
    required String path,
    required List<int> bytes,
    required bool publicUrl,
  }) async {
    try {
      await _client.storage
          .from(bucket)
          .uploadBinary(
            path,
            Uint8List.fromList(bytes),
            fileOptions: const supabase.FileOptions(upsert: true),
          );
      if (publicUrl) {
        return _client.storage.from(bucket).getPublicUrl(path);
      }
      return path;
    } on supabase.StorageException catch (e) {
      throw ServerException(e.message);
    }
  }

  /// Returns the profile row for [user], creating it first when it
  /// does not exist yet. This is the single place profile rows are
  /// created — sign-up, first sign-in after email confirmation,
  /// and session restore all funnel through here, so the row is
  /// never created twice and never missing for a signed-in user.
  ///
  /// `maybeSingle()` returns null instead of throwing when no row
  /// matches (unlike `single()`, which throws on zero rows).
  Future<ProfileModel> _ensureProfile(supabase.User user) async {
    final Map<String, dynamic>? row = await _client
        .from(SupabaseConstants.profilesTable)
        .select()
        .eq('id', user.id)
        .maybeSingle();
    if (row != null) {
      return ProfileModel.fromJson(row);
    }
    final ProfileModel model = ProfileModel.fromAuthUser(
      id: user.id,
      email: user.email ?? '',
      metadata: user.userMetadata,
    );
    final Map<String, dynamic> inserted = await _client
        .from(SupabaseConstants.profilesTable)
        .insert(model.toJson())
        .select()
        .single();
    return ProfileModel.fromJson(inserted);
  }
}
