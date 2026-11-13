import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/app_cubit.dart';
import '../network/api_client.dart';
import '../services/app_settings_service.dart';
import '../services/supabase_service.dart';

/// Registers core dependencies in dependency order:
/// SharedPreferences -> services -> ApiClient -> AppCubit.
/// Feature registrations (M1+) are added in `injection_container.dart`
/// after this function, in the same order: data source -> repository ->
/// use case -> cubit.
///
/// Why three different registration types:
/// - `registerSingleton` (SharedPreferences) — one instance already
///   exists, created in `main.dart`; GetIt only stores it.
/// - `registerLazySingleton` (services, ApiClient) — created once, the
///   first time something asks for them, then reused everywhere.
/// - `registerFactory` ([AppCubit]) — a *new* Cubit every time one is
///   requested, so each `BlocProvider` gets its own independent Cubit.
void registerCore(GetIt sl, SharedPreferences prefs) {
  sl.registerSingleton<SharedPreferences>(prefs);

  sl.registerLazySingleton<AppSettingsService>(
    () => AppSettingsService(sl<SharedPreferences>()),
  );
  sl.registerLazySingleton<SupabaseService>(() => SupabaseService());
  // ApiClient is registered after both services it depends on: the
  // AuthInterceptor needs SupabaseService (access token) and the
  // LanguageInterceptor needs AppSettingsService (saved locale).
  // Both are passed in here so the interceptors are always active in
  // production; Supabase Auth/DB calls still use supabase_flutter
  // directly and never go through Dio.
  sl.registerLazySingleton<ApiClient>(
    () => ApiClient(
      supabaseService: sl<SupabaseService>(),
      settingsService: sl<AppSettingsService>(),
    ),
  );

  sl.registerFactory<AppCubit>(
    () => AppCubit(sl<AppSettingsService>(), sl<SupabaseService>()),
  );
}
