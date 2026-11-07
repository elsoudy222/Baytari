/// Onboarding screen — the 4 Figma onboarding pages.
///
/// Layout per page (from the screenshots): the logo mark top-left,
/// "Skip" top-right in teal, a large illustration area, the title
/// in dark teal bold, the subtitle in grey, the page dots (orange
/// active, grey inactive), and a full-width teal "Get Started"
/// button at the bottom.
///
/// Behaviour:
/// - "Get Started" advances to the next page; on the last page it
///   marks onboarding as seen (via [OnboardingCubit.markSeen]) and
///   goes to `/get-started`.
/// - "Skip" marks onboarding as seen and jumps straight to
///   `/get-started`.
/// - The page index is local UI state (`setState` in this widget):
///   it is not business logic, so it does not belong in a Cubit.
///
/// Titles/subtitles come from the ARB files (Arabic default, RTL
/// correct) — never hardcoded here.
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/baytari_logo.dart';
import '../cubit/onboarding_cubit.dart';
import '../widgets/onboarding_dots.dart';
import '../widgets/onboarding_illustration.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();

  /// Current page index — UI state only (see the file doc comment).
  int _currentPage = 0;

  static const int _pageCount = 4;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Finishes onboarding: persist "seen", then go to Get Started.
  Future<void> _finish() async {
    await context.read<OnboardingCubit>().markSeen();
    if (mounted) {
      context.go(AppRoutes.getStarted);
    }
  }

  void _onGetStarted() {
    if (_currentPage == _pageCount - 1) {
      _finish();
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    // Titles/subtitles in page order, from the ARB files.
    final List<(String, String, OnboardingIllustration)> pages =
        <(String, String, OnboardingIllustration)>[
          (
            l10n.onboardingTitle1,
            l10n.onboardingSubtitle1,
            OnboardingIllustration.strayAnimals,
          ),
          (
            l10n.onboardingTitle2,
            l10n.onboardingSubtitle2,
            OnboardingIllustration.vetClinics,
          ),
          (
            l10n.onboardingTitle3,
            l10n.onboardingSubtitle3,
            OnboardingIllustration.community,
          ),
          (
            l10n.onboardingTitle4,
            l10n.onboardingSubtitle4,
            OnboardingIllustration.impact,
          ),
        ];

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: <Widget>[
              const SizedBox(height: 8),
              // Top row: logo mark (start side) + Skip (end side).
              // In RTL the logo moves to the right automatically.
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  const BaytariLogoMark(size: 44),
                  TextButton(
                    onPressed: _finish,
                    child: Text(l10n.skip),
                  ),
                ],
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _pageCount,
                  onPageChanged: (int index) {
                    setState(() => _currentPage = index);
                  },
                  itemBuilder: (context, index) {
                    final (String title, String subtitle,
                        OnboardingIllustration variant) = pages[index];
                    return Column(
                      children: <Widget>[
                        const SizedBox(height: 16),
                        // Expanded gives the illustration a *bounded*
                        // height (the Column itself passes unbounded
                        // height to its children, so the illustration
                        // could not size itself from its constraints).
                        Expanded(
                          child: OnboardingIllustrationWidget(
                            variant: variant,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          title,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                color: context.isDark
                                    ? AppColors.darkHeading
                                    : AppColors.heading,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          subtitle,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppColors.subtitle),
                        ),
                      ],
                    );
                  },
                ),
              ),
              OnboardingDots(count: _pageCount, current: _currentPage),
              const SizedBox(height: 24),
              // Full-width teal button (styling from the theme).
              SizedBox(
                width: double.infinity,
                child: AppButton(
                  label: l10n.getStarted,
                  onPressed: _onGetStarted,
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
