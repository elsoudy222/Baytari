import 'package:flutter/material.dart';

/// Centralized text styles. Widgets use these (or the theme's
/// `textTheme`) instead of defining their own font sizes and weights.
///
/// `height` is a line-height multiplier (1.3–1.5), not pixels: it keeps
/// Arabic text — which is taller than Latin text — from clipping.
/// These styles are ready for M1+ screens; the M0 screens use the
/// theme's `textTheme` (e.g. `headlineMedium`) instead.
abstract final class AppTextStyles {
  static const TextStyle headline = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    height: 1.3,
  );

  static const TextStyle title = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  static const TextStyle body = TextStyle(fontSize: 16, height: 1.5);

  static const TextStyle bodySmall = TextStyle(fontSize: 14, height: 1.5);

  static const TextStyle caption = TextStyle(fontSize: 12, height: 1.4);
}
