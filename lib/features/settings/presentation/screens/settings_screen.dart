import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/app_cubit.dart';
import '../../../../app/app_state.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/extensions/context_extensions.dart';

/// Settings screen (M0): language and theme, changed at runtime and
/// persisted by [AppCubit] through `AppSettingsService`.
///
/// `context.read<AppCubit>()` is called *inside* the `BlocBuilder`
/// builder on purpose: the Cubit is read once per rebuild, and the
/// `BlocBuilder` itself listens to the state, so the dropdown and the
/// segmented buttons always show the current saved values.
///
/// `initialValue:` (not `value:`): in this Flutter SDK the `value`
/// parameter of `DropdownButtonFormField` is deprecated — `initialValue`
/// sets the starting selection, and the widget keeps its own selection
/// afterwards. The locale label is chosen with a simple check
/// (`'ar'` → Arabic, anything else → English) because only two
/// languages exist; when a third language is added, this must become
/// a lookup instead of an if/else.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: BlocBuilder<AppCubit, AppState>(
        builder: (context, state) {
          final AppCubit cubit = context.read<AppCubit>();
          return ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              Text(
                l10n.language,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<Locale>(
                initialValue: state.locale,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                items: AppConstants.supportedLocales
                    .map(
                      (Locale locale) => DropdownMenuItem<Locale>(
                        value: locale,
                        child: Text(
                          locale.languageCode == 'ar'
                              ? l10n.arabic
                              : l10n.english,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (Locale? locale) {
                  if (locale != null) {
                    cubit.setLocale(locale);
                  }
                },
              ),
              const SizedBox(height: 24),
              Text(
                l10n.theme,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              SegmentedButton<ThemeMode>(
                segments: <ButtonSegment<ThemeMode>>[
                  ButtonSegment<ThemeMode>(
                    value: ThemeMode.system,
                    label: Text(l10n.themeSystem),
                  ),
                  ButtonSegment<ThemeMode>(
                    value: ThemeMode.light,
                    label: Text(l10n.themeLight),
                  ),
                  ButtonSegment<ThemeMode>(
                    value: ThemeMode.dark,
                    label: Text(l10n.themeDark),
                  ),
                ],
                selected: <ThemeMode>{state.themeMode},
                onSelectionChanged: (Set<ThemeMode> selection) {
                  cubit.setThemeMode(selection.first);
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
