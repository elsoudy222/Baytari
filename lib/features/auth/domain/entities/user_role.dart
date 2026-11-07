/// The role of a user, as stored in the `profiles.role` column
/// (Postgres enum `user_role`, see the M1 + auth-UI SQL migrations).
///
/// This enum lives in the DOMAIN layer: pure Dart, no Flutter,
/// Supabase or Postgres imports. The data layer converts between
/// this enum and the database string (`owner`, `vet`, ...) in
/// `ProfileModel` — the domain never sees the raw string.
///
/// Roles offered on the sign-up screen (Figma `Sign_Up.png`):
/// [owner] (Community Member), [vet] (Veterinarian — clinic
/// owner), [shelterOwner] (Shelter — shelter owner). The two
/// "worker" roles are chosen on the Account Information step:
/// [staffVet] (Staff vet — works at a clinic) and [shelterWorker]
/// (Shelter worker — works at a shelter). [clinicAdmin] exists for
/// later stages (clinic staff management, M5) and is never
/// selectable in the sign-up UI.
library;

enum UserRole {
  owner,
  vet,
  staffVet,
  clinicAdmin,
  shelterOwner,
  shelterWorker;

  /// The exact string stored in the database (`owner`, `vet`,
  /// `staff_vet`, `clinic_admin`, `shelter_owner`,
  /// `shelter_worker`). Note the snake_case: the database uses
  /// `staff_vet`, Dart uses `staffVet`.
  String get value => switch (this) {
    UserRole.owner => 'owner',
    UserRole.vet => 'vet',
    UserRole.staffVet => 'staff_vet',
    UserRole.clinicAdmin => 'clinic_admin',
    UserRole.shelterOwner => 'shelter_owner',
    UserRole.shelterWorker => 'shelter_worker',
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
    'shelter_owner' => UserRole.shelterOwner,
    'shelter_worker' => UserRole.shelterWorker,
    _ => UserRole.owner,
  };
}
