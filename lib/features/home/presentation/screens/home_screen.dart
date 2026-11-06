import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_cubit.dart';
import '../../../../app/app_state.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/widgets/app_button.dart';

/// M0 placeholder home shell. It shows only localized strings and
/// theme colors, and links to Settings where language and theme can be
/// changed at runtime. Feature content lands here in M1+.
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
