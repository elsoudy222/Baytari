import 'package:flutter/material.dart';

import '../localization/generated/app_localizations.dart';

/// Convenience accessors for localization, theme and layout.
/// Widgets use these instead of reaching for hardcoded strings/colors.
extension BuildContextExtensions on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;

  ColorScheme get colors => Theme.of(this).colorScheme;

  TextTheme get textTheme => Theme.of(this).textTheme;

  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}
