import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';

/// Persists app-level settings (theme mode + locale) in SharedPreferences.
///
/// This is the only class that talks to SharedPreferences for these two
/// settings. [AppCubit] depends on this service, never on
/// SharedPreferences directly.
class AppSettingsService {
  AppSettingsService(this._prefs);

  final SharedPreferences _prefs;

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
