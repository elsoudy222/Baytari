/// The Home shell: the bottom navigation of Figma's Home
/// screen (Home / Map / Community / Vets / Shelters).
///
/// Only the Home tab is built in this stage — it is the feed.
/// The other four tabs show a "coming soon" placeholder: their
/// features (Map, Community, Vets, Shelters) are later stages
/// (M3/M4/M5), and this stage must not build them.
///
/// An [IndexedStack] keeps every tab's state alive: switching
/// to Map and back does not reload the feed or lose the scroll
/// position.
library;

import 'package:flutter/material.dart';

import '../../../../core/extensions/context_extensions.dart';
import 'coming_soon_screen.dart';
import 'home_screen.dart';

class HomeShellScreen extends StatefulWidget {
  const HomeShellScreen({super.key});

  @override
  State<HomeShellScreen> createState() => _HomeShellScreenState();
}

class _HomeShellScreenState extends State<HomeShellScreen> {
  /// The selected tab (0 = Home). The feed is index 0 so the
  /// shell opens on it.
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: <Widget>[
          const HomeScreen(),
          ComingSoonScreen(title: l10n.mapTab),
          ComingSoonScreen(title: l10n.communityTab),
          ComingSoonScreen(title: l10n.vetsTab),
          ComingSoonScreen(title: l10n.sheltersTab),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: scheme.primary,
        unselectedItemColor: scheme.onSurfaceVariant,
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: const Icon(Icons.home),
            label: l10n.home,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.location_on_outlined),
            label: l10n.mapTab,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.groups_outlined),
            label: l10n.communityTab,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.local_hospital_outlined),
            label: l10n.vetsTab,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.home_work_outlined),
            label: l10n.sheltersTab,
          ),
        ],
      ),
    );
  }
}
