import 'package:flutter/material.dart';

import '../extensions/context_extensions.dart';

/// Shared error state with a retry action.
///
/// The title is always the localized generic error text; the
/// *specific* message comes from the caller (usually the Failure's
/// message, passed down from the Cubit). The retry button only appears
/// when `onRetry` is given — a screen that cannot retry simply does
/// not pass one, instead of showing a dead button. The icon colour
/// comes from the theme (`context.colors.error`), so it follows the
/// light/dark theme.
class ErrorState extends StatelessWidget {
  const ErrorState({required this.message, this.onRetry, super.key});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.error_outline,
              size: 48,
              color: context.colors.error,
            ),
            const SizedBox(height: 16),
            Text(
              context.l10n.errorTitle,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            if (onRetry != null) ...<Widget>[
              const SizedBox(height: 16),
              FilledButton(
                onPressed: onRetry,
                child: Text(context.l10n.retry),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
