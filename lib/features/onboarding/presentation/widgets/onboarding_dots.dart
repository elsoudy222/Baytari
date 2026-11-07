/// Onboarding page dots, as in the Figma screenshots.
///
/// The active dot is a wide orange pill; inactive dots are small
/// grey circles. Colours come from [AppColors] (centralized) — the
/// widget never hardcodes a colour.
library;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class OnboardingDots extends StatelessWidget {
  const OnboardingDots({
    required this.count,
    required this.current,
    super.key,
  });

  final int count;
  final int current;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List<Widget>.generate(count, (int index) {
        final bool isActive = index == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 32 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive ? AppColors.secondary : AppColors.dotInactive,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}
