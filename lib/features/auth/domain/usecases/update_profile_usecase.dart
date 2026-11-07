/// Use case: update the current user's profile (name / phone).
///
/// The role cannot be changed here on purpose: a user must not be
/// able to promote themselves from owner to vet by editing a form.
/// Role changes are an admin action for a later stage.
///
/// The extra optional fields exist for the sign-up wizard: after
/// the licence photo is uploaded, the wizard saves its storage
/// path (`licenseUrl`) on the profile through this same use case,
/// and the workplace note is saved the same way.
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
    String? username,
    String? avatarUrl,
    String? licenseUrl,
    String? workplaceNote,
  }) {
    return _repository.updateProfile(
      fullName: fullName,
      phone: phone,
      username: username,
      avatarUrl: avatarUrl,
      licenseUrl: licenseUrl,
      workplaceNote: workplaceNote,
    );
  }
}
