/// Get Started screen — from the Figma `Get_Started.png`.
///
/// Layout: the logo mark top-left, the real Figma illustration
/// (the animals art cropped from `Get_Started.png`, see
/// [OnboardingIllustrationWidget]), the invite text, a teal
/// "Log In" button, a white "Sign Up" button, and a "Join as a
/// guest" text link.
///
/// Behaviour:
/// - "Log In" -> `/login`, "Sign Up" -> `/register` (the existing
///   M1 auth flow, untouched by this screen).
/// - "Join as a guest" -> [OnboardingCubit.continueAsGuest] (session
///   only, no account is created) and then home `/`. The router's
///   guard lets guests reach Home; signing in later still works
///   from the home screen.
///
/// The invite text is adapted from the original design's wording
/// ("Join ... today...") with the Baytari name, and lives in the
/// ARB files — the old file name never appears in the app.
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/baytari_logo.dart';
import '../cubit/onboarding_cubit.dart';
import '../widgets/onboarding_illustration.dart';

class GetStartedScreen extends StatelessWidget {
  const GetStartedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const SizedBox(height: 8),
              // Logo mark top-left (start side in RTL too).
              const Align(
                alignment: AlignmentDirectional.centerStart,
                child: BaytariLogoMark(size: 44),
              ),
              const SizedBox(height: 16),
              const Expanded(
                child: OnboardingIllustrationWidget(
                  variant: OnboardingIllustration.getStarted,
                ),
              ),
              Text(
                l10n.getStartedMessage,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 24),
              AppButton(
                label: l10n.logIn,
                onPressed: () => context.go(AppRoutes.login),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => context.go(AppRoutes.register),
                child: Text(l10n.signUp),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  // Guest mode: session only, no account created.
                  context.read<OnboardingCubit>().continueAsGuest();
                  context.go(AppRoutes.home);
                },
                child: Text(l10n.joinAsGuest),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
