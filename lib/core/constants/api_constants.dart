/// Networking constants for the Dio client in `core/network`.
///
/// There is no base URL here in M0: Supabase is the backend and it is
/// reached through the Supabase client, not through Dio. Dio is kept
/// configured and ready for any future REST endpoint — when one is
/// added, its base URL goes here, in one place, not in a data source.
abstract final class ApiConstants {
  // The timeouts: 15s to connect, 30s to send/receive. They are
  // deliberately generous for mobile networks, and they stop a request
  // from hanging forever if the server never answers.
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);

  static const String jsonContentType = 'application/json';
}
