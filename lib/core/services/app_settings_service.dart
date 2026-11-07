import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';

/// Persists app-level settings (theme mode + locale) in SharedPreferences.
///
/// This is the only class that talks to SharedPreferences for these two
/// settings. [AppCubit] depends on this service, never on
/// SharedPreferences directly.
///
/// Storage format is deliberately boring: the theme is saved as the
/// enum name (`'light'` / `'dark'` / `'system'`) and the locale as its
/// language code (`'ar'` / `'en'`). Plain strings survive app updates,
/// and an unknown saved value safely falls back to the default instead
/// of crashing (see the `_` branch in [getThemeMode]).
class AppSettingsService {
  AppSettingsService(this._prefs);

  final SharedPreferences _prefs;

  /// Reads the saved theme. The `switch` has a `_` (default) branch on
  /// purpose: if the stored string is missing or unknown (e.g. from an
  /// older app version), the app falls back to the system theme.
  ThemeMode getThemeMode() {
    final String? raw = _prefs.getString(AppConstants.themeModeKey);
    return switch (raw) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  Future<bool> setThemeMode(ThemeMode mode) {
    return _prefs.setString(AppConstants.themeModeKey, mode.name);
  }

  /// Reads the saved locale. An unknown or missing code falls back to
  /// the default locale (Arabic) — the app always has a valid locale.
  Locale getLocale() {
    final String? code = _prefs.getString(AppConstants.localeCodeKey);
    if (code != null &&
        AppConstants.supportedLanguageCodes.contains(code)) {
      return Locale(code);
    }
    return AppConstants.defaultLocale;
  }

  Future<bool> setLocale(Locale locale) {
    return _prefs.setString(AppConstants.localeCodeKey, locale.languageCode);
  }
}
