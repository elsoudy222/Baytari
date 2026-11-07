/// A user's profile — the DOMAIN entity for the `profiles` table.
///
/// This is a plain Dart class ([Equatable] for value equality, no
/// Flutter imports): the domain layer defines *what* a profile is,
/// and the data layer (`ProfileModel`) is responsible for converting
/// it to/from JSON. `id` is the Supabase auth user id — the profile
/// row and the auth account are the same person, by design (the
/// migration makes `profiles.id` a foreign key to `auth.users`).
library;

import 'package:equatable/equatable.dart';

import 'user_role.dart';

class Profile extends Equatable {
  const Profile({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    this.phone,
    this.avatarUrl,
    this.username,
    this.licenseUrl,
    this.workplaceNote,
    this.createdAt,
  });

  /// The Supabase auth user id (uuid). Same value as `auth.users.id`.
  final String id;

  final String email;

  final String fullName;

  final UserRole role;

  /// Optional phone number (may be empty for users who skipped it).
  final String? phone;

  /// Optional avatar image URL (uploaded to the `avatars` Storage
  /// bucket from the sign-up "username + photo" step).
  final String? avatarUrl;

  /// The username picked on the sign-up "Welcome To Baytari!" step.
  /// Unique in the database (migration 20261107000002); null until
  /// the user picks one.
  final String? username;

  /// Storage path of the licence photo, uploaded to the private
  /// `licenses` bucket during vet / shelter sign-up ("Verify Your
  /// License"). It is a storage *path* (not a public URL) because
  /// the bucket is private — only the user and admins can open it.
  final String? licenseUrl;

  /// A pending text note for staff vets / shelter workers: the
  /// clinic or shelter they said they work at. There are no
  /// clinics / shelters in the database yet (M3/M5), so this is
  /// free text for now, not a foreign key — see the Arabic doc.
  final String? workplaceNote;

  final DateTime? createdAt;

  /// Returns a copy with only the given fields replaced. Used by
  /// the Cubit after an update, and by tests — the entity itself is
  /// immutable, so nobody edits a Profile in place.
  Profile copyWith({
    String? id,
    String? email,
    String? fullName,
    UserRole? role,
    String? phone,
    String? avatarUrl,
    String? username,
    String? licenseUrl,
    String? workplaceNote,
    DateTime? createdAt,
  }) {
    return Profile(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      username: username ?? this.username,
      licenseUrl: licenseUrl ?? this.licenseUrl,
      workplaceNote: workplaceNote ?? this.workplaceNote,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    id,
    email,
    fullName,
    role,
    phone,
    avatarUrl,
    username,
    licenseUrl,
    workplaceNote,
    createdAt,
  ];
}
