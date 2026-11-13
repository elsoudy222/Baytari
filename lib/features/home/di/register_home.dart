/// Home (feed) dependency registration (GetIt).
///
/// Registration order is dependency order — a service is
/// registered only after everything it needs already exists:
///   SupabaseService (core, already registered)
///     -> [HomeRemoteDataSource] (lazy singleton, one instance)
///     -> [HomeRepository] (lazy singleton, one instance)
///     -> use cases (lazy singletons, stateless, one each)
///     -> Cubits (factories: a new Cubit per screen — the feed,
///        the comments screen and the create screen each own
///        theirs, and close it when they are disposed).
///
/// Widgets and Cubits never create these themselves; they ask
/// GetIt (`sl<HomeFeedCubit>()`). That is what makes the feed
/// testable: tests register a fake [HomeRepository] instead of
/// the real one.
library;

import 'package:get_it/get_it.dart';

import '../../../../core/services/supabase_service.dart';
import '../data/datasources/home_remote_data_source.dart';
import '../data/datasources/supabase_home_remote_data_source.dart';
import '../data/repositories/home_repository_impl.dart';
import '../domain/repositories/home_repository.dart';
import '../domain/usecases/add_comment_usecase.dart';
import '../domain/usecases/create_report_usecase.dart';
import '../domain/usecases/get_comments_usecase.dart';
import '../domain/usecases/get_report_usecase.dart';
import '../domain/usecases/get_reports_usecase.dart';
import '../domain/usecases/set_report_status_usecase.dart';
import '../domain/usecases/toggle_comment_like_usecase.dart';
import '../domain/usecases/toggle_helper_usecase.dart';
import '../presentation/cubit/create_report_cubit.dart';
import '../presentation/cubit/home_feed_cubit.dart';
import '../presentation/cubit/report_comments_cubit.dart';

void registerHome(GetIt sl) {
  sl.registerLazySingleton<HomeRemoteDataSource>(
    () => SupabaseHomeRemoteDataSource(sl<SupabaseService>()),
  );
  sl.registerLazySingleton<HomeRepository>(
    () => HomeRepositoryImpl(sl<HomeRemoteDataSource>()),
  );

  sl.registerLazySingleton<GetReportsUseCase>(
    () => GetReportsUseCase(sl<HomeRepository>()),
  );
  sl.registerLazySingleton<GetReportUseCase>(
    () => GetReportUseCase(sl<HomeRepository>()),
  );
  sl.registerLazySingleton<CreateReportUseCase>(
    () => CreateReportUseCase(sl<HomeRepository>()),
  );
  sl.registerLazySingleton<ToggleHelperUseCase>(
    () => ToggleHelperUseCase(sl<HomeRepository>()),
  );
  sl.registerLazySingleton<SetReportStatusUseCase>(
    () => SetReportStatusUseCase(sl<HomeRepository>()),
  );
  sl.registerLazySingleton<GetCommentsUseCase>(
    () => GetCommentsUseCase(sl<HomeRepository>()),
  );
  sl.registerLazySingleton<AddCommentUseCase>(
    () => AddCommentUseCase(sl<HomeRepository>()),
  );
  sl.registerLazySingleton<ToggleCommentLikeUseCase>(
    () => ToggleCommentLikeUseCase(sl<HomeRepository>()),
  );

  sl.registerFactory<HomeFeedCubit>(
    () => HomeFeedCubit(
      getReportsUseCase: sl<GetReportsUseCase>(),
      toggleHelperUseCase: sl<ToggleHelperUseCase>(),
      setReportStatusUseCase: sl<SetReportStatusUseCase>(),
    ),
  );
  sl.registerFactory<ReportCommentsCubit>(
    () => ReportCommentsCubit(
      getReportUseCase: sl<GetReportUseCase>(),
      getCommentsUseCase: sl<GetCommentsUseCase>(),
      addCommentUseCase: sl<AddCommentUseCase>(),
      toggleCommentLikeUseCase: sl<ToggleCommentLikeUseCase>(),
      setReportStatusUseCase: sl<SetReportStatusUseCase>(),
    ),
  );
  sl.registerFactory<CreateReportCubit>(
    () => CreateReportCubit(
      createReportUseCase: sl<CreateReportUseCase>(),
    ),
  );
}
