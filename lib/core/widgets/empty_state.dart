import 'package:flutter/material.dart';

/// Shared empty state. The message is supplied by the caller as a
/// localized string — never hardcoded here.
///
/// The caller decides *what* "empty" means for its screen (no pets, no
/// appointments, no results) and passes the matching localized text;
/// this widget only decides *how* an empty state looks, in one place.
class EmptyState extends StatelessWidget {
  const EmptyState({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(message, textAlign: TextAlign.center),
      ),
    );
  }
}
