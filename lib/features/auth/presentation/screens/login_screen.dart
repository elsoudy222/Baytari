/// The login screen, redesigned to the Figma `Log_in.png`:
///
/// - "Welcome back!" with the Baytari logo mark (the heading is
///   orange + teal in Figma; here the logo mark carries the brand
///   and the heading uses the dark-teal theme colour).
/// - "Email or Phone Number" field, Password field with a
///   show/hide eye, "Forgot your password?" link.
/// - Teal "Log in" button, "or log in with" divider, Google / X /
///   Facebook buttons (UI only — see [SocialLoginButtons]).
/// - Terms/Privacy footer, demo-mode banner when Supabase is not
///   configured.
///
/// The screen owns only the form. Sign-in lives in
/// [AuthCubit.signIn]; after success the router redirect sends the
/// user to Home. "Email or Phone Number": v1 signs in by EMAIL
/// only (phone sign-in needs an SMS provider) — a phone number
/// typed here is rejected by the email validator with a localized
/// message, and the Arabic doc says so plainly.
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
import '../../../../core/widgets/baytari_logo.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';
import '../widgets/auth_scaffold.dart';
import '../widgets/social_login_buttons.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  /// Password visibility (the eye icon in Figma).
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AuthScaffold(
      title: '',
      showCard: false,
      onBack: () => context.go(AppRoutes.getStarted),
      child: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, state) {
          final bool isLoading = state.status == AuthStatus.loading;
          return Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const SizedBox(height: 8),
                // "Welcome back!" + logo mark (Figma header).
                Row(
                  children: <Widget>[
                    const BaytariLogoMark(size: 44),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l10n.welcomeBack,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Demo-mode banner: visible only when Supabase
                // was not configured at launch.
                BlocBuilder<AppCubit, AppState>(
                  builder: (context, appState) {
                    if (appState.supabaseConfigured) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Card(
                        child: ListTile(
                          leading: const Icon(Icons.cloud_off_outlined),
                          title: Text(l10n.authNotConfigured),
                        ),
                      ),
                    );
                  },
                ),
                AuthTextField(
                  controller: _emailController,
                  hint: l10n.emailOrPhone,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: (value) => Validators.isValidEmail(value ?? '')
                      ? null
                      : l10n.invalidEmail,
                ),
                const SizedBox(height: 16),
                AuthTextField(
                  controller: _passwordController,
                  hint: l10n.password,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                    onPressed: () => setState(
                      () => _obscurePassword = !_obscurePassword,
                    ),
                  ),
                  validator: (value) => Validators.isValidPassword(
                    value ?? '',
                  )
                      ? null
                      : l10n.passwordTooShort,
                  onFieldSubmitted: (_) => _submit(isLoading),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton(
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: () => context.push(AppRoutes.forgotPassword),
                    child: Text(l10n.forgotPassword),
                  ),
                ),
                const SizedBox(height: 16),
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
                    label: l10n.logIn,
                    onPressed: () => _submit(isLoading),
                  ),
                const SizedBox(height: 16),
                SocialLoginButtons(label: l10n.orLogInWith),
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
          );
        },
      ),
    );
  }

  /// Validates the form, then hands the values to the Cubit.
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
