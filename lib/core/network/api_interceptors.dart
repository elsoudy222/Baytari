/// Dio interceptors for the centralized [ApiClient].
///
/// Interceptors run on every HTTP request/response that goes through
/// Dio, so cross-cutting concerns (auth, language, logging) live here
/// once instead of being repeated in every data source.
///
/// There are three of them, added to Dio in this order:
/// 1. [AuthInterceptor] — attaches the Supabase access token.
/// 2. [LanguageInterceptor] — sends the app's current locale.
/// 3. Dio's built-in [LogInterceptor] — pretty request/response
///    logging, debug builds only (see `api_client.dart`).
///
/// Why interceptors and not headers set once in `ApiClient`?
/// The access token and the locale can both change while the app is
/// running (sign in/out, language switch). An interceptor reads the
/// *current* value on every request, so a token obtained after login
/// or a language changed in settings is picked up immediately —
/// a header set once at startup would go stale.
///
/// Supabase Auth/DB calls are NOT affected: they go through the
/// Supabase client (`supabase_flutter`), never through Dio. These
/// interceptors only apply to future REST calls made with Dio.
library;

import 'package:dio/dio.dart';

import '../services/app_settings_service.dart';
import '../services/supabase_service.dart';

/// Adds `Authorization: Bearer <access token>` to every request
/// when the user is signed in.
///
/// The token is read from the Supabase session **at request time**
/// (`currentSession?.accessToken`) — it is never stored in a file,
/// never copied into a variable that outlives the request, and never
/// logged. Supabase refreshes the session token itself, so the
/// interceptor always sees a fresh token.
///
/// When Supabase is not configured (demo mode) or there is no
/// session (guest / signed out), the request simply goes out
/// without the header — the server then answers as an anonymous
/// caller instead of the app crashing.
class AuthInterceptor extends Interceptor {
  /// Takes the [SupabaseService] (not the raw client) so the
  /// interceptor can ask `isConfigured` first: reading
  /// `SupabaseService.client` while unconfigured throws, and an
  /// interceptor must never throw for a missing session.
  AuthInterceptor(this._supabaseService);

  final SupabaseService _supabaseService;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    // No Supabase, no session, no header — and no crash.
    if (_supabaseService.isConfigured) {
      final String? token = _supabaseService
          .client
          .auth
          .currentSession
          ?.accessToken;
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    // `handler.next` passes the (possibly modified) request on to
    // the next interceptor, and finally to the network.
    handler.next(options);
  }
}

/// Adds `Accept-Language: <language code>` to every request
/// (`ar` or `en`).
///
/// The code comes from [AppSettingsService], which reads the
/// *persisted* locale — the same locale the UI is showing. So a
/// server that localizes its responses (e.g. error messages) always
/// answers in the language the user actually picked, and a language
/// change in settings takes effect on the very next request without
/// restarting the app or rebuilding the Dio client.
class LanguageInterceptor extends Interceptor {
  /// The settings service is the single source of truth for the
  /// locale; the interceptor never keeps its own copy of it.
  LanguageInterceptor(this._settingsService);

  final AppSettingsService _settingsService;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    options.headers['Accept-Language'] =
        _settingsService.getLocale().languageCode;
    handler.next(options);
  }
}
