/// Use case: get the profile of the currently signed-in user.
///
/// Used once at startup (`AuthCubit.checkSession`) to restore the
/// session: Supabase persists the session on the device, so if this
/// returns a profile, the user is still logged in and goes straight
/// to Home; if it returns null, the user is sent to Login.
library;

import '../../../../core/errors/result.dart';
import '../entities/profile.dart';
import '../repositories/auth_repository.dart';

class GetCurrentProfileUseCase {
  const GetCurrentProfileUseCase(this._repository);

  final AuthRepository _repository;

  Future<Result<Profile?>> call() {
    return _repository.getCurrentProfile();
  }
}
