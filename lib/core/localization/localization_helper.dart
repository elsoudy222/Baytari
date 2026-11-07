import 'package:flutter/material.dart';

import '../constants/app_constants.dart';

/// Helpers around the supported locales. All user-facing strings come
/// from the generated `AppLocalizations` class, never from here.
abstract final class LocalizationHelper {
  static List<Locale> get supportedLocales => AppConstants.supportedLocales;

  /// Builds a [Locale] from a saved language code (`'ar'` / `'en'`).
  /// An unknown code can never crash the app: it falls back to the
  /// default locale (Arabic), the same fallback used everywhere else.
  static Locale localeFromCode(String code) {
    if (AppConstants.supportedLanguageCodes.contains(code)) {
      return Locale(code);
    }
    return AppConstants.defaultLocale;
  }

  /// Languages written right-to-left. (Flutter's `Bidi` helper is not
  /// exposed in this SDK, so the check is an explicit language list.)
  ///
  /// Only Arabic is used by the app today; the other codes are listed
  /// so the helper stays correct if a language is added later. Flutter
  /// itself already flips the layout from `locale`, this helper is for
  /// code that needs to ask explicitly (e.g. custom alignment logic).
  static const Set<String> _rtlLanguageCodes = <String>{
    'ar',
    'he',
    'fa',
    'ur',
  };

  static bool isRtl(Locale locale) =>
      _rtlLanguageCodes.contains(locale.languageCode);
}
