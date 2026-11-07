/// Use case: verify a 6-digit email OTP.
///
/// - [OtpPurpose.signup]: verifies the sign-up code and signs the
///   user in, returning the profile (created on first sign-in).
/// - [OtpPurpose.recovery]: verifies the reset code; the user then
///   holds a recovery session and may set a new password
///   ([ResetPasswordUseCase]).
///
/// A wrong code fails with [AuthFailure] — the UI shows the red
/// "Wrong Code" state from the Figma OTP screen.
library;

import '../../../../core/errors/result.dart';
import '../entities/profile.dart';
import '../repositories/auth_repository.dart';
import 'request_otp_usecase.dart';

class VerifyOtpUseCase {
  const VerifyOtpUseCase(this._repository);

  final AuthRepository _repository;

  Future<Result<Profile?>> call({
    required String email,
    required String token,
    required OtpPurpose purpose,
  }) {
    return switch (purpose) {
      OtpPurpose.signup => _repository.verifySignupOtp(
        email: email,
        token: token,
      ),
      // Recovery verification returns no profile — the recovery
      // session is the result, so the success value is null.
      OtpPurpose.recovery => _repository
          .verifyRecoveryOtp(email: email, token: token)
          .then((Result<void> result) {
            return switch (result) {
              Success() => const Success<Profile?>(null),
              FailureResult(:final failure) =>
                FailureResult<Profile?>(failure),
            };
          }),
    };
  }
}
