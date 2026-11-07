/// Use case: upload an avatar photo to the public `avatars`
/// Storage bucket.
///
/// The sign-up "Welcome To Baytari!" step: the user picks a
/// profile photo, this uploads the JPEG bytes and returns the
/// public URL. The URL is stored on the profile as `avatar_url`
/// by the caller (via `UpdateUsernameAndAvatarUseCase`); this use
/// case only uploads, so the wizard can retry the photo without
/// touching the profile row.
library;

import '../../../../core/errors/result.dart';
import '../repositories/auth_repository.dart';

class UploadAvatarUseCase {
  const UploadAvatarUseCase(this._repository);

  final AuthRepository _repository;

  Future<Result<String>> call(List<int> bytes) {
    return _repository.uploadAvatar(bytes);
  }
}
