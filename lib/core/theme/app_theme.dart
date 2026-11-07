import 'package:flutter/material.dart';

import 'dark_theme.dart';
import 'light_theme.dart';

/// Single entry point for the app's themes.
///
/// `BaytariApp` reads `AppTheme.light` / `AppTheme.dark` and lets
/// Flutter pick between them from the `themeMode` in [AppState]. The
/// two getters look trivial on purpose: the real work (seed colours,
/// surfaces, buttons) lives in `light_theme.dart` / `dark_theme.dart`.
abstract final class AppTheme {
  static ThemeData get light => buildLightTheme();

  static ThemeData get dark => buildDarkTheme();
}
