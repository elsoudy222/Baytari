/// The Baytari logo.
///
/// Two pieces, for two sizes:
/// - [BaytariLogoMark] — the pin mark only, drawn with [CustomPaint]
///   (no extra dependency): a teal location pin with an orange dog
///   face and a teal cat face inside, echoing the original pin mark
///   in the Figma screenshots. Used small, e.g. top-left on the
///   onboarding pages.
/// - [BaytariLogo] — the full logo: the generated PNG
///   (`assets/images/baytari_logo.png`, teal pin + dog + cat +
///   "Baytari / بيطري" wordmark) plus the wordmark in text. Used
///   large, e.g. on the splash screen.
///
/// The wordmark text is never a hardcoded literal: the Latin name
/// comes from [AppConstants.appName] and the Arabic name from the
/// localized `appTitle` (which is "بيطري" in Arabic and "Baytari"
/// in English, so the second line only shows when it differs).
library;

import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/extensions/context_extensions.dart';
import '../../core/theme/app_colors.dart';

/// The full Baytari logo: generated PNG image + wordmark underneath.
class BaytariLogo extends StatelessWidget {
  const BaytariLogo({required this.height, super.key});

  /// Total height of the logo image (the wordmark follows below it).
  final double height;

  @override
  Widget build(BuildContext context) {
    final String arabicName = context.l10n.appTitle;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Image.asset(
          'assets/images/baytari_logo.png',
          height: height,
          fit: BoxFit.contain,
          // If the asset is ever missing, the wordmark below still
          // identifies the app instead of a broken-image box.
          errorBuilder: (context, error, stackTrace) =>
              BaytariLogoMark(size: height * 0.6),
        ),
        const SizedBox(height: 12),
        Text(
          AppConstants.appName,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: context.isDark ? AppColors.darkHeading : AppColors.heading,
            fontWeight: FontWeight.bold,
          ),
        ),
        // In Arabic the localized title is "بيطري"; in English it is
        // the same "Baytari", so the second line would be a duplicate.
        if (arabicName != AppConstants.appName)
          Text(
            arabicName,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
  }
}

/// The pin mark only, drawn with CustomPaint (vector, no dependency).
class BaytariLogoMark extends StatelessWidget {
  const BaytariLogoMark({required this.size, super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _PinLogoPainter(),
    );
  }
}

/// Draws the pin: teal pin body, white inner circle, orange dog head
/// (left) and teal cat head with ears (right). All colours come from
/// [AppColors], never hardcoded here.
class _PinLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final Paint teal = Paint()..color = AppColors.primary;
    final Paint orange = Paint()..color = AppColors.secondary;
    final Paint white = Paint()..color = AppColors.background;
    final Paint dark = Paint()..color = AppColors.heading;

    // Pin body: a circle on top of a triangle pointing down.
    final Path pin = Path()
      ..addOval(Rect.fromCircle(center: Offset(w * 0.5, h * 0.38), radius: w * 0.42))
      ..moveTo(w * 0.14, h * 0.52)
      ..lineTo(w * 0.5, h * 0.98)
      ..lineTo(w * 0.86, h * 0.52)
      ..close();
    canvas.drawPath(pin, teal);

    // White inner circle for the two faces to sit on.
    canvas.drawCircle(
      Offset(w * 0.5, h * 0.38),
      w * 0.30,
      white,
    );

    // Dog (left): orange head + floppy ears.
    canvas.drawCircle(Offset(w * 0.38, h * 0.38), w * 0.14, orange);
    canvas.drawCircle(Offset(w * 0.33, h * 0.34), w * 0.03, dark);
    canvas.drawCircle(Offset(w * 0.43, h * 0.34), w * 0.03, dark);

    // Cat (right): teal head + two pointed ears.
    final Path cat = Path()
      ..moveTo(w * 0.58, h * 0.30)
      ..lineTo(w * 0.60, h * 0.20)
      ..lineTo(w * 0.66, h * 0.28)
      ..lineTo(w * 0.72, h * 0.20)
      ..lineTo(w * 0.74, h * 0.30)
      ..addOval(Rect.fromCircle(center: Offset(w * 0.66, h * 0.38), radius: w * 0.13))
      ..close();
    canvas.drawPath(cat, teal);
    canvas.drawCircle(Offset(w * 0.62, h * 0.36), w * 0.02, white);
    canvas.drawCircle(Offset(w * 0.70, h * 0.36), w * 0.02, white);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
