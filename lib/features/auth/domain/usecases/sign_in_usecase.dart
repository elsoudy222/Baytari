/// Use case: sign in with email + password.
///
/// One action, one repository call — see `SignUpUseCase` for the
/// pattern. Returns the signed-in user's [Profile] on success.
library;

import '../../../../core/errors/result.dart';
import '../entities/profile.dart';
import '../repositories/auth_repository.dart';

class SignInUseCase {
  const SignInUseCase(this._repository);

  final AuthRepository _repository;

  Future<Result<Profile>> call({
    required String email,
    required String password,
  }) {
    return _repository.signIn(email: email, password: password);
  }
}
