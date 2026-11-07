/// The Baytari logo (v3).
///
/// Two pieces, for two sizes:
/// - [BaytariLogoMark] — the icon only (dog + cat silhouette),
///   cropped out of the v3 PNG into `assets/images/baytari_mark.png`
///   with a transparent background, so it works on light and dark
///   screens. Used small, e.g. top-left on the onboarding and
///   auth pages.
/// - [BaytariLogo] — the full wide lockup: the icon on the left,
///   the "Baytari" wordmark (bold, with an orange paw on the "i")
///   and "بيطري" underneath, all inside `assets/images/baytari_logo.png`.
///   Used large, e.g. on the splash screen. The wordmark is part of
///   the image itself, so this widget adds NO text underneath it —
///   adding it would duplicate the name twice.
///
/// v3 colours match the app palette exactly (no gradient, no brown):
/// the dog is solid orange [#F15B2A], the cat is solid teal
/// [#3E8E83], the wordmark is "Bayt" in dark teal [#223F3C] +
/// "tari" in teal [#3E8E83], the paw is vivid orange, and "بيطري"
/// is teal. (v2 had a teal-to-orange gradient on the icon; v3
/// replaced it with these solid palette colours.)
/// If an image asset is ever missing, the widget falls back to the
/// old vector pin mark drawn with [CustomPaint] instead of showing
/// a broken-image box.
library;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// The full Baytari logo: the v2 wide lockup PNG, nothing else.
class BaytariLogo extends StatelessWidget {
  const BaytariLogo({required this.height, super.key});

  /// Desired height of the logo. The lockup is wide (about 3:1),
  /// so on a narrow phone the width is capped to the space
  /// available and the height shrinks to keep the aspect ratio —
  /// otherwise a 220-high logo would be ~660 wide and overflow.
  final double height;

  /// Width-to-height ratio of the v3 lockup PNG (2640 x 864).
  static const double _lockupAspectRatio = 2640 / 864;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        // The image keeps its own aspect ratio: width = height x 3.
        // If that is wider than the space we have, shrink both
        // dimensions together instead of overflowing.
        double width = height * _lockupAspectRatio;
        double displayHeight = height;
        if (constraints.hasBoundedWidth && width > constraints.maxWidth) {
          width = constraints.maxWidth;
          displayHeight = width / _lockupAspectRatio;
        }
        return Image.asset(
          'assets/images/baytari_logo.png',
          width: width,
          height: displayHeight,
          fit: BoxFit.contain,
          // If the asset is ever missing, fall back to the small
          // mark so the screen still shows the brand.
          errorBuilder: (context, error, stackTrace) =>
              BaytariLogoMark(size: displayHeight),
        );
      },
    );
  }
}

/// The icon mark only: the dog + cat silhouette from the v3 logo
/// (solid orange dog, solid teal cat).
class BaytariLogoMark extends StatelessWidget {
  const BaytariLogoMark({required this.size, super.key});

  /// Width and height of the (square) mark image.
  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/baytari_mark.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      // If the cropped mark is ever missing, fall back to the
      // vector pin mark drawn below (no asset needed).
      errorBuilder: (context, error, stackTrace) => CustomPaint(
        size: Size(size, size),
        painter: _PinLogoPainter(),
      ),
    );
  }
}

/// Draws the old (v1) pin: teal pin body, white inner circle, orange
/// dog head (left) and teal cat head with ears (right). Only used as
/// a fallback when the PNG assets are missing. All colours come from
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
