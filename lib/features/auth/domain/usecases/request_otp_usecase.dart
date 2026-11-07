/// Use case: send an email OTP (one action, one repository call).
///
/// Two flavours share this use case — the [OtpPurpose] says which:
/// - [OtpPurpose.signup]: the code that verifies a just-created
///   account (sign-up wizard, after `signUp` returned "awaiting
///   confirmation").
/// - [OtpPurpose.recovery]: the code that starts a password reset
///   (forgot-password flow).
///
/// Both send the code to EMAIL only. Phone OTP needs an SMS
/// provider and is out of v1 — see the Arabic doc. The repository
/// sends with `shouldCreateUser: false`, so an unknown email fails
/// instead of silently creating an account.
library;

import '../../../../core/errors/result.dart';
import '../repositories/auth_repository.dart';

/// Which OTP flow the code is for — signup verification or
/// password recovery. The repository maps this to the matching
/// Supabase `OtpType` (`signup` / `recovery`).
enum OtpPurpose { signup, recovery }

class RequestOtpUseCase {
  const RequestOtpUseCase(this._repository);

  final AuthRepository _repository;

  Future<Result<void>> call({
    required String email,
    required OtpPurpose purpose,
  }) {
    return switch (purpose) {
      OtpPurpose.signup => _repository.requestSignupOtp(email: email),
      OtpPurpose.recovery => _repository.requestPasswordReset(
        email: email,
      ),
    };
  }
}
