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
void registerCore(GetIt sl, SharedPreferences prefs) {
  sl.registerSingleton<SharedPreferences>(prefs);

  sl.registerLazySingleton<AppSettingsService>(
    () => AppSettingsService(sl<SharedPreferences>()),
  );
  sl.registerLazySingleton<SupabaseService>(() => SupabaseService());
  sl.registerLazySingleton<ApiClient>(() => ApiClient());

  sl.registerFactory<AppCubit>(
    () => AppCubit(sl<AppSettingsService>(), sl<SupabaseService>()),
  );
}
