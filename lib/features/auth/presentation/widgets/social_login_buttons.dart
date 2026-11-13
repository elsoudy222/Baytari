/// Social sign-in buttons from the Figma login / sign-up screens:
/// Google, X and Facebook in white rounded squares under an
/// "or log in with" divider.
///
/// UI ONLY, on purpose: social OAuth needs provider setup in
/// Supabase (Google Cloud / Meta / X developer consoles, redirect
/// URLs) and is NOT part of this stage. Tapping a button shows a
/// localized "coming soon" message instead of pretending to sign
/// in — see the Arabic doc. When OAuth is set up later, these
/// buttons call `AuthCubit.signInWithProvider(...)` instead.
library;

import 'package:flutter/material.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/dialogs/app_toast.dart';

class SocialLoginButtons extends StatelessWidget {
  const SocialLoginButtons({super.key, this.label});

  /// The divider text ("or log in with" / "or sign up with").
  /// Null hides the divider and shows only the buttons.
  final String? label;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      children: <Widget>[
        if (label != null) ...<Widget>[
          Row(
            children: <Widget>[
              const Expanded(child: Divider()),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  label!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.subtitle,
                  ),
                ),
              ),
              const Expanded(child: Divider()),
            ],
          ),
          const SizedBox(height: 16),
        ],
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            _SocialButton(
              label: 'G',
              color: AppColors.secondary,
              onTap: () => _comingSoon(context, l10n.socialComingSoon),
            ),
            const SizedBox(width: 16),
            _SocialButton(
              label: 'X',
              color: AppColors.heading,
              onTap: () => _comingSoon(context, l10n.socialComingSoon),
            ),
            const SizedBox(width: 16),
            _SocialButton(
              label: 'f',
              color: AppColors.facebookBlue,
              onTap: () => _comingSoon(context, l10n.socialComingSoon),
            ),
          ],
        ),
      ],
    );
  }

  void _comingSoon(BuildContext context, String message) {
    showAppToast(context, message);
  }
}

/// One white rounded square with a brand letter. The letters are
/// text (not brand image assets): no logo files are bundled, and
/// the buttons are "coming soon" placeholders anyway.
class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: context.isDark
              ? AppColors.darkSurface
              : AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.mintBorder),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
