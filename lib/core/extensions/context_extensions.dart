import 'package:flutter/material.dart';

import '../localization/generated/app_localizations.dart';

/// Convenience accessors for localization, theme and layout.
/// Widgets use these instead of reaching for hardcoded strings/colors.
///
/// `context.l10n` is the short way to say
/// `AppLocalizations.of(context)!` — the `!` is safe here because the
/// delegates are registered in `BaytariApp`; if they were missing, the
/// app would fail at startup, not silently show nothing.
extension BuildContextExtensions on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;

  // Shortcuts to the current theme, so widgets never hardcode a color:
  // `context.colors.primary` always follows the light/dark theme.
  ColorScheme get colors => Theme.of(this).colorScheme;

  TextTheme get textTheme => Theme.of(this).textTheme;

  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}
