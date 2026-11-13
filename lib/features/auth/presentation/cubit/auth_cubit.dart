/// The auth Cubit: the single source of truth for "who is signed in".
///
/// Pattern (same as [AppCubit]): one method per user action, each
/// method emits Loading, calls exactly one use case, then emits the
/// result as a new state. The Cubit never touches Supabase, Dio, or
/// a repository implementation — it only knows the five use cases,
/// which is why it is unit-testable with a fake repository.
///
/// One [AuthCubit] lives for the whole app (created once in
/// `BaytariApp` and provided to the whole widget tree): the auth
/// session is app-wide, not per-screen, so every screen reads the
/// same state. The router's redirect also reads this Cubit, so a
/// sign-in / sign-out immediately re-routes the user.
///
/// Error handling: a failed action emits `unauthenticated` (or
/// keeps the previous state for updateProfile) plus `errorMessage`.
/// The UI shows a localized generic message; `errorMessage` is the
/// technical detail, kept for logging/debugging.
library;

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/result.dart';
import '../../domain/entities/profile.dart';
import '../../domain/entities/user_role.dart';
import '../../domain/usecases/get_current_profile_usecase.dart';
import '../../domain/usecases/request_otp_usecase.dart';
import '../../domain/usecases/reset_password_usecase.dart';
import '../../domain/usecases/sign_in_usecase.dart';
import '../../domain/usecases/sign_out_usecase.dart';
import '../../domain/usecases/sign_up_usecase.dart';
import '../../domain/usecases/update_profile_usecase.dart';
import '../../domain/usecases/update_username_and_avatar_usecase.dart';
import '../../domain/usecases/upload_avatar_usecase.dart';
import '../../domain/usecases/upload_license_usecase.dart';
import '../../domain/usecases/verify_otp_usecase.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit({
    required this._signUpUseCase,
    required this._signInUseCase,
    required this._signOutUseCase,
    required this._getCurrentProfileUseCase,
    required this._updateProfileUseCase,
    required this._requestOtpUseCase,
    required this._verifyOtpUseCase,
    required this._resetPasswordUseCase,
    required this._updateUsernameAndAvatarUseCase,
    required this._uploadLicenseUseCase,
    required this._uploadAvatarUseCase,
  }) : super(const AuthState());

  final SignUpUseCase _signUpUseCase;
  final SignInUseCase _signInUseCase;
  final SignOutUseCase _signOutUseCase;
  final GetCurrentProfileUseCase _getCurrentProfileUseCase;
  final UpdateProfileUseCase _updateProfileUseCase;
  final RequestOtpUseCase _requestOtpUseCase;
  final VerifyOtpUseCase _verifyOtpUseCase;
  final ResetPasswordUseCase _resetPasswordUseCase;
  final UpdateUsernameAndAvatarUseCase _updateUsernameAndAvatarUseCase;
  final UploadLicenseUseCase _uploadLicenseUseCase;
  final UploadAvatarUseCase _uploadAvatarUseCase;

  /// Clears a one-shot [AuthAction] after the screen handled it,
  /// so the same action is never delivered twice.
  void clearAction() {
    if (state.action != AuthAction.none) {
      emit(state.copyWith(action: AuthAction.none));
    }
  }

  /// A stored profile counts as "wizard-complete" when it has a
  /// username: the username step is the last data the wizard
  /// collects, so a stored username means the wizard ran to the
  /// end in a past session. Used ONLY when restoring a session or
  /// signing in — during a live wizard run the flag stays false
  /// until [markProfileCompleted] (see [AuthState.profileCompleted]),
  /// because deriving it from the profile there would redirect the
  /// user away from the confirmation screen.
  static bool _hasCompletedProfile(Profile? profile) {
    final String? username = profile?.username;
    return username != null && username.isNotEmpty;
  }

  /// Marks the sign-up wizard as finished. Called by the register
  /// screen when the user leaves the confirmation step ("Go to
  /// Home"): only then may the router guard send a signed-in user
  /// away from `/register`. It is deliberately NOT set by
  /// [completeProfile] — the confirmation screen itself lives on
  /// `/register`, so setting it there would redirect the user to
  /// Home before they ever saw it.
  void markProfileCompleted() {
    if (!state.profileCompleted) {
      emit(state.copyWith(profileCompleted: true));
    }
  }

  /// Restores the session at startup. Called once by `BaytariApp`.
  /// Supabase persists the session on the device, so a returning
  /// user is authenticated again without typing a password.
  Future<void> checkSession() async {
    emit(state.copyWith(status: AuthStatus.loading, clearError: true));
    final Result<Profile?> result = await _getCurrentProfileUseCase();
    switch (result) {
      case Success(:final value):
        if (value == null) {
          emit(
            state.copyWith(
              status: AuthStatus.unauthenticated,
              clearProfile: true,
              clearError: true,
            ),
          );
        } else {
          emit(
            state.copyWith(
              status: AuthStatus.authenticated,
              profile: value,
              // No live wizard on a session restore: the stored
              // profile tells whether the wizard finished before.
              profileCompleted: _hasCompletedProfile(value),
              clearError: true,
            ),
          );
        }
      case FailureResult(:final failure):
        emit(
          state.copyWith(
            status: AuthStatus.unauthenticated,
            clearProfile: true,
            errorMessage: failure.message,
          ),
        );
    }
  }

  /// Creates the account. On success with a session the user is
  /// authenticated immediately; when email confirmation is ON the
  /// use case returns a null profile, and the state becomes
  /// `awaitingConfirmation` so the register screen can tell the
  /// user to check their email.
  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
    required UserRole role,
    String? phone,
    String? workplaceNote,
  }) async {
    emit(
      state.copyWith(
        status: AuthStatus.loading,
        clearError: true,
        action: AuthAction.none,
      ),
    );
    final Result<Profile?> result = await _signUpUseCase(
      email: email,
      password: password,
      fullName: fullName,
      role: role,
      phone: phone,
      workplaceNote: workplaceNote,
    );
    switch (result) {
      case Success(:final value):
        if (value == null) {
          emit(
            state.copyWith(
              status: AuthStatus.awaitingConfirmation,
              clearError: true,
            ),
          );
        } else {
          emit(
            state.copyWith(
              status: AuthStatus.authenticated,
              profile: value,
              // The wizard just started (confirmation OFF): the
              // licence / username steps still lie ahead.
              profileCompleted: false,
              clearError: true,
            ),
          );
        }
      case FailureResult(:final failure):
        emit(
          state.copyWith(
            status: AuthStatus.unauthenticated,
            errorMessage: failure.message,
          ),
        );
    }
  }

  /// Signs in with email + password.
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    emit(state.copyWith(status: AuthStatus.loading, clearError: true));
    final Result<Profile> result = await _signInUseCase(
      email: email,
      password: password,
    );
    switch (result) {
      case Success(:final value):
        emit(
          state.copyWith(
            status: AuthStatus.authenticated,
            profile: value,
            // A returning user signing in: the stored profile tells
            // whether the wizard finished in a past session.
            profileCompleted: _hasCompletedProfile(value),
            clearError: true,
          ),
        );
      case FailureResult(:final failure):
        emit(
          state.copyWith(
            status: AuthStatus.unauthenticated,
            errorMessage: failure.message,
          ),
        );
    }
  }

  /// Signs out and returns to the unauthenticated state. The router
  /// redirect (listening to this Cubit's stream) then sends the
  /// user to the login screen.
  Future<void> signOut() async {
    emit(state.copyWith(status: AuthStatus.loading, clearError: true));
    final Result<void> result = await _signOutUseCase();
    switch (result) {
      case Success():
        emit(
          state.copyWith(
            status: AuthStatus.unauthenticated,
            clearProfile: true,
            clearError: true,
          ),
        );
      case FailureResult(:final failure):
        // Sign-out failed: stay authenticated, the profile is
        // still valid — the user can retry from the profile screen.
        emit(
          state.copyWith(
            status: AuthStatus.authenticated,
            errorMessage: failure.message,
          ),
        );
    }
  }

  /// Updates the profile (name / phone). On success the state
  /// holds the new profile so every screen shows it immediately;
  /// on failure the old profile stays and the error is shown.
  Future<void> updateProfile({
    required String fullName,
    String? phone,
    String? username,
    String? avatarUrl,
    String? licenseUrl,
    String? workplaceNote,
  }) async {
    emit(state.copyWith(status: AuthStatus.loading, clearError: true));
    final Result<Profile> result = await _updateProfileUseCase(
      fullName: fullName,
      phone: phone,
      username: username,
      avatarUrl: avatarUrl,
      licenseUrl: licenseUrl,
      workplaceNote: workplaceNote,
    );
    switch (result) {
      case Success(:final value):
        emit(
          state.copyWith(
            status: AuthStatus.authenticated,
            profile: value,
            clearError: true,
          ),
        );
      case FailureResult(:final failure):
        emit(
          state.copyWith(
            status: AuthStatus.authenticated,
            errorMessage: failure.message,
          ),
        );
    }
  }

  /// Sends the sign-up OTP code to [email]. Emits `otpSent` on
  /// success so the wizard advances to the code boxes; on failure
  /// the wizard stays and shows the error.
  Future<void> requestSignupOtp({required String email}) async {
    await _requestOtp(email: email, purpose: OtpPurpose.signup);
  }

  /// Sends the password-recovery OTP code to [email].
  Future<void> requestPasswordReset({required String email}) async {
    await _requestOtp(email: email, purpose: OtpPurpose.recovery);
  }

  /// Shared OTP-request logic for both purposes: loading, one use
  /// case call, then `otpSent` or the error.
  Future<void> _requestOtp({
    required String email,
    required OtpPurpose purpose,
  }) async {
    emit(
      state.copyWith(
        status: AuthStatus.loading,
        clearError: true,
        action: AuthAction.none,
      ),
    );
    final Result<void> result = await _requestOtpUseCase(
      email: email,
      purpose: purpose,
    );
    switch (result) {
      case Success():
        emit(
          state.copyWith(
            status: AuthStatus.unauthenticated,
            action: AuthAction.otpSent,
            clearError: true,
          ),
        );
      case FailureResult(:final failure):
        emit(
          state.copyWith(
            status: AuthStatus.unauthenticated,
            errorMessage: failure.message,
          ),
        );
    }
  }

  /// Verifies the sign-up OTP. On success the user is signed in
  /// (profile in state) and the wizard advances to the
  /// username/photo step. A wrong code emits `unauthenticated`
  /// with the error — the wizard shows the red "Wrong Code" state.
  Future<void> verifySignupOtp({
    required String email,
    required String token,
  }) async {
    emit(
      state.copyWith(
        status: AuthStatus.loading,
        clearError: true,
        action: AuthAction.none,
      ),
    );
    final Result<Profile?> result = await _verifyOtpUseCase(
      email: email,
      token: token,
      purpose: OtpPurpose.signup,
    );
    switch (result) {
      case Success(:final value):
        emit(
          state.copyWith(
            status: AuthStatus.authenticated,
            profile: value,
            action: AuthAction.otpVerified,
            // The wizard continues to the username step — the
            // profile is not complete yet.
            profileCompleted: false,
            clearError: true,
          ),
        );
      case FailureResult(:final failure):
        emit(
          state.copyWith(
            status: AuthStatus.unauthenticated,
            errorMessage: failure.message,
          ),
        );
    }
  }

  /// Verifies the recovery OTP. On success the user holds a
  /// recovery session and the forgot-password flow advances to
  /// the new-password step.
  Future<void> verifyRecoveryOtp({
    required String email,
    required String token,
  }) async {
    emit(
      state.copyWith(
        status: AuthStatus.loading,
        clearError: true,
        action: AuthAction.none,
      ),
    );
    final Result<Profile?> result = await _verifyOtpUseCase(
      email: email,
      token: token,
      purpose: OtpPurpose.recovery,
    );
    switch (result) {
      case Success():
        emit(
          state.copyWith(
            status: AuthStatus.unauthenticated,
            action: AuthAction.otpVerified,
            clearError: true,
          ),
        );
      case FailureResult(:final failure):
        emit(
          state.copyWith(
            status: AuthStatus.unauthenticated,
            errorMessage: failure.message,
          ),
        );
    }
  }

  /// Sets the new password (recovery session required) and signs
  /// out. Emits `passwordReset` so the flow shows the success
  /// screen, which sends the user to log in.
  Future<void> resetPassword({required String newPassword}) async {
    emit(
      state.copyWith(
        status: AuthStatus.loading,
        clearError: true,
        action: AuthAction.none,
      ),
    );
    final Result<void> result = await _resetPasswordUseCase(
      newPassword: newPassword,
    );
    switch (result) {
      case Success():
        emit(
          state.copyWith(
            status: AuthStatus.unauthenticated,
            clearProfile: true,
            action: AuthAction.passwordReset,
            clearError: true,
          ),
        );
      case FailureResult(:final failure):
        emit(
          state.copyWith(
            status: AuthStatus.unauthenticated,
            errorMessage: failure.message,
          ),
        );
    }
  }

  /// Saves the username and avatar URL picked on the sign-up
  /// "Welcome To Baytari!" step. Emits `profileCompleted` so the
  /// wizard advances to the confirmation screen.
  Future<void> completeProfile({
    String? username,
    String? avatarUrl,
  }) async {
    emit(
      state.copyWith(
        status: AuthStatus.loading,
        clearError: true,
        action: AuthAction.none,
      ),
    );
    final Result<Profile> result = await _updateUsernameAndAvatarUseCase(
      username: username,
      avatarUrl: avatarUrl,
    );
    switch (result) {
      case Success(:final value):
        emit(
          state.copyWith(
            status: AuthStatus.authenticated,
            profile: value,
            action: AuthAction.profileCompleted,
            // Deliberately still false: the confirmation screen
            // lives on `/register`, and only the wizard itself may
            // mark the profile complete (see [markProfileCompleted]).
            profileCompleted: false,
            clearError: true,
          ),
        );
      case FailureResult(:final failure):
        emit(
          state.copyWith(
            status: AuthStatus.authenticated,
            errorMessage: failure.message,
          ),
        );
    }
  }

  /// Uploads a licence photo and returns its storage path (or
  /// null on failure, with the error in state). The wizard then
  /// saves the path on the profile via [updateProfile].
  Future<String?> uploadLicense(List<int> bytes) async {
    emit(
      state.copyWith(
        status: AuthStatus.loading,
        clearError: true,
        action: AuthAction.none,
      ),
    );
    final Result<String> result = await _uploadLicenseUseCase(bytes);
    switch (result) {
      case Success(:final value):
        emit(
          state.copyWith(
            status: AuthStatus.authenticated,
            action: AuthAction.licenseUploaded,
            clearError: true,
          ),
        );
        return value;
      case FailureResult(:final failure):
        emit(
          state.copyWith(
            status: AuthStatus.authenticated,
            errorMessage: failure.message,
          ),
        );
        return null;
    }
  }

  /// Uploads an avatar photo and returns its public URL (or null
  /// on failure, with the error in state). The wizard then saves
  /// the URL on the profile via [completeProfile].
  Future<String?> uploadAvatar(List<int> bytes) async {
    emit(
      state.copyWith(
        status: AuthStatus.loading,
        clearError: true,
        action: AuthAction.none,
      ),
    );
    final Result<String> result = await _uploadAvatarUseCase(bytes);
    switch (result) {
      case Success(:final value):
        emit(
          state.copyWith(
            status: AuthStatus.authenticated,
            clearError: true,
          ),
        );
        return value;
      case FailureResult(:final failure):
        emit(
          state.copyWith(
            status: AuthStatus.authenticated,
            errorMessage: failure.message,
          ),
        );
        return null;
    }
  }
}
