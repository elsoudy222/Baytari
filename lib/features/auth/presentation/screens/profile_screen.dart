/// The profile screen: shows the signed-in user's profile, lets
/// them edit their name/phone, and signs them out.
///
/// The screen reads the profile from [AuthCubit] (the single
/// source of truth — the same state the router and the home screen
/// read), so after an edit every screen shows the new values
/// without any refresh. Signing out flips the Cubit to
/// `unauthenticated` and the router redirect sends the user to
/// the login screen; the button itself does no navigation.
///
/// Edit mode is local UI state (`_editing`): the form is only a
/// different view of the same profile, not a different feature.
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../domain/entities/profile.dart';
import '../../domain/entities/user_role.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  bool _editing = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.myProfile)),
      body: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, state) {
          final Profile? profile = state.profile;
          final bool isLoading = state.status == AuthStatus.loading;
          if (profile == null) {
            // No profile: either the session check is still running
            // or the user is not signed in (the redirect normally
            // sends them to login first — this is the safety net).
            return const Center(child: CircularProgressIndicator());
          }
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Card(
                    child: Column(
                      children: <Widget>[
                        ListTile(
                          leading: const Icon(Icons.person_outlined),
                          title: Text(profile.fullName),
                          subtitle: Text(profile.email),
                        ),
                        ListTile(
                          leading: const Icon(Icons.badge_outlined),
                          title: Text(_roleLabel(profile.role)),
                        ),
                        if (profile.phone != null &&
                            profile.phone!.isNotEmpty)
                          ListTile(
                            leading: const Icon(Icons.phone_outlined),
                            title: Text(profile.phone!),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (_editing)
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          TextFormField(
                            controller: _nameController,
                            textInputAction: TextInputAction.next,
                            decoration: InputDecoration(
                              labelText: l10n.fullName,
                            ),
                            validator: (value) =>
                                Validators.isNotEmpty(value)
                                ? null
                                : l10n.nameRequired,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            textInputAction: TextInputAction.done,
                            decoration: InputDecoration(
                              labelText: l10n.phoneOptional,
                            ),
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
                          if (isLoading)
                            const LinearProgressIndicator()
                          else
                            AppButton(
                              label: l10n.save,
                              onPressed: () => _save(profile),
                            ),
                        ],
                      ),
                    )
                  else
                    AppButton(
                      label: l10n.editProfile,
                      onPressed: () {
                        // Prefill the form with the current values.
                        _nameController.text = profile.fullName;
                        _phoneController.text = profile.phone ?? '';
                        setState(() => _editing = true);
                      },
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
                  OutlinedButton(
                    onPressed: isLoading
                        ? null
                        : () => context.read<AuthCubit>().signOut(),
                    child: Text(l10n.logout),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// The role label in the current language. `staffVet` /
  /// `clinicAdmin` cannot be created from the M1 UI, but a row
  /// with such a role could exist in the database — showing its
  /// stored value is better than crashing or lying about it.
  String _roleLabel(UserRole role) {
    return switch (role) {
      UserRole.owner => context.l10n.roleOwner,
      UserRole.vet => context.l10n.roleVet,
      UserRole.staffVet ||
              UserRole.clinicAdmin ||
              UserRole.shelterOwner ||
              UserRole.shelterWorker =>
          role.value,
    };
  }

  Future<void> _save(Profile profile) async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    final String phone = _phoneController.text.trim();
    final AuthCubit cubit = context.read<AuthCubit>();
    await cubit.updateProfile(
      fullName: _nameController.text.trim(),
      phone: phone.isEmpty ? null : phone,
    );
    // Show the confirmation only when the update actually
    // succeeded (no error in the state) and the widget is still
    // on screen (`mounted` — the user could have navigated away
    // while the request was in flight).
    if (!mounted) {
      return;
    }
    if (cubit.state.errorMessage == null) {
      setState(() => _editing = false);
      showAppToast(context, context.l10n.profileSaved);
    }
  }
}
