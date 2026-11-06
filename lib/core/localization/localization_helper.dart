import 'package:flutter/material.dart';

import '../constants/app_constants.dart';

/// Helpers around the supported locales. All user-facing strings come
/// from the generated `AppLocalizations` class, never from here.
abstract final class LocalizationHelper {
  static List<Locale> get supportedLocales => AppConstants.supportedLocales;

  static Locale localeFromCode(String code) {
    if (AppConstants.supportedLanguageCodes.contains(code)) {
      return Locale(code);
    }
    return AppConstants.defaultLocale;
  }

  /// Languages written right-to-left. (Flutter's `Bidi` helper is not
  /// exposed in this SDK, so the check is an explicit language list.)
  static const Set<String> _rtlLanguageCodes = <String>{
    'ar',
    'he',
    'fa',
    'ur',
  };

  static bool isRtl(Locale locale) =>
      _rtlLanguageCodes.contains(locale.languageCode);
}
