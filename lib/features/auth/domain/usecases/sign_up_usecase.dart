/// Use case: sign up a new user.
///
/// A use case is one single action, callable like a function
/// (`call(...)`), holding exactly one repository call. It contains
/// no UI, no Supabase, no Flutter — only the rule for this action.
/// The Cubit calls this, never the repository directly: that keeps
/// the Cubit thin and the business rule in one named place.
///
/// The `params` are named (not a separate params class) because
/// there are only a few of them and they are self-explanatory.
///
/// `workplaceNote` is the staff vet / shelter worker note ("works
/// at clinic/shelter X") — it travels in the auth metadata so the
/// profile row keeps it even when email confirmation delays the
/// row creation until the first sign-in.
library;

import '../../../../core/errors/result.dart';
import '../entities/profile.dart';
import '../entities/user_role.dart';
import '../repositories/auth_repository.dart';

class SignUpUseCase {
  const SignUpUseCase(this._repository);

  final AuthRepository _repository;

  Future<Result<Profile?>> call({
    required String email,
    required String password,
    required String fullName,
    required UserRole role,
    String? phone,
    String? workplaceNote,
  }) {
    return _repository.signUp(
      email: email,
      password: password,
      fullName: fullName,
      role: role,
      phone: phone,
      workplaceNote: workplaceNote,
    );
  }
}
