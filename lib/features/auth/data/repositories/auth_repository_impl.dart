/// The auth repository IMPLEMENTATION (data layer).
///
/// Implements the domain contract [AuthRepository] by delegating to
/// the [AuthRemoteDataSource]. Its only other job is error mapping:
/// data-source exceptions become domain [Failure]s, wrapped in a
/// [Result], so Cubits and use cases never see a Supabase/Dio type.
///
/// Mapping table:
/// - [AuthException]            -> [AuthFailure] (wrong password,
///   email already registered, ...)
/// - [SupabaseNotConfiguredException] -> [NotConfiguredFailure]
///   (app started without --dart-define keys; demo mode)
/// - [ServerException] / anything else -> [ServerFailure]
///
/// `Result<void>` for sign-out uses `Success(null)`: `void` has no
/// value, so the success case carries null — the caller only checks
/// `isSuccess`.
library;

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result.dart';
import '../../domain/entities/profile.dart';
import '../../domain/entities/user_role.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';
import '../models/profile_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._remoteDataSource);

  final AuthRemoteDataSource _remoteDataSource;

  @override
  Future<Result<Profile?>> signUp({
    required String email,
    required String password,
    required String fullName,
    required UserRole role,
    String? phone,
  }) async {
    try {
      final ProfileModel? profile = await _remoteDataSource.signUp(
        email: email,
        password: password,
        fullName: fullName,
        role: role,
        phone: phone,
      );
      return Success<Profile?>(profile);
    } on AppException catch (e) {
      return FailureResult<Profile?>(_mapException(e));
    }
  }

  @override
  Future<Result<Profile>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final ProfileModel profile = await _remoteDataSource.signIn(
        email: email,
        password: password,
      );
      return Success<Profile>(profile);
    } on AppException catch (e) {
      return FailureResult<Profile>(_mapException(e));
    }
  }

  @override
  Future<Result<void>> signOut() async {
    try {
      await _remoteDataSource.signOut();
      return const Success<void>(null);
    } on AppException catch (e) {
      return FailureResult<void>(_mapException(e));
    }
  }

  @override
  Future<Result<Profile?>> getCurrentProfile() async {
    try {
      final ProfileModel? profile = await _remoteDataSource
          .getCurrentProfile();
      return Success<Profile?>(profile);
    } on AppException catch (e) {
      return FailureResult<Profile?>(_mapException(e));
    }
  }

  @override
  Future<Result<Profile>> updateProfile({
    required String fullName,
    String? phone,
  }) async {
    try {
      final ProfileModel profile = await _remoteDataSource.updateProfile(
        fullName: fullName,
        phone: phone,
      );
      return Success<Profile>(profile);
    } on AppException catch (e) {
      return FailureResult<Profile>(_mapException(e));
    }
  }

  /// One mapping function for all five methods, so the mapping can
  /// never drift between them: the same exception always means the
  /// same failure, whichever action triggered it.
  Failure _mapException(AppException exception) {
    return switch (exception) {
      AuthException(:final message) => AuthFailure(message),
      SupabaseNotConfiguredException(:final message) =>
        NotConfiguredFailure(message),
      _ => ServerFailure(exception.message),
    };
  }
}
