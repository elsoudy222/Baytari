/// The login screen: email + password form.
///
/// The screen owns only the form (controllers, validation, and
/// which button was tapped). The actual sign-in lives in
/// [AuthCubit.signIn] — the screen never calls Supabase or a
/// repository. After a successful sign-in the router's redirect
/// (see `AppRouter`) sends the user to Home automatically, because
/// the auth status changed to `authenticated`.
///
/// The demo-mode banner (Supabase not configured) is shown from
/// [AppState.supabaseConfigured]: in demo mode the form still
/// works, but signing in fails with a "not configured" message
/// instead of crashing — the app never pretends login works.
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_cubit.dart';
import '../../../../app/app_state.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.login)),
      body: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, state) {
          final bool isLoading = state.status == AuthStatus.loading;
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    // Demo-mode banner: visible only when Supabase
                    // was not configured at launch.
                    BlocBuilder<AppCubit, AppState>(
                      builder: (context, appState) {
                        if (appState.supabaseConfigured) {
                          return const SizedBox.shrink();
                        }
                        return Card(
                          child: ListTile(
                            leading: const Icon(Icons.cloud_off_outlined),
                            title: Text(l10n.authNotConfigured),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(labelText: l10n.email),
                      validator: (value) => Validators.isValidEmail(
                        value ?? '',
                      )
                          ? null
                          : l10n.invalidEmail,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                      decoration: InputDecoration(labelText: l10n.password),
                      validator: (value) => Validators.isValidPassword(
                        value ?? '',
                      )
                          ? null
                          : l10n.passwordTooShort,
                      onFieldSubmitted: (_) => _submit(isLoading),
                    ),
                    const SizedBox(height: 16),
                    // The technical message stays in the state for
                    // logging; the user sees the localized text.
                    if (state.errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(
                          l10n.authError,
                          style: TextStyle(color: context.colors.error),
                        ),
                      ),
                    if (isLoading)
                      const LinearProgressIndicator()
                    else
                      AppButton(
                        label: l10n.login,
                        onPressed: () => _submit(isLoading),
                      ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Text(l10n.noAccount),
                        TextButton(
                          onPressed: () => context.go(AppRoutes.register),
                          child: Text(l10n.register),
                        ),
                      ],
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

  /// Validates the form, then hands the values to the Cubit.
  /// `_formKey.currentState!.validate()` runs every field's
  /// `validator` and shows the error under the field if any fails.
  void _submit(bool isLoading) {
    if (isLoading) {
      return;
    }
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthCubit>().signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
    }
  }
}
