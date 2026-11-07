/// Use case: update the current user's profile (name / phone).
///
/// The role cannot be changed here on purpose: a user must not be
/// able to promote themselves from owner to vet by editing a form.
/// Role changes are an admin action for a later stage.
library;

import '../../../../core/errors/result.dart';
import '../entities/profile.dart';
import '../repositories/auth_repository.dart';

class UpdateProfileUseCase {
  const UpdateProfileUseCase(this._repository);

  final AuthRepository _repository;

  Future<Result<Profile>> call({
    required String fullName,
    String? phone,
  }) {
    return _repository.updateProfile(fullName: fullName, phone: phone);
  }
}
