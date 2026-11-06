/// Low-level exceptions thrown by data sources.
/// Presentation code must never catch these directly — repositories map
/// them to [Failure]s (see `failures.dart`).
class AppException implements Exception {
  const AppException(this.message);

  final String message;

  @override
  String toString() => 'AppException: $message';
}

class ServerException extends AppException {
  const ServerException(super.message);
}

class NetworkException extends AppException {
  const NetworkException(super.message);
}

class CacheException extends AppException {
  const CacheException(super.message);
}

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
