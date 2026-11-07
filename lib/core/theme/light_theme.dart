import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Material 3 light theme.
///
/// `ColorScheme.fromSeed` builds the *entire* colour scheme (primary,
/// surfaces, error, on-colours) from one seed colour, so every widget
/// that uses `colorScheme` automatically matches. The overrides below
/// only pin down the details that matter: AppBar and scaffold use the
/// surface colour, cards are flat (`elevation: 0`) with a low surface
/// container, and filled buttons use the primary colour. The dark
/// theme mirrors this file on purpose, so the two themes stay in sync.
ThemeData buildLightTheme() {
  final ColorScheme colorScheme = ColorScheme.fromSeed(
    seedColor: AppColors.lightSeed,
    brightness: Brightness.light,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    brightness: Brightness.light,
    appBarTheme: AppBarTheme(
      backgroundColor: colorScheme.surface,
      foregroundColor: colorScheme.onSurface,
      centerTitle: true,
    ),
    scaffoldBackgroundColor: colorScheme.surface,
    cardTheme: CardThemeData(
      color: colorScheme.surfaceContainerLow,
      elevation: 0,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
    ),
  );
}
