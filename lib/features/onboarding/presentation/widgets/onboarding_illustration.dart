/// Simplified onboarding illustrations.
///
/// The Figma art is custom illustration (people, animals, clinic
/// scenes) and cannot be copied into the app. This widget is a
/// deliberate placeholder in the same Figma palette: a large peach
/// or mint blob with one big pet-related icon in the middle and a
/// small paw print. It keeps the layout, spacing and colours of the
/// Figma pages so the real artwork can be dropped in later without
/// moving anything else.
///
/// One variant per onboarding page:
/// 0 — Helping Stray Animals: pets icon on a peach blob.
/// 1 — Vet Clinics: medical services icon on a mint blob.
/// 2 — Community of Helpers: group icon on a lavender-tinted blob.
/// 3 — Make an Impact: favourite (heart) icon on a peach blob.
library;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// The four illustration variants, in onboarding page order.
enum OnboardingIllustration { strayAnimals, vetClinics, community, impact }

class OnboardingIllustrationWidget extends StatelessWidget {
  const OnboardingIllustrationWidget({required this.variant, super.key});

  final OnboardingIllustration variant;

  @override
  Widget build(BuildContext context) {
    // Blob colour, main icon and accent icon, per variant. Colours
    // come from AppColors (centralized) — never hardcoded here.
    final (Color blob, IconData icon, Color iconColor) = switch (variant) {
      OnboardingIllustration.strayAnimals => (
        AppColors.peach,
        Icons.pets_outlined,
        AppColors.primary,
      ),
      OnboardingIllustration.vetClinics => (
        AppColors.mint,
        Icons.medical_services_outlined,
        AppColors.primaryDark,
      ),
      OnboardingIllustration.community => (
        AppColors.mintBorder,
        Icons.groups_outlined,
        AppColors.primary,
      ),
      OnboardingIllustration.impact => (
        AppColors.peach,
        Icons.favorite_outlined,
        AppColors.secondary,
      ),
    };

    return LayoutBuilder(
      builder: (context, constraints) {
        // The blob is as wide as the screen (minus padding) and a
        // little shorter than wide, like the Figma illustration area
        // — but never taller than the space the page actually gives
        // it, or small screens (and tests) overflow.
        final double size = constraints.maxWidth;
        // Leave ~40% of the page height for the title + subtitle
        // below the illustration, or small screens overflow.
        final double height = constraints.maxHeight.isFinite
            ? (size * 0.85).clamp(0, constraints.maxHeight * 0.62).toDouble()
            : size * 0.85;
        return SizedBox(
          height: height,
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              // Blob: a rounded shape, wider than tall, in the
              // Figma peach/mint colour.
              Container(
                width: size,
                height: height * 0.85,
                decoration: BoxDecoration(
                  color: blob,
                  borderRadius: BorderRadius.all(
                    Radius.elliptical(size * 0.5, height * 0.42),
                  ),
                ),
              ),
              // Main icon, large, in the Figma teal/orange.
              Icon(icon, size: height * 0.45, color: iconColor),
              // Small paw accent, bottom-right of the blob.
              Positioned(
                right: size * 0.08,
                bottom: height * 0.06,
                child: Icon(
                  Icons.pets,
                  size: height * 0.14,
                  color: AppColors.secondary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
