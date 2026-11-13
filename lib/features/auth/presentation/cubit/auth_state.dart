/// Auth state: one status, the signed-in profile (if any), and the
/// last error message (technical text, for logging — the UI shows a
/// localized message, never this string directly).
///
/// The state is immutable; every change goes through [copyWith].
/// [Equatable] compares the fields, so emitting an identical state
/// does nothing and `BlocBuilder` rebuilds only on real change.
library;

import 'package:equatable/equatable.dart';

import '../../domain/entities/profile.dart';

/// The auth lifecycle. `initial` is "we have not checked yet"
/// (before `checkSession` finishes); `awaitingConfirmation` means
/// the account exists but the user must confirm their email before
/// they can sign in — the register screen shows the "check your
/// email" message in that case.
enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  awaitingConfirmation,
}

/// A one-shot result of the last auth action, so a screen can
/// react exactly once (e.g. the sign-up wizard advances to the
/// next step when `otpVerified` arrives, the forgot-password flow
/// advances when `otpSent` arrives). It is reset to `none` on
/// every new action and on every success that sets a status.
enum AuthAction {
  none,
  otpSent,
  otpVerified,
  passwordReset,
  profileCompleted,
  licenseUploaded,
}

class AuthState extends Equatable {
  const AuthState({
    this.status = AuthStatus.initial,
    this.profile,
    this.errorMessage,
    this.action = AuthAction.none,
    this.profileCompleted = false,
  });

  final AuthStatus status;

  /// The signed-in user's profile. Null unless authenticated.
  final Profile? profile;

  /// Technical failure message from the last failed action, or null.
  /// Cleared on every new action and on every success.
  final String? errorMessage;

  /// The last completed action (see [AuthAction]).
  final AuthAction action;

  /// True once the sign-up wizard has run to the end (the user saw
  /// the confirmation screen and tapped "Go to Home").
  ///
  /// This is what the router guard reads — NOT `profile.username`:
  /// the wizard emits `authenticated` mid-flow (OTP verified,
  /// username saved) while it is still on `/register`, and the
  /// confirmation screen itself lives on `/register`. If the guard
  /// used the username, it would redirect the user to Home before
  /// they ever saw the confirmation screen. So the flag stays
  /// false through the whole wizard and is set only by
  /// [AuthCubit.markProfileCompleted], which the register screen
  /// calls when the user leaves the confirmation step.
  ///
  /// For a restored session / sign-in there is no live wizard, so
  /// the Cubit derives the flag from the stored profile instead:
  /// a profile that already has a username finished the wizard in
  /// a past session (see `AuthCubit._hasCompletedProfile`).
  final bool profileCompleted;

  /// Convenience: true only when the user is signed in.
  bool get isAuthenticated => status == AuthStatus.authenticated;

  AuthState copyWith({
    AuthStatus? status,
    Profile? profile,
    String? errorMessage,
    AuthAction? action,
    bool? profileCompleted,
    bool clearError = false,
    bool clearProfile = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      // `copyWith` cannot tell "set to null" from "not passed", so
      // the two boolean flags say explicitly when to clear a field.
      profile: clearProfile ? null : (profile ?? this.profile),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      action: action ?? this.action,
      profileCompleted: profileCompleted ?? this.profileCompleted,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    status,
    profile,
    errorMessage,
    action,
    profileCompleted,
  ];
}
