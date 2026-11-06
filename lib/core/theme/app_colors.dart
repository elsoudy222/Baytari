import 'package:flutter/material.dart';

/// The single source of truth for colors.
///
/// Widgets must use `Theme.of(context).colorScheme` (or these constants
/// via [AppTheme]) — never a hardcoded `Color(...)` in a widget.
abstract final class AppColors {
  /// Primary brand color: a calm teal, fitting a veterinary app.
  static const Color primary = Color(0xFF0F766E);
  static const Color primaryLight = Color(0xFF14B8A6);
  static const Color primaryDark = Color(0xFF0B4F4A);

  static const Color secondary = Color(0xFFF59E0B);

  static const Color lightSeed = primary;
  static const Color darkSeed = primaryLight;

  static const Color error = Color(0xFFB3261E);
}
