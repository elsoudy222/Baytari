import 'package:flutter/material.dart';

/// App-wide constants. No user-facing text lives here — all visible
/// strings are in the ARB files under `core/localization/l10n`.
abstract final class AppConstants {
  static const String appName = 'Baytari';

  /// Default locale on first run (user-confirmed: Arabic).
  static const Locale defaultLocale = Locale('ar');

  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  static const List<String> supportedLanguageCodes = <String>['ar', 'en'];

  // SharedPreferences keys.
  static const String themeModeKey = 'baytari_theme_mode';
  static const String localeCodeKey = 'baytari_locale_code';
}
