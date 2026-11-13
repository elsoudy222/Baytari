import 'package:flutter/material.dart';

/// The single source of truth for colors.
///
/// Widgets must use `Theme.of(context).colorScheme` (or these constants
/// via [AppTheme]) — never a hardcoded `Color(...)` in a widget.
///
/// The palette is the Figma palette, sampled from the screenshots the
/// user sent (Splash / Onboarding / Get Started / Log In):
/// - background `#FAFAFA` (off-white, sampled from every screen)
/// - primary teal `#3E8E83` (the full-width buttons, sampled)
/// - orange accent `#F15B2A` (the pin dog in the Splash logo, and the
///   active onboarding dot)
/// - dark teal heading `#223F3C` (onboarding titles, sampled)
/// - peach blob `#F2DEC5` (the blob behind the onboarding art, sampled)
/// - mint card `#EAF6F2` (the pale card behind the Sign Up form)
/// - subtitle grey `#5E6E6B` (onboarding subtitles, sampled)
/// - inactive dot `#D9DEDD` (grey onboarding dots)
///
/// The dark theme keeps the same teal/orange identity on a dark teal
/// background, so the brand survives a theme switch.
abstract final class AppColors {
  /// Primary brand color: the Figma teal, sampled from the buttons.
  static const Color primary = Color(0xFF3E8E83);
  static const Color primaryLight = Color(0xFF6FB3A8);
  static const Color primaryDark = Color(0xFF2A6B62);

  /// Orange accent: the Figma orange, sampled from the logo pin.
  static const Color secondary = Color(0xFFF15B2A);

  /// Dark teal used for onboarding titles and the logo wordmark.
  static const Color heading = Color(0xFF223F3C);

  /// Grey-teal used for onboarding subtitles and secondary text.
  static const Color subtitle = Color(0xFF5E6E6B);

  /// Peach blob behind the onboarding illustrations.
  static const Color peach = Color(0xFFF2DEC5);

  /// Pale mint card background (Sign Up / welcome cards in Figma).
  static const Color mint = Color(0xFFEAF6F2);

  /// Pale mint border / divider in the Figma cards.
  static const Color mintBorder = Color(0xFFCFE1DF);

  /// Off-white Figma background.
  static const Color background = Color(0xFFFAFAFA);

  /// Grey inactive onboarding dot.
  static const Color dotInactive = Color(0xFFD9DEDD);

  /// Dark theme surfaces: a very dark teal, not pure black, so the
  /// teal buttons still read as brand teal.
  static const Color darkBackground = Color(0xFF12211F);
  static const Color darkSurface = Color(0xFF1B2E2B);
  static const Color darkHeading = Color(0xFFEAF6F2);

  static const Color lightSeed = primary;
  static const Color darkSeed = primaryLight;

  /// Pale yellow of the "Sighted" status chip and the "Sighted"
  /// comment bubble (Home feed, sampled from Figma).
  static const Color statusYellow = Color(0xFFF9E79F);

  /// Peach-orange of the "Couldn't find" status chip and bubble
  /// (Home feed, sampled from Figma).
  static const Color statusPeach = Color(0xFFF5CBA7);

  /// Brown of the "Mid Priority" label on a post header (Home
  /// feed, sampled from Figma).
  static const Color priorityMid = Color(0xFF8B5E34);

  static const Color error = Color(0xFFB3261E);

  /// Facebook brand blue, used only by the (UI-only) Facebook
  /// social button. Brand colors live in the theme so no widget
  /// hardcodes a hex value.
  static const Color facebookBlue = Color(0xFF1877F2);
}
