/// Splash screen — the app entry point.
///
/// Layout (from the Figma Splash / loading screens): off-white
/// background, the Baytari logo centred, the yellow cat from the
/// Figma loading screen (`loading_cat.svg`, the cat playing with
/// a ball of yarn) underneath it, and a small orange loading dot
/// below that.
///
/// Flow: the screen shows for about 2 seconds, then decides where
/// to go — it never stays on screen:
/// - onboarding not seen yet -> `/onboarding`
/// - onboarding seen + signed in (or guest) -> home `/`
/// - onboarding seen + not signed in -> `/get-started`
///
/// The decision reads the two Cubits' *current* state (no new
/// loading: the session check already ran in `BaytariApp.initState`
/// and the onboarding flag is read synchronously). The timer is
/// cancelled in `dispose`, and navigation checks `mounted`, so a
/// hot-reload or a fast dispose never navigates on a dead widget.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_router.dart';
import '../../../../core/widgets/baytari_logo.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../cubit/onboarding_cubit.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(seconds: 2), _goNext);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _goNext() {
    if (!mounted) {
      return;
    }
    final bool seen = context.read<OnboardingCubit>().state.seen;
    if (!seen) {
      context.go(AppRoutes.onboarding);
      return;
    }
    final AuthCubit authCubit = context.read<AuthCubit>();
    final bool signedIn = authCubit.state.isAuthenticated;
    final bool guest = context.read<OnboardingCubit>().state.guestMode;
    context.go(signedIn || guest ? AppRoutes.home : AppRoutes.getStarted);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const BaytariLogo(height: 220),
            // const SizedBox(height: 16),
            // // The yellow cat from the Figma loading screen
            // // (`loading_cat.svg`): the loading screen in Figma is
            // // the cat with the orange dot underneath, so the
            // // splash shows both. Flexible so small screens shrink
            // // the art instead of overflowing.
            // Flexible(
            //   child: SvgPicture.asset(
            //     'assets/images/loading_cat.svg',
            //     fit: BoxFit.contain,
            //   ),
            // ),
            // const SizedBox(height: 16),
            // Orange loading dot, as on the Figma loading screen.
            // const SizedBox(
            //   width: 12,
            //   height: 12,
            //   child: DecoratedBox(
            //     decoration: BoxDecoration(
            //       color: AppColors.secondary,
            //       shape: BoxShape.circle,
            //     ),
            //   ),
            // ),
          ],
        ),
      ),
    );
  }
}
