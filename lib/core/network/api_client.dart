import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../constants/api_constants.dart';
import '../errors/exceptions.dart';
import '../services/app_settings_service.dart';
import '../services/supabase_service.dart';
import 'api_interceptors.dart';

/// Central Dio client. All HTTP traffic in the app goes through this class
/// (from data sources only — never from widgets or Cubits).
///
/// There is no REST base URL in M0: Supabase is the backend and it is
/// accessed through the Supabase client, not through Dio. Dio is kept
/// configured and ready for any future REST endpoints, and its error
/// mapping is unit-testable through [mapError].
///
/// The client is the app's *centralized* ApiService: every request
/// passes through three interceptors, added in this order —
/// [AuthInterceptor] (Bearer token when signed in),
/// [LanguageInterceptor] (`Accept-Language` from the saved locale),
/// and Dio's [LogInterceptor] (pretty request/response logging,
/// debug builds only — it prints bodies, so it must never ship in a
/// release build). See `api_interceptors.dart` for why each one reads
/// its value at request time instead of once at startup.
class ApiClient {
  /// The Dio instance is injectable (`Dio? dio`) so tests can pass a
  /// fake Dio — the client never reaches the real network in tests.
  ///
  /// The two services are optional (`?`) so old call sites and tests
  /// can still build an `ApiClient()` with no arguments: without them
  /// the interceptors are simply skipped and the client behaves
  /// exactly as before. In production GetIt always passes both.
  ApiClient({
    Dio? dio,
    SupabaseService? supabaseService,
    AppSettingsService? settingsService,
  }) : _dio = dio ?? Dio() {
    _dio.options
      ..connectTimeout = ApiConstants.connectTimeout
      ..receiveTimeout = ApiConstants.receiveTimeout
      ..sendTimeout = ApiConstants.sendTimeout
      ..headers = <String, String>{
        'Content-Type': ApiConstants.jsonContentType,
      };
    // Auth first (so the token is on the request before anything
    // else sees it), then language, then logging last so the log
    // shows the final headers that actually go out.
    if (supabaseService != null) {
      _dio.interceptors.add(AuthInterceptor(supabaseService));
    }
    if (settingsService != null) {
      _dio.interceptors.add(LanguageInterceptor(settingsService));
    }
    // `kDebugMode` is true for `flutter run` and `flutter test`,
    // false for release/profile builds — logging never ships.
    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(requestBody: true, responseBody: true),
      );
    }
  }

  final Dio _dio;

  Dio get dio => _dio;

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw mapError(e);
    }
  }

  Future<Response<T>> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw mapError(e);
    }
  }

  /// Maps a [DioException] to a plain [AppException]. Kept public and
  /// static so it can be unit tested without a network call.
  ///
  /// The mapping is by *cause*, not by message text: timeouts and
  /// connection errors become [NetworkException] (the user's internet),
  /// 401/403 become [AuthException] (login/permission), any other HTTP
  /// error becomes [ServerException] with the status code attached, and
  /// a cancelled request is its own case so a user cancelling is not
  /// reported as a network failure. Repositories will later map these
  /// exceptions to the matching [Failure]s.
  static AppException mapError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return const NetworkException('Network connection failed.');
      case DioExceptionType.badResponse:
        final int? statusCode = error.response?.statusCode;
        if (statusCode == 401 || statusCode == 403) {
          return const AuthException('Not authorized.');
        }
        return ServerException(
          'Server error${statusCode == null ? '' : ' ($statusCode)'}.',
        );
      case DioExceptionType.cancel:
        return const AppException('Request was cancelled.');
      case DioExceptionType.badCertificate:
        return const NetworkException('Bad certificate.');
      case DioExceptionType.transformTimeout:
        return const NetworkException('Response transformation timed out.');
      case DioExceptionType.unknown:
        return const NetworkException('Unknown network error.');
    }
  }
}
