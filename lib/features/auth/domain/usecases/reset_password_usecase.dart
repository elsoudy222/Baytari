/// Use case: set the new password after a verified recovery OTP.
///
/// The recovery session (from [VerifyOtpUseCase] with
/// `OtpPurpose.recovery`) is what authorizes this call — Supabase
/// only lets a user change their own password while that session
/// is active. The repository also signs the user out afterwards,
/// so the Figma success screen can send them to log in with the
/// new password.
library;

import '../../../../core/errors/result.dart';
import '../repositories/auth_repository.dart';

class ResetPasswordUseCase {
  const ResetPasswordUseCase(this._repository);

  final AuthRepository _repository;

  Future<Result<void>> call({required String newPassword}) {
    return _repository.resetPassword(newPassword: newPassword);
  }
}
