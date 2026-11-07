/// Use case: sign out the current user.
///
/// Clears the locally stored Supabase session. The next app launch
/// will find no session, so the user lands on the login screen.
library;

import '../../../../core/errors/result.dart';
import '../repositories/auth_repository.dart';

class SignOutUseCase {
  const SignOutUseCase(this._repository);

  final AuthRepository _repository;

  Future<Result<void>> call() {
    return _repository.signOut();
  }
}
