/// Shared shell for the auth screens, matching the Figma auth
/// design (Log In / Sign Up / Forgot password):
///
/// - Back arrow (top-start) that pops the route.
/// - A pale mint card ([AppColors.mint]) holding the form, with
///   rounded corners — the "card" in every Figma sign-up step.
/// - The "By continuing, you agree to our Terms of Service and
///   Privacy Policy" footer at the bottom (Terms / Privacy are
///   links in the design; they show a "coming soon" message for
///   now — the legal pages do not exist yet).
/// - Scrollable content, so the keyboard never overflows a small
///   screen (the Figma keyboard screenshots show the form above
///   the keyboard).
///
/// Screens pass their title + body; this widget owns only layout.
library;

import 'package:flutter/material.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/localization/generated/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/dialogs/app_toast.dart';

/// The auth shell: back arrow, optional title, mint card, footer.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    required this.title,
    required this.child,
    super.key,
    this.showCard = true,
    this.showTermsFooter = true,
    this.onBack,
  });

  /// The heading at the top ("Sign Up", "Reset Your Password",
  /// ...). Empty string hides the heading (login uses its own
  /// "Welcome back!" header instead).
  final String title;

  /// The form content.
  final Widget child;

  /// Figma sign-up steps wrap the form in a mint card; the login
  /// screen does not use a card.
  final bool showCard;

  /// The Terms/Privacy footer (shown on login + sign-up in Figma).
  final bool showTermsFooter;

  /// Custom back action; defaults to popping the route.
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const SizedBox(height: 8),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back),
                    color: AppColors.primary,
                    onPressed:
                        onBack ?? () => Navigator.of(context).maybePop(),
                    tooltip: MaterialLocalizations.of(
                      context,
                    ).backButtonTooltip,
                  ),
                ),
                if (title.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 8),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.headlineSmall
                        ?.copyWith(
                          color: context.isDark
                              ? AppColors.darkHeading
                              : AppColors.heading,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                ],
                if (showCard)
                  Container(
                    decoration: BoxDecoration(
                      color: context.isDark
                          ? AppColors.darkSurface
                          : AppColors.mint,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: child,
                  )
                else
                  child,
                const SizedBox(height: 24),
                if (showTermsFooter) _TermsFooter(l10n: l10n),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// "By continuing, you agree to our Terms of Service and Privacy
/// Policy" — Terms / Privacy are tappable links in Figma; the
/// legal pages do not exist yet, so they show a localized
/// "coming soon" snackbar instead of navigating nowhere.
class _TermsFooter extends StatelessWidget {
  const _TermsFooter({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        Text(
          l10n.termsAgreement,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.subtitle,
          ),
        ),
        TextButton(
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          onPressed: () => _comingSoon(context),
          child: Text(
            l10n.termsOfService,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.primary,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
        Text(
          ' ${l10n.termsAnd} ',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.subtitle,
          ),
        ),
        TextButton(
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          onPressed: () => _comingSoon(context),
          child: Text(
            l10n.privacyPolicy,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.primary,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }

  void _comingSoon(BuildContext context) {
    showAppToast(context, context.l10n.socialComingSoon);
  }
}

/// A white rounded text field in the Figma style: white fill,
/// no visible border until focused (then the teal outline from
/// the theme), 12px corners. Used by every auth form so the
/// fields look identical across login / sign-up / reset.
class AuthTextField extends StatelessWidget {
  const AuthTextField({
    required this.controller,
    required this.hint,
    super.key,
    this.keyboardType,
    this.obscureText = false,
    this.textInputAction,
    this.validator,
    this.onChanged,
    this.onFieldSubmitted,
    this.suffixIcon,
    this.prefixIcon,
    this.readOnly = false,
    this.onTap,
    this.maxLength,
  });

  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final bool obscureText;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final bool readOnly;
  final VoidCallback? onTap;
  final int? maxLength;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      textInputAction: textInputAction,
      validator: validator,
      onChanged: onChanged,
      onFieldSubmitted: onFieldSubmitted,
      readOnly: readOnly,
      onTap: onTap,
      maxLength: maxLength,
      buildCounter:
          (
            context, {
            required int currentLength,
            required bool isFocused,
            required int? maxLength,
          }) => null,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: context.isDark
            ? AppColors.darkBackground
            : AppColors.background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: context.colors.error),
        ),
        suffixIcon: suffixIcon,
        prefixIcon: prefixIcon,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }
}

/// A full-width teal button in the Figma style (the theme's
/// FilledButton already uses the teal + 12px radius, so this is
/// just [AppButton] re-exported under the auth naming).
typedef AuthPrimaryButton = AppButton;
