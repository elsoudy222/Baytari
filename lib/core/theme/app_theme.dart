import 'package:flutter/material.dart';

import 'dark_theme.dart';
import 'light_theme.dart';

/// Single entry point for the app's themes.
abstract final class AppTheme {
  static ThemeData get light => buildLightTheme();

  static ThemeData get dark => buildDarkTheme();
}
