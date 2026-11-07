import 'package:flutter/material.dart';

/// Primary action button. Styling comes from the theme only —
/// no hardcoded colors or sizes.
///
/// `label` is a plain string on purpose: the *caller* passes an
/// already-localized string (`l10n.xxx`), so this widget never needs
/// to know about localization. `onPressed: null` disables the button
/// (Flutter greys a `FilledButton` automatically when it is null).
class AppButton extends StatelessWidget {
  const AppButton({
    required this.label,
    required this.onPressed,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(onPressed: onPressed, child: Text(label));
  }
}
