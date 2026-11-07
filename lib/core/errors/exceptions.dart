/// Low-level exceptions thrown by data sources.
///
/// Two-level error design (do not mix them):
/// - **Exceptions** (this file) are thrown at the bottom, by data
///   sources — they name the *technical* cause (server, network,
///   cache, auth, not configured).
/// - **[Failure]s** (`failures.dart`) are what the domain layer sees.
///   A repository catches an exception and returns the matching
///   Failure, so Cubits and UI never import Dio or Supabase.
/// Presentation code must never catch these directly — repositories map
/// them to [Failure]s (see `failures.dart`).
class AppException implements Exception {
  const AppException(this.message);

  final String message;

  @override
  String toString() => 'AppException: $message';
}

/// The server answered, but with an error (e.g. HTTP 500).
class ServerException extends AppException {
  const ServerException(super.message);
}

/// The request never reached the server (no internet, timeout).
class NetworkException extends AppException {
  const NetworkException(super.message);
}

/// Local storage failed (read/write of cached data).
class CacheException extends AppException {
  const CacheException(super.message);
}

/// The user is not logged in, or has no permission (HTTP 401/403).
class AuthException extends AppException {
  const AuthException(super.message);
}

/// Thrown when Supabase was not configured with `--dart-define`.
/// This is an expected M0 state, not a crash: the app runs in demo mode.
class SupabaseNotConfiguredException extends AppException {
  const SupabaseNotConfiguredException()
    : super(
        'Supabase is not configured. Run with '
        '--dart-define SUPABASE_URL=... '
        '--dart-define SUPABASE_ANON_KEY=...',
      );
}
