/// The role of a user, as stored in the `profiles.role` column
/// (Postgres enum `user_role`, see the M1 SQL migration).
///
/// This enum lives in the DOMAIN layer: pure Dart, no Flutter,
/// Supabase or Postgres imports. The data layer converts between
/// this enum and the database string (`owner`, `vet`, ...) in
/// `ProfileModel` — the domain never sees the raw string.
///
/// Only [owner] and [vet] are offered on the register screen.
/// [staffVet] and [clinicAdmin] exist for later stages (clinic
/// staff management, M5) and are never selectable in the M1 UI.
library;

enum UserRole {
  owner,
  vet,
  staffVet,
  clinicAdmin;

  /// The exact string stored in the database (`owner`, `vet`,
  /// `staff_vet`, `clinic_admin`). Note the snake_case: the database
  /// uses `staff_vet`, Dart uses `staffVet`.
  String get value => switch (this) {
    UserRole.owner => 'owner',
    UserRole.vet => 'vet',
    UserRole.staffVet => 'staff_vet',
    UserRole.clinicAdmin => 'clinic_admin',
  };

  /// Parses a database string back into a [UserRole]. Unknown or
  /// missing values fall back to [owner] instead of crashing — a
  /// profile row must never break the whole app because of a typo
  /// in one column.
  static UserRole fromString(String? value) => switch (value) {
    'owner' => UserRole.owner,
    'vet' => UserRole.vet,
    'staff_vet' => UserRole.staffVet,
    'clinic_admin' => UserRole.clinicAdmin,
    _ => UserRole.owner,
  };
}
