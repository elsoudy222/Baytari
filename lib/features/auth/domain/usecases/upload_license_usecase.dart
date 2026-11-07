/// Use case: upload a licence photo to the private `licenses`
/// Storage bucket.
///
/// The sign-up "Verify Your License" step (vet / shelter): the
/// user photographs their licence, this uploads the JPEG bytes
/// and returns the storage path. The path is stored on the
/// profile as `license_url` by the caller (via `updateProfile`);
/// this use case only uploads, so the wizard can retry the photo
/// ("Retake") without touching the profile row.
library;

import '../../../../core/errors/result.dart';
import '../repositories/auth_repository.dart';

class UploadLicenseUseCase {
  const UploadLicenseUseCase(this._repository);

  final AuthRepository _repository;

  Future<Result<String>> call(List<int> bytes) {
    return _repository.uploadLicense(bytes);
  }
}
