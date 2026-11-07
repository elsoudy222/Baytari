/// Onboarding state: has the user seen onboarding, and are they
/// continuing as a guest?
///
/// Both flags are plain booleans (no loading state is needed: the
/// "seen" flag is read synchronously from SharedPreferences in the
/// Cubit's constructor, and "guest" only lives for this app run).
/// The state is immutable; every change goes through [copyWith].
library;

import 'package:equatable/equatable.dart';

class OnboardingState extends Equatable {
  const OnboardingState({this.seen = false, this.guestMode = false});

  /// True once onboarding was finished or skipped (persisted).
  final bool seen;

  /// True when the user chose "Join as a guest" (session only, not
  /// persisted — the next launch shows onboarding / get-started again
  /// unless the user signs in).
  final bool guestMode;

  OnboardingState copyWith({bool? seen, bool? guestMode}) {
    return OnboardingState(
      seen: seen ?? this.seen,
      guestMode: guestMode ?? this.guestMode,
    );
  }

  @override
  List<Object?> get props => <Object?>[seen, guestMode];
}
