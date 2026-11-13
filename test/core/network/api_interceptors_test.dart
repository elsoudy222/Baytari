/// Unit tests for the Dio interceptors and their wiring in [ApiClient].
///
/// The interceptors are tested through a real Dio that never touches
/// the network: [_CapturingAdapter] is a stub `HttpClientAdapter`
/// that answers every request with an empty 200 and records the
/// request options, so the tests can assert on the headers the
/// interceptors added. No Supabase session exists in tests
/// (demo mode), so the auth tests only prove the "no session, no
/// header, no crash" case — a signed-in token is verified by the
/// live app, not here.
library;

import 'dart:typed_data';

import 'package:baytari/core/constants/app_constants.dart';
import 'package:baytari/core/network/api_client.dart';
import 'package:baytari/core/network/api_interceptors.dart';
import 'package:baytari/core/services/app_settings_service.dart';
import 'package:baytari/core/services/supabase_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A fake HTTP adapter: captures the request and answers `200 {}`.
///
/// Dio calls `fetch` for every request; this stub never opens a
/// socket, so the tests are fast and offline-safe.
class _CapturingAdapter implements HttpClientAdapter {
  RequestOptions? lastOptions;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastOptions = options;
    return ResponseBody.fromString('{}', 200);
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late _CapturingAdapter adapter;

  setUp(() {
    adapter = _CapturingAdapter();
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  Future<AppSettingsService> createSettings() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return AppSettingsService(prefs);
  }

  Dio createDio({List<Interceptor>? interceptors}) {
    final Dio dio = Dio();
    dio.httpClientAdapter = adapter;
    if (interceptors != null) {
      dio.interceptors.addAll(interceptors);
    }
    return dio;
  }

  group('LanguageInterceptor', () {
    test('sends Accept-Language: ar when no locale is saved', () async {
      final AppSettingsService settings = await createSettings();
      final Dio dio = createDio(
        interceptors: <Interceptor>[LanguageInterceptor(settings)],
      );

      await dio.get<dynamic>('https://example.com/ping');

      expect(adapter.lastOptions?.headers['Accept-Language'], 'ar');
    });

    test('sends Accept-Language: en after the locale is saved as en',
        () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        AppConstants.localeCodeKey: 'en',
      });
      final AppSettingsService settings = await createSettings();
      final Dio dio = createDio(
        interceptors: <Interceptor>[LanguageInterceptor(settings)],
      );

      await dio.get<dynamic>('https://example.com/ping');

      expect(adapter.lastOptions?.headers['Accept-Language'], 'en');
    });
  });

  group('AuthInterceptor', () {
    test('adds no Authorization header when Supabase is not configured',
        () async {
      // A fresh SupabaseService is unconfigured in tests (no
      // --dart-define keys), i.e. demo mode: the interceptor must
      // leave the request alone instead of throwing.
      final Dio dio = createDio(
        interceptors: <Interceptor>[AuthInterceptor(SupabaseService())],
      );

      await dio.get<dynamic>('https://example.com/ping');

      expect(
        adapter.lastOptions?.headers.containsKey('Authorization'),
        isFalse,
      );
    });
  });

  group('ApiClient wiring', () {
    test('wires both interceptors: language header present, no crash',
        () async {
      final AppSettingsService settings = await createSettings();
      final ApiClient client = ApiClient(
        dio: createDio(),
        supabaseService: SupabaseService(),
        settingsService: settings,
      );
      // Point the client's Dio at the capturing adapter too.
      client.dio.httpClientAdapter = adapter;

      await client.get<dynamic>('https://example.com/ping');

      expect(adapter.lastOptions?.headers['Accept-Language'], 'ar');
      expect(
        adapter.lastOptions?.headers.containsKey('Authorization'),
        isFalse,
      );
    });

    test('without services it still works (interceptors skipped)', () async {
      final ApiClient client = ApiClient(dio: createDio());
      client.dio.httpClientAdapter = adapter;

      await client.get<dynamic>('https://example.com/ping');

      expect(
        adapter.lastOptions?.headers.containsKey('Accept-Language'),
        isFalse,
      );
    });
  });
}
