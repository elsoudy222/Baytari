/// Use case: set the username and avatar on the current profile.
///
/// The sign-up "Welcome To Baytari!" step: the user picks a
/// username (unique in the database) and optionally a profile
/// photo (already uploaded to the `avatars` bucket — this use case
/// only stores the URL). Either field may be omitted; the other is
/// still saved. A taken username fails with a server failure —
/// the UI tells the user to pick another one.
library;

import '../../../../core/errors/result.dart';
import '../entities/profile.dart';
import '../repositories/auth_repository.dart';

class UpdateUsernameAndAvatarUseCase {
  const UpdateUsernameAndAvatarUseCase(this._repository);

  final AuthRepository _repository;

  Future<Result<Profile>> call({String? username, String? avatarUrl}) {
    return _repository.updateUsernameAndAvatar(
      username: username,
      avatarUrl: avatarUrl,
    );
  }
}
