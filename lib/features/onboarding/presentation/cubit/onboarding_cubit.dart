/// Onboarding Cubit: remembers that onboarding was seen, and tracks
/// guest mode for this app run.
///
/// The Cubit owns no UI and makes no API calls. It talks only to
/// [AppSettingsService] (SharedPreferences, via GetIt) — the same
/// service [AppCubit] uses for theme and language. The "seen" flag is
/// read synchronously in the constructor, so the splash screen can
/// decide immediately whether to show onboarding, with no loading
/// flash. `markSeen()` saves first, then emits (same save-then-emit
/// order as `AppCubit.setThemeMode`); `continueAsGuest()` only
/// changes the in-memory state, so guest mode is never persisted
/// and never creates any account.
library;

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/services/app_settings_service.dart';
import 'onboarding_state.dart';

class OnboardingCubit extends Cubit<OnboardingState> {
  OnboardingCubit(this._settings)
    : super(OnboardingState(seen: _settings.getOnboardingSeen()));

  final AppSettingsService _settings;

  /// Persists "onboarding seen", then emits the new state.
  Future<void> markSeen() async {
    await _settings.setOnboardingSeen();
    emit(state.copyWith(seen: true));
  }

  /// Continue without signing in. Session only: nothing is saved,
  /// and no guest account is created in Supabase.
  void continueAsGuest() {
    emit(state.copyWith(guestMode: true));
  }
}
