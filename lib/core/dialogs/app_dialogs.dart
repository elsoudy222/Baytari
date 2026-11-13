/// App dialogs — the one place the app shows a modal dialog.
///
/// This file lives in `core/dialogs/` next to the toast
/// (`app_toast.dart`) for the same reason: a screen should never
/// build its own `AlertDialog` from scratch, or every dialog in the
/// app ends up looking — and behaving — differently. These two
/// helpers are the only dialog builders the app needs so far:
///
/// - [showAppLoadingDialog] — a non-dismissible spinner while a
///   long operation runs (sign-in, upload, ...).
/// - [showAppConfirmationDialog] — a "are you sure?" dialog that
///   answers `true` (confirmed) or `false` (cancelled / dismissed).
///
/// Both are theme-aware (colors and text styles come from the
/// current `Theme`, never hardcoded) and localized (button labels
/// come from the generated ARB strings, never hardcoded) — so they
/// follow light/dark mode and Arabic/English automatically, exactly
/// like the rest of the app.
library;

import 'package:flutter/material.dart';

import '../extensions/context_extensions.dart';

/// Shows a non-dismissible loading dialog: a spinner in the brand
/// color and the localized "Loading…" text.
///
/// The dialog cannot be dismissed by tapping outside it or with
/// the back button (`barrierDismissible: false` + [PopScope]) —
/// the user must wait for the operation to finish, because
/// dismissing it early would leave a half-finished sign-in or
/// upload running with no visible feedback.
///
/// Call [hideAppLoadingDialog] when the operation finishes. It must
/// be called exactly once per show, from the same place that
/// awaited the operation — popping with no dialog on screen would
/// pop the screen underneath instead.
Future<void> showAppLoadingDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    // Not dismissible: see the doc comment above.
    barrierDismissible: false,
    builder: (BuildContext dialogContext) {
      return PopScope(
        // Back button also blocked while loading.
        canPop: false,
        child: AlertDialog(
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              CircularProgressIndicator(
                // Brand color from the theme, so the spinner is
                // teal in light mode and readable in dark mode.
                color: dialogContext.colors.primary,
              ),
              const SizedBox(width: 16),
              Flexible(
                child: Text(
                  // Localized "Loading…" from the ARB files.
                  dialogContext.l10n.loading,
                  style: dialogContext.textTheme.bodyLarge,
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// Hides the dialog shown by [showAppLoadingDialog].
///
/// Pops the topmost route of the *root* navigator, which is where
/// `showDialog` puts its dialog — so it closes the dialog even
/// when the call happens from a nested navigator (e.g. inside a
/// GoRouter sub-route). Only call it after a matching
/// [showAppLoadingDialog], otherwise it pops the current screen.
void hideAppLoadingDialog(BuildContext context) {
  Navigator.of(context, rootNavigator: true).pop();
}

/// Shows a confirmation dialog and answers whether the user
/// confirmed.
///
/// Returns `true` when the user taps the confirm button,
/// `false` when they tap cancel or dismiss the dialog (back button
/// / tap outside). Callers use it like:
///
/// ```dart
/// final bool confirmed = await showAppConfirmationDialog(
///   context: context,
///   title: 'Delete pet',
///   message: 'This cannot be undone.',
/// );
/// if (confirmed) { /* delete */ }
/// ```
///
/// [title] and [message] are passed in by the caller (they are
/// screen-specific), but the buttons are not: [confirmLabel]
/// defaults to the localized "Confirm" and [cancelLabel] to the
/// localized "Cancel" from the ARB files, so no screen ever
/// hardcodes button text. Pass explicit labels only when a screen
/// genuinely needs different words (e.g. "Delete" instead of
/// "Confirm").
Future<bool> showAppConfirmationDialog({
  required BuildContext context,
  required String title,
  required String message,
  String? confirmLabel,
  String? cancelLabel,
}) async {
  // `?? false`: dismissing the dialog returns null from
  // `showDialog`, and "dismissed" means "not confirmed".
  final bool? result = await showDialog<bool>(
    context: context,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(cancelLabel ?? dialogContext.l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            // Confirm stands out in the brand color; cancel stays
            // the default (neutral) text-button color.
            child: Text(
              confirmLabel ?? dialogContext.l10n.confirm,
              style: TextStyle(color: dialogContext.colors.primary),
            ),
          ),
        ],
      );
    },
  );
  return result ?? false;
}
