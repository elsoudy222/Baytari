/// Supabase configuration keys and table names.
///
/// The URL and anon key are **never** hardcoded. They are supplied with
/// `--dart-define SUPABASE_URL=... SUPABASE_ANON_KEY=...` at run time.
/// If they are not supplied, [SupabaseService] reports "not configured"
/// and the app runs in demo mode (see `core/services/supabase_service.dart`).
abstract final class SupabaseConstants {
  static const String urlDefineKey = 'SUPABASE_URL';
  static const String anonKeyDefineKey = 'SUPABASE_ANON_KEY';

  // Table names from the implementation plan (§4). No tables exist yet —
  // the Supabase project itself has not been created. These names are
  // constants so M1+ data sources use one source of truth.
  static const String profilesTable = 'profiles';
  static const String clinicsTable = 'clinics';
  static const String vetsTable = 'vets';
  static const String petsTable = 'pets';
  static const String servicesTable = 'services';
  static const String appointmentsTable = 'appointments';
  static const String shiftsTable = 'shifts';
  static const String reviewsTable = 'reviews';

  // Storage buckets from the implementation plan (§4).
  static const String avatarsBucket = 'avatars';
  static const String petPhotosBucket = 'pet-photos';
}
