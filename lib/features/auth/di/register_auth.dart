/// Auth dependency registration (GetIt).
///
/// Registration order is dependency order — a service is registered
/// only after everything it needs already exists:
///   SupabaseService (core, already registered)
///     -> [AuthRemoteDataSource] (lazy singleton, one instance)
///     -> [AuthRepository] (lazy singleton, one instance)
///     -> use cases (lazy singletons, stateless, one each)
///     -> [AuthCubit] (factory: a new Cubit per request — `BaytariApp`
///        creates one and owns it for the app's lifetime).
///
/// Widgets and Cubits never create these themselves; they ask GetIt
/// (`sl<AuthCubit>()`). That is what makes the auth flow testable:
/// tests register a fake [AuthRepository] instead of the real one.
library;

import 'package:get_it/get_it.dart';

import '../../../../core/services/supabase_service.dart';
import '../data/datasources/auth_remote_data_source.dart';
import '../data/datasources/supabase_auth_remote_data_source.dart';
import '../data/repositories/auth_repository_impl.dart';
import '../domain/repositories/auth_repository.dart';
import '../domain/usecases/get_current_profile_usecase.dart';
import '../domain/usecases/sign_in_usecase.dart';
import '../domain/usecases/sign_out_usecase.dart';
import '../domain/usecases/sign_up_usecase.dart';
import '../domain/usecases/update_profile_usecase.dart';
import '../presentation/cubit/auth_cubit.dart';

void registerAuth(GetIt sl) {
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => SupabaseAuthRemoteDataSource(sl<SupabaseService>()),
  );
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(sl<AuthRemoteDataSource>()),
  );

  sl.registerLazySingleton<SignUpUseCase>(
    () => SignUpUseCase(sl<AuthRepository>()),
  );
  sl.registerLazySingleton<SignInUseCase>(
    () => SignInUseCase(sl<AuthRepository>()),
  );
  sl.registerLazySingleton<SignOutUseCase>(
    () => SignOutUseCase(sl<AuthRepository>()),
  );
  sl.registerLazySingleton<GetCurrentProfileUseCase>(
    () => GetCurrentProfileUseCase(sl<AuthRepository>()),
  );
  sl.registerLazySingleton<UpdateProfileUseCase>(
    () => UpdateProfileUseCase(sl<AuthRepository>()),
  );

  sl.registerFactory<AuthCubit>(
    () => AuthCubit(
      signUpUseCase: sl<SignUpUseCase>(),
      signInUseCase: sl<SignInUseCase>(),
      signOutUseCase: sl<SignOutUseCase>(),
      getCurrentProfileUseCase: sl<GetCurrentProfileUseCase>(),
      updateProfileUseCase: sl<UpdateProfileUseCase>(),
    ),
  );
}
