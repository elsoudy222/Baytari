/// App-wide constants. No user-facing text lives here — all visible
/// strings are in the ARB files under `core/localization/l10n`.
///
/// `abstract final class` is used on purpose: the class can never be
/// instantiated and never subclassed, it is only a namespace for
/// `static const` values.
library;

import 'package:flutter/material.dart';

abstract final class AppConstants {
  static const String appName = 'Baytari';

  /// Default locale on first run (user-confirmed: Arabic).
  static const Locale defaultLocale = Locale('ar');

  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  static const List<String> supportedLanguageCodes = <String>['ar', 'en'];

  // SharedPreferences keys. The `baytari_` prefix keeps our keys
  // separate from any other app/package that shares the same storage.
  static const String themeModeKey = 'baytari_theme_mode';
  static const String localeCodeKey = 'baytari_locale_code';

  /// True once the user has finished (or skipped) onboarding.
  /// Read by [OnboardingCubit] so returning users skip onboarding.
  static const String onboardingSeenKey = 'baytari_onboarding_seen';
}
