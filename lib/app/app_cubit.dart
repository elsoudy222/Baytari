/// App-level Cubit: theme mode + locale, persisted through
/// [AppSettingsService]. It contains no business logic and no API calls.
///
/// The pattern is the same one every feature Cubit will follow in M1+:
/// the Cubit owns a small state object ([AppState]), exposes one method
/// per user action, and talks only to services/use cases — never
/// directly to SharedPreferences, Dio, or Supabase.
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/services/app_settings_service.dart';
import '../core/services/supabase_service.dart';
import 'app_state.dart';
class AppCubit extends Cubit<AppState> {
  AppCubit(this._settings, this._supabase) : super(const AppState());

  final AppSettingsService _settings;
  final SupabaseService _supabase;

  /// Loads persisted settings (or the defaults: system theme, Arabic).
  ///
  /// `load()` is called once by `BaytariApp` right after the Cubit is
  /// created. It reads the saved values, then emits one new state with
  /// `copyWith` — the unchanged fields keep their current values, so
  /// `load()` never accidentally resets anything. The
  /// `supabaseConfigured` flag is read here (not stored) because it
  /// depends on the `--dart-define` keys given at launch, not on a
  /// saved preference.
  Future<void> load() async {
    emit(
      state.copyWith(
        themeMode: _settings.getThemeMode(),
        locale: _settings.getLocale(),
        supabaseConfigured: _supabase.isConfigured,
      ),
    );
  }

  /// Saves the new theme first, then emits it.
  ///
  /// Saving *before* emitting matters: if the app is killed right
  /// after the tap, the choice is already on disk, so the next launch
  /// restores it. The same save-then-emit order is used in [setLocale].
  Future<void> setThemeMode(ThemeMode mode) async {
    await _settings.setThemeMode(mode);
    emit(state.copyWith(themeMode: mode));
  }

  /// Saves the new locale first, then emits it (see [setThemeMode]).
  /// Changing the locale here rebuilds `MaterialApp` in `app.dart`,
  /// which swaps every string and flips the layout direction (RTL/LTR).
  Future<void> setLocale(Locale locale) async {
    await _settings.setLocale(locale);
    emit(state.copyWith(locale: locale));
  }
}
