import 'package:flutter/material.dart';

import '../extensions/context_extensions.dart';

/// Shared loading state, used by every feature instead of duplicating
/// a spinner + text.
///
/// `mainAxisSize: MainAxisSize.min` keeps the column as small as its
/// children (spinner + text) instead of stretching to fill the screen,
/// so `Center` can actually centre it. The text comes from the ARB
/// files (`context.l10n.loading`), never hardcoded.
class LoadingState extends StatelessWidget {
  const LoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(context.l10n.loading),
        ],
      ),
    );
  }
}
