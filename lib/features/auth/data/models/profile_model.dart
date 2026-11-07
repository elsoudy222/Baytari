/// Data model for a profile row — the JSON <-> [Profile] converter.
///
/// The domain entity ([Profile]) knows nothing about JSON; this
/// model does the translation, manually (`fromJson` / `toJson`,
/// no codegen — the plan keeps codegen minimal in v1). The database
/// column names are snake_case (`full_name`, `avatar_url`), the
/// Dart fields are camelCase — the mapping lives only here, so a
/// column rename touches exactly one file.
library;

import '../../domain/entities/profile.dart';
import '../../domain/entities/user_role.dart';

class ProfileModel extends Profile {
  const ProfileModel({
    required super.id,
    required super.email,
    required super.fullName,
    required super.role,
    super.phone,
    super.avatarUrl,
    super.username,
    super.licenseUrl,
    super.workplaceNote,
    super.createdAt,
  });

  /// Builds a model from one row of the `profiles` table (a JSON
  /// map from Supabase). `created_at` is an ISO-8601 string in the
  /// database; `DateTime.tryParse` returns null instead of throwing
  /// on a bad value, so one bad row never crashes the app.
  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      fullName: json['full_name'] as String? ?? '',
      role: UserRole.fromString(json['role'] as String?),
      phone: json['phone'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      username: json['username'] as String?,
      licenseUrl: json['license_url'] as String?,
      workplaceNote: json['workplace_note'] as String?,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.tryParse(json['created_at'] as String),
    );
  }

  /// Builds a model from a Supabase auth user (not a table row):
  /// the id/email come from the auth account, the name/role/phone
  /// from the metadata saved at sign-up time (`signUp(data: ...)`).
  /// Used by `_ensureProfile` when the profile row does not exist
  /// yet — e.g. the user confirmed their email and signs in for
  /// the first time.
  factory ProfileModel.fromAuthUser({
    required String id,
    required String email,
    required Map<String, dynamic>? metadata,
  }) {
    return ProfileModel(
      id: id,
      email: email,
      fullName: metadata?['full_name'] as String? ?? '',
      role: UserRole.fromString(metadata?['role'] as String?),
      phone: metadata?['phone'] as String?,
      username: metadata?['username'] as String?,
      workplaceNote: metadata?['workplace_note'] as String?,
    );
  }

  /// The map written to the `profiles` table on INSERT. `id` is
  /// included: the profile row's id IS the auth user id (the
  /// migration makes it a foreign key to `auth.users`). The new
  /// columns (`username`, `license_url`, `workplace_note`) come
  /// from migration 20261107000002 — apply it before running this
  /// code, or the insert fails on the unknown columns.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'email': email,
      'full_name': fullName,
      'role': role.value,
      'phone': phone,
      'avatar_url': avatarUrl,
      'username': username,
      'license_url': licenseUrl,
      'workplace_note': workplaceNote,
    };
  }

  /// The map written on UPDATE: only the fields a user may change
  /// themselves. `role` is deliberately absent — a user must not
  /// promote themselves to vet by editing a form (see
  /// `UpdateProfileUseCase`). Null values are dropped by the
  /// caller (`updateProfile` in the data source) so an update of
  /// the name never wipes the avatar or username.
  Map<String, dynamic> toUpdateJson() {
    return <String, dynamic>{
      'full_name': fullName,
      'phone': phone,
      'avatar_url': avatarUrl,
      'username': username,
      'license_url': licenseUrl,
      'workplace_note': workplaceNote,
    };
  }
}
