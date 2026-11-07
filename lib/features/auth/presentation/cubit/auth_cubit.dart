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
import '../../domain/usecases/sign_in_usecase.dart';
import '../../domain/usecases/sign_out_usecase.dart';
import '../../domain/usecases/sign_up_usecase.dart';
import '../../domain/usecases/update_profile_usecase.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit({
    required this._signUpUseCase,
    required this._signInUseCase,
    required this._signOutUseCase,
    required this._getCurrentProfileUseCase,
    required this._updateProfileUseCase,
  }) : super(const AuthState());

  final SignUpUseCase _signUpUseCase;
  final SignInUseCase _signInUseCase;
  final SignOutUseCase _signOutUseCase;
  final GetCurrentProfileUseCase _getCurrentProfileUseCase;
  final UpdateProfileUseCase _updateProfileUseCase;

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
  }) async {
    emit(state.copyWith(status: AuthStatus.loading, clearError: true));
    final Result<Profile?> result = await _signUpUseCase(
      email: email,
      password: password,
      fullName: fullName,
      role: role,
      phone: phone,
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
  }) async {
    emit(state.copyWith(status: AuthStatus.loading, clearError: true));
    final Result<Profile> result = await _updateProfileUseCase(
      fullName: fullName,
      phone: phone,
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
}
