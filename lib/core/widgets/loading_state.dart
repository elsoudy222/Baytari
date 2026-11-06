import 'package:flutter/material.dart';

import '../extensions/context_extensions.dart';

/// Shared loading state, used by every feature instead of duplicating
/// a spinner + text.
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
