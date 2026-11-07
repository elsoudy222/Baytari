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

class AuthState extends Equatable {
  const AuthState({
    this.status = AuthStatus.initial,
    this.profile,
    this.errorMessage,
  });

  final AuthStatus status;

  /// The signed-in user's profile. Null unless authenticated.
  final Profile? profile;

  /// Technical failure message from the last failed action, or null.
  /// Cleared on every new action and on every success.
  final String? errorMessage;

  /// Convenience: true only when the user is signed in.
  bool get isAuthenticated => status == AuthStatus.authenticated;

  AuthState copyWith({
    AuthStatus? status,
    Profile? profile,
    String? errorMessage,
    bool clearError = false,
    bool clearProfile = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      // `copyWith` cannot tell "set to null" from "not passed", so
      // the two boolean flags say explicitly when to clear a field.
      profile: clearProfile ? null : (profile ?? this.profile),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => <Object?>[status, profile, errorMessage];
}
