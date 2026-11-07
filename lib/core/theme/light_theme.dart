import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Material 3 light theme, in the Figma palette.
///
/// `ColorScheme.fromSeed` builds the *entire* colour scheme (primary,
/// surfaces, error, on-colours) from one seed colour, so every widget
/// that uses `colorScheme` automatically matches. The overrides below
/// only pin down the details that matter: the scaffold uses the Figma
/// off-white background (`#FAFAFA`), cards are flat (`elevation: 0`)
/// with the mint card colour, and filled buttons use the Figma teal
/// with the Figma corner radius (12) and full-width padding. The dark
/// theme mirrors this file on purpose, so the two themes stay in sync.
///
/// Font: Cairo (the user's choice) for Arabic and Latin alike, via
/// `GoogleFonts.cairoTextTheme` — applied to the whole text theme so
/// every widget inherits it without naming a font anywhere else.
ThemeData buildLightTheme() {
  final ColorScheme colorScheme = ColorScheme.fromSeed(
    seedColor: AppColors.lightSeed,
    brightness: Brightness.light,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    brightness: Brightness.light,
    textTheme: GoogleFonts.cairoTextTheme(),
    scaffoldBackgroundColor: AppColors.background,
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.heading,
      centerTitle: true,
    ),
    cardTheme: CardThemeData(
      color: AppColors.mint,
      elevation: 0,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        backgroundColor: colorScheme.surface,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: AppColors.primary),
    ),
  );
}
