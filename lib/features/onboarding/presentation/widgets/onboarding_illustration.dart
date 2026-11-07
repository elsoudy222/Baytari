/// Onboarding illustrations — the real Figma artwork, as SVG.
///
/// The artwork is the SVG files the user exported from the Figma
/// design and sent (`Stray_animal.svg`, `VET.svg`, `Community.svg`,
/// `Impact.svg`, `Get_started_illustration.svg`, `loading_cat.svg`,
/// `Frame.svg`). They live in `assets/images/` as `.svg` files and
/// are drawn with [SvgPicture] (`flutter_svg`).
///
/// Why SVG instead of the earlier PNG crops: the first version cut
/// the illustrations out of 393 px wide Figma screenshots, so they
/// were raster images that looked slightly soft on large screens.
/// Vector art stays sharp at every size — and it is the actual
/// Figma artwork, not a screenshot of it.
///
/// One variant per onboarding page, in page order:
/// 0 — Helping Stray Animals: `onboarding_1.svg` (Stray_animal).
/// 1 — Vet Clinics: `onboarding_2.svg` (VET).
/// 2 — Community of Helpers: `onboarding_3.svg` (Community).
/// 3 — Make an Impact: `onboarding_4.svg` (Impact).
/// Get Started screen: `get_started.svg`.
/// Shelter (sign-up only): `shelter.svg` (Frame — the kennel
/// scene with the "Animal Shelter" sign, from the Figma sign-up
/// screen, used for the Shelter role card and step header).
///
/// The same widget is reused by the sign-up role cards and the
/// sign-up step headers (`register_screen.dart`), so those show
/// the real art too — the Community Member card shows the
/// onboarding-4 art (Impact), the Veterinarian card the
/// onboarding-2 art (VET), and the Shelter card the kennel scene,
/// exactly like the Figma `Sign_Up.png`.
library;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// The illustration variants, in onboarding page order.
enum OnboardingIllustration {
  strayAnimals,
  vetClinics,
  community,
  impact,
  getStarted,
  shelter,
}

class OnboardingIllustrationWidget extends StatelessWidget {
  const OnboardingIllustrationWidget({required this.variant, super.key});

  final OnboardingIllustration variant;

  /// The Figma SVG artwork for each variant.
  String get _asset => switch (variant) {
    OnboardingIllustration.strayAnimals => 'assets/images/onboarding_1.svg',
    OnboardingIllustration.vetClinics => 'assets/images/onboarding_2.svg',
    OnboardingIllustration.community => 'assets/images/onboarding_3.svg',
    OnboardingIllustration.impact => 'assets/images/onboarding_4.svg',
    OnboardingIllustration.getStarted => 'assets/images/get_started.svg',
    OnboardingIllustration.shelter => 'assets/images/shelter.svg',
  };

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Same sizing as before: the image is as wide as the
        // screen (minus padding) and a little shorter than wide —
        // but never taller than the space the page actually gives
        // it, or small screens (and tests) overflow. Leave ~40%
        // of the page height for the title + subtitle below the
        // illustration.
        final double size = constraints.maxWidth;
        final double height = constraints.maxHeight.isFinite
            ? (size * 0.85).clamp(0, constraints.maxHeight * 0.62).toDouble()
            : size * 0.85;
        // The SVGs have different aspect ratios (the art is
        // taller on pages 2 and 4), so contain-fit keeps the whole
        // picture visible instead of cutting its edges.
        return SizedBox(
          height: height,
          child: SvgPicture.asset(
            _asset,
            fit: BoxFit.contain,
            // If the asset is ever missing or cannot be parsed,
            // show a paw icon instead of a broken-image box.
            placeholderBuilder: (context) => const Icon(
              Icons.pets_outlined,
              size: 80,
            ),
          ),
        );
      },
    );
  }
}
