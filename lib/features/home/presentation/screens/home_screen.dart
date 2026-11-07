import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_cubit.dart';
import '../../../../app/app_state.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';

/// M0 placeholder home shell. It shows only localized strings and
/// theme colors, and links to Settings where language and theme can be
/// changed at runtime. Feature content lands here in M1+.
///
/// Layout, in order: `LayoutBuilder` measures the screen, then a
/// `SingleChildScrollView` + `ConstrainedBox(minHeight: ...)` make the
/// content scroll on small screens (and when the keyboard is open)
/// while still filling the screen on large ones. The `BlocBuilder`
/// wraps *only* the Supabase status card, so a theme/language change
/// rebuilds just that card, not the whole screen. The button uses
/// `context.go(AppRoutes.settings)` — declarative navigation through
/// the central router, never `Navigator.push` with a hardcoded path.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.appTitle)),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      l10n.welcome,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(l10n.welcomeMessage),
                    const SizedBox(height: 16),
                    Text(l10n.homeDescription),
                    const SizedBox(height: 24),
                    BlocBuilder<AppCubit, AppState>(
                      builder: (context, state) {
                        return Card(
                          child: ListTile(
                            leading: Icon(
                              state.supabaseConfigured
                                  ? Icons.cloud_done_outlined
                                  : Icons.cloud_off_outlined,
                            ),
                            title: Text(
                              state.supabaseConfigured
                                  ? l10n.supabaseConfigured
                                  : l10n.supabaseNotConfigured,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    // Auth entry point (M1): signed-in users see
                    // their name and a link to their profile;
                    // everyone else gets the sign-in button.
                    BlocBuilder<AuthCubit, AuthState>(
                      builder: (context, authState) {
                        if (authState.isAuthenticated &&
                            authState.profile != null) {
                          return Card(
                            child: ListTile(
                              leading: const Icon(Icons.person_outlined),
                              title: Text(authState.profile!.fullName),
                              trailing: TextButton(
                                onPressed: () =>
                                    context.go(AppRoutes.profile),
                                child: Text(l10n.myProfile),
                              ),
                            ),
                          );
                        }
                        return AppButton(
                          label: l10n.login,
                          onPressed: () => context.go(AppRoutes.login),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    AppButton(
                      label: l10n.settings,
                      onPressed: () => context.go(AppRoutes.settings),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
