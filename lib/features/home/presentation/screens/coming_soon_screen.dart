/// Placeholder for a bottom-nav tab whose feature is not built
/// yet (Map / Community / Vets / Shelters in this stage).
///
/// A plain "coming soon" message with the tab title — no fake
/// content, no dead buttons. Each tab is replaced by its real
/// screen in its own stage.
library;

import 'package:flutter/material.dart';

import '../../../../core/extensions/context_extensions.dart';

class ComingSoonScreen extends StatelessWidget {
  const ComingSoonScreen({required this.title, super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(Icons.construction_outlined, size: 64),
              const SizedBox(height: 16),
              Text(
                l10n.comingSoon,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.comingSoonMessage,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
