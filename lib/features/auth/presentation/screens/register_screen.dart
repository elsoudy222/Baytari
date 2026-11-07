/// The register screen: create an account (owner or vet).
///
/// Form fields: full name, email, optional phone, password,
/// confirm password, and the role picker ([RoleSelector]). On
/// submit the values go to [AuthCubit.signUp]; the screen never
/// talks to Supabase itself.
///
/// TWO POSSIBLE OUTCOMES (both handled here):
/// - The user is signed in immediately (email confirmation OFF in
///   Supabase): the router redirect sends them to Home.
/// - The account was created but needs email confirmation (the
///   Supabase default): the Cubit state becomes
///   `awaitingConfirmation` and this screen shows the "check your
///   email" card instead of the form.
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../domain/entities/user_role.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';
import '../widgets/role_selector.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();

  /// The role picked in the form. Owner by default: most users of
  /// the app are pet owners; vets pick their role explicitly.
  UserRole _role = UserRole.owner;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.register)),
      body: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, state) {
          final bool isLoading = state.status == AuthStatus.loading;
          // Confirmation pending: replace the form with the
          // "check your email" message and a way back to login.
          if (state.status == AuthStatus.awaitingConfirmation) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.mark_email_read_outlined),
                      title: Text(l10n.emailConfirmationSent),
                    ),
                  ),
                  const SizedBox(height: 24),
                  AppButton(
                    label: l10n.login,
                    onPressed: () => context.go(AppRoutes.login),
                  ),
                ],
              ),
            );
          }
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Text(l10n.selectRole),
                    const SizedBox(height: 8),
                    RoleSelector(
                      selected: _role,
                      onChanged: (role) => setState(() => _role = role),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: l10n.fullName,
                      ),
                      validator: (value) => Validators.isNotEmpty(value)
                          ? null
                          : l10n.nameRequired,
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
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: l10n.phoneOptional,
                      ),
                      // Phone is optional: an empty field is valid,
                      // a filled one must be a real phone number.
                      validator: (value) {
                        final String text = value ?? '';
                        if (text.trim().isEmpty) {
                          return null;
                        }
                        return Validators.isValidPhone(text)
                            ? null
                            : l10n.invalidPhone;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: l10n.password,
                      ),
                      validator: (value) => Validators.isValidPassword(
                        value ?? '',
                      )
                          ? null
                          : l10n.passwordTooShort,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _confirmController,
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                      decoration: InputDecoration(
                        labelText: l10n.confirmPassword,
                      ),
                      validator: (value) =>
                          value == _passwordController.text
                          ? null
                          : l10n.passwordsDoNotMatch,
                      onFieldSubmitted: (_) => _submit(isLoading),
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
                        label: l10n.register,
                        onPressed: () => _submit(isLoading),
                      ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Text(l10n.alreadyHaveAccount),
                        TextButton(
                          onPressed: () => context.go(AppRoutes.login),
                          child: Text(l10n.login),
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

  void _submit(bool isLoading) {
    if (isLoading) {
      return;
    }
    if (_formKey.currentState?.validate() ?? false) {
      final String phone = _phoneController.text.trim();
      context.read<AuthCubit>().signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        fullName: _nameController.text.trim(),
        role: _role,
        phone: phone.isEmpty ? null : phone,
      );
    }
  }
}
