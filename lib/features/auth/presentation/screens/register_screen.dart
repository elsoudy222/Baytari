/// The sign-up wizard, rebuilt to the Figma sign-up screens.
///
/// ONE screen, SEVEN steps, in the Figma order:
/// 1. Role — three cards: Community Member, Veterinarian, Shelter
///    (`Sign_Up.png`). Illustrations are the simplified
///    onboarding-style placeholders (blob + icon), not the Figma art.
/// 2. Account Information — First/Last Name, Email, Phone with a
///    country-code picker (Egypt +20 by default). Vets pick
///    "Clinic owner / Staff vet", shelters pick "Shelter owner /
///    Shelter worker"; staff/worker get a workplace field
///    ("Pick the clinic/shelter you work with") — there are no
///    clinics/shelters in the database yet, so the name is saved
///    as a pending text note on the profile (see the Arabic doc).
/// 3. Set Your Password — Create + Confirm, with the live rules
///    checklist (8+ chars, upper+lower, a number). Tapping Next
///    CREATES the account via [AuthCubit.signUp].
/// 4. Verify Your License — vet / shelter only: photograph the
///    licence (camera or gallery), Upload Photo / Retake. The
///    photo is uploaded only once a session exists (see below).
/// 5. Email OTP — 6 boxes (Figma shows 4, but Supabase OTP
///    codes are 6 digits minimum — see `otp_code_input.dart`),
///    Resend Code, Skip. The code is sent to EMAIL (phone OTP
///    needs an SMS provider — out of v1).
/// 6. Username + photo — "Welcome To Baytari!", username field,
///    Add Profile Photo, confirm.
/// 7. Confirmation — "Welcome! Your Account is Ready" with the
///    community or vet text, "Go to Home".
///
/// SESSION TIMING (why the licence upload is deferred): when
/// Supabase email confirmation is ON, `signUp` creates the
/// account but returns NO session, so Storage (which requires a
/// signed-in user) cannot accept the licence yet. The wizard
/// therefore holds the photo bytes and uploads them right after
/// the OTP is verified (when the session exists). When
/// confirmation is OFF the session exists immediately and the
/// licence uploads at step 4. Either way the user never re-picks
/// the photo.
///
/// The wizard owns only step state + form controllers. Every
/// server action goes through [AuthCubit]; a [BlocListener]
/// advances the step on the Cubit's one-shot [AuthAction]s.
library;

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/baytari_logo.dart';
import '../../../onboarding/presentation/widgets/onboarding_illustration.dart';
import '../../domain/entities/user_role.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';
import '../widgets/auth_scaffold.dart';
import '../widgets/country_code_picker.dart';
import '../widgets/otp_code_input.dart';
import '../widgets/password_rules.dart';
import '../widgets/social_login_buttons.dart';

/// The wizard steps, in Figma order.
enum _SignUpStep { role, info, password, license, otp, username, done }

/// Which sign-up track the user picked on step 1.
enum _SignUpTrack { community, vet, shelter }

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  _SignUpStep _step = _SignUpStep.role;
  _SignUpTrack _track = _SignUpTrack.community;

  /// Sub-role toggles on the info step: vet track -> clinic owner
  /// (true) or staff vet (false); shelter track -> shelter owner
  /// (true) or shelter worker (false). Community has no sub-role.
  bool _isOwner = true;

  final GlobalKey<FormState> _infoFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _passwordFormKey = GlobalKey<FormState>();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _workplaceController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final OtpCodeController _otpController = OtpCodeController();

  /// The dial code picked in the country picker (Egypt by default).
  CountryCode _country = countryCodes.first;

  /// Live password text, so the rules checklist updates per keystroke.
  String _passwordText = '';

  /// Licence photo bytes, held until a session exists to upload.
  Uint8List? _licenseBytes;

  /// Avatar photo bytes, held until the username step confirms.
  Uint8List? _avatarBytes;

  /// True after a wrong OTP code, for the red "Wrong Code" state.
  bool _otpWrong = false;

  /// True once the OTP was requested for this email, so the wizard
  /// never sends it twice for the same step entry.
  bool _otpRequested = false;

  final ImagePicker _imagePicker = ImagePicker();

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _workplaceController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _usernameController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  /// The final role for the account: track + sub-role toggle.
  UserRole get _role => switch (_track) {
    _SignUpTrack.community => UserRole.owner,
    _SignUpTrack.vet => _isOwner ? UserRole.vet : UserRole.staffVet,
    _SignUpTrack.shelter =>
      _isOwner ? UserRole.shelterOwner : UserRole.shelterWorker,
  };

  /// True for the vet/shelter tracks, which need licence verification.
  bool get _needsLicense => _track != _SignUpTrack.community;

  String get _fullName =>
      '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}'
          .trim();

  String get _phone {
    final String local = _phoneController.text.trim();
    if (local.isEmpty) {
      return '';
    }
    return '${_country.dialCode} $local';
  }

  String? get _workplaceNote {
    if (_isOwner) {
      return null;
    }
    final String name = _workplaceController.text.trim();
    if (name.isEmpty) {
      return null;
    }
    // Pending note until clinics/shelters exist in the database.
    return _track == _SignUpTrack.vet
        ? 'Staff vet — clinic: $name'
        : 'Shelter worker — shelter: $name';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) => _onAuthState(context, state),
      child: AuthScaffold(
        title: l10n.signUp,
        onBack: _onBack,
        child: BlocBuilder<AuthCubit, AuthState>(
          builder: (context, state) {
            final bool isLoading = state.status == AuthStatus.loading;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                if (isLoading) const LinearProgressIndicator(),
                if (state.errorMessage != null && _step != _SignUpStep.otp)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      l10n.authError,
                      style: TextStyle(color: context.colors.error),
                    ),
                  ),
                switch (_step) {
                  _SignUpStep.role => _RoleStep(
                    onPick: (track) {
                      setState(() {
                        _track = track;
                        _isOwner = true;
                        _step = _SignUpStep.info;
                      });
                    },
                  ),
                  _SignUpStep.info => _infoStep(isLoading),
                  _SignUpStep.password => _passwordStep(isLoading),
                  _SignUpStep.license => _licenseStep(isLoading),
                  _SignUpStep.otp => _otpStep(isLoading),
                  _SignUpStep.username => _usernameStep(isLoading),
                  _SignUpStep.done => _doneStep(),
                },
              ],
            );
          },
        ),
      ),
    );
  }

  /// Reacts to Cubit results: advances the wizard on success.
  void _onAuthState(BuildContext context, AuthState state) {
    // A fresh error on the OTP step means a wrong code.
    if (state.errorMessage != null && _step == _SignUpStep.otp) {
      setState(() => _otpWrong = true);
      return;
    }
    switch (state.status) {
      case AuthStatus.awaitingConfirmation:
        // Account created, email confirmation ON: send the OTP
        // code and show the code boxes.
        if (_step == _SignUpStep.password && !_otpRequested) {
          _otpRequested = true;
          context.read<AuthCubit>().requestSignupOtp(
            email: _emailController.text.trim(),
          );
          setState(() => _step = _SignUpStep.otp);
        }
      case AuthStatus.authenticated:
        if (_step == _SignUpStep.password) {
          // Confirmation OFF: signed in immediately — skip OTP.
          setState(
            () => _step = _needsLicense
                ? _SignUpStep.license
                : _SignUpStep.username,
          );
        } else if (state.action == AuthAction.otpVerified &&
            _step == _SignUpStep.otp) {
          // OTP verified: session exists now — upload a held
          // licence photo, then continue to the username step.
          context.read<AuthCubit>().clearAction();
          _uploadPendingLicense().then((_) {
            if (mounted) {
              setState(() => _step = _SignUpStep.username);
            }
          });
        } else if (state.action == AuthAction.profileCompleted &&
            _step == _SignUpStep.username) {
          context.read<AuthCubit>().clearAction();
          setState(() => _step = _SignUpStep.done);
        }
      case AuthStatus.initial ||
          AuthStatus.loading ||
          AuthStatus.unauthenticated:
        break;
    }
  }

  /// Uploads the held licence photo (if any) and saves its path
  /// on the profile. Only runs when a session exists.
  Future<void> _uploadPendingLicense() async {
    final Uint8List? bytes = _licenseBytes;
    if (bytes == null) {
      return;
    }
    final String? path = await context.read<AuthCubit>().uploadLicense(
      bytes,
    );
    if (path != null && mounted) {
      await context.read<AuthCubit>().updateProfile(
        fullName: _fullName,
        phone: _phone.isEmpty ? null : _phone,
        licenseUrl: path,
      );
    }
  }

  /// Back: previous wizard step, or the Get Started screen from step 1.
  void _onBack() {
    if (_step == _SignUpStep.role) {
      context.go(AppRoutes.getStarted);
      return;
    }
    setState(() {
      _step = switch (_step) {
        _SignUpStep.role => _SignUpStep.role,
        _SignUpStep.info => _SignUpStep.role,
        _SignUpStep.password => _SignUpStep.info,
        _SignUpStep.license => _SignUpStep.password,
        _SignUpStep.otp => _SignUpStep.password,
        _SignUpStep.username => _needsLicense
            ? _SignUpStep.license
            : _SignUpStep.password,
        _SignUpStep.done => _SignUpStep.username,
      };
    });
  }

  // -- Step 2: Account Information -------------------------------------

  Widget _infoStep(bool isLoading) {
    final l10n = context.l10n;
    return Form(
      key: _infoFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _StepIllustration(track: _track),
          const SizedBox(height: 12),
          Text(
            l10n.accountInformation,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          if (_track != _SignUpTrack.community) ...<Widget>[
            _SubRoleToggle(
              firstLabel: _track == _SignUpTrack.vet
                  ? l10n.clinicOwner
                  : l10n.shelterOwner,
              secondLabel: _track == _SignUpTrack.vet
                  ? l10n.staffVet
                  : l10n.shelterWorker,
              isFirst: _isOwner,
              onChanged: (value) => setState(() => _isOwner = value),
            ),
            const SizedBox(height: 16),
            if (!_isOwner) ...<Widget>[
              AuthTextField(
                controller: _workplaceController,
                hint: _track == _SignUpTrack.vet
                    ? l10n.pickClinic
                    : l10n.pickShelter,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.workplaceComingSoon,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.subtitle,
                ),
              ),
              const SizedBox(height: 8),
            ],
          ],
          AuthTextField(
            controller: _firstNameController,
            hint: l10n.firstName,
            textInputAction: TextInputAction.next,
            validator: (value) =>
                Validators.isNotEmpty(value) ? null : l10n.nameRequired,
          ),
          const SizedBox(height: 16),
          AuthTextField(
            controller: _lastNameController,
            hint: l10n.lastName,
            textInputAction: TextInputAction.next,
            validator: (value) =>
                Validators.isNotEmpty(value) ? null : l10n.nameRequired,
          ),
          const SizedBox(height: 16),
          AuthTextField(
            controller: _emailController,
            hint: l10n.email,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            validator: (value) =>
                Validators.isValidEmail(value ?? '') ? null : l10n.invalidEmail,
          ),
          const SizedBox(height: 16),
          AuthTextField(
            controller: _phoneController,
            hint: l10n.phoneNumber,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.done,
            prefixIcon: _CountryPrefix(
              country: _country,
              onTap: () async {
                final CountryCode? picked =
                    await showCountryCodePicker(context);
                if (picked != null) {
                  setState(() => _country = picked);
                }
              },
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
          AppButton(
            label: l10n.next,
            onPressed: isLoading
                ? null
                : () {
                    if (_infoFormKey.currentState?.validate() ?? false) {
                      setState(() => _step = _SignUpStep.password);
                    }
                  },
          ),
          const SizedBox(height: 16),
          SocialLoginButtons(label: l10n.orSignUpWith),
        ],
      ),
    );
  }

  // -- Step 3: Set Your Password ----------------------------------------

  Widget _passwordStep(bool isLoading) {
    final l10n = context.l10n;
    return Form(
      key: _passwordFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _StepIllustration(track: _track),
          const SizedBox(height: 12),
          Text(
            l10n.setYourPassword,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          AuthTextField(
            controller: _passwordController,
            hint: l10n.createPassword,
            obscureText: true,
            textInputAction: TextInputAction.next,
            onChanged: (value) => setState(() => _passwordText = value),
          ),
          const SizedBox(height: 12),
          PasswordRulesChecklist(password: _passwordText),
          const SizedBox(height: 16),
          AuthTextField(
            controller: _confirmController,
            hint: l10n.confirmPassword,
            obscureText: true,
            textInputAction: TextInputAction.done,
            validator: (value) => value == _passwordController.text
                ? null
                : l10n.passwordsDoNotMatch,
            onFieldSubmitted: (_) => _submitPassword(isLoading),
          ),
          const SizedBox(height: 16),
          AppButton(
            label: l10n.next,
            onPressed: isLoading ? null : () => _submitPassword(isLoading),
          ),
        ],
      ),
    );
  }

  /// Creates the account (the Cubit + listener move the wizard on).
  void _submitPassword(bool isLoading) {
    if (isLoading) {
      return;
    }
    if (!(_passwordFormKey.currentState?.validate() ?? false)) {
      return;
    }
    if (!Validators.isStrongPassword(_passwordController.text)) {
      // The checklist shows which rule is missing; the form stays.
      return;
    }
    final String phone = _phone;
    context.read<AuthCubit>().signUp(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      fullName: _fullName,
      role: _role,
      phone: phone.isEmpty ? null : phone,
      workplaceNote: _workplaceNote,
    );
  }

  // -- Step 4: Verify Your License (vet / shelter only) -----------------

  Widget _licenseStep(bool isLoading) {
    final l10n = context.l10n;
    final bool hasPhoto = _licenseBytes != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          l10n.verifyYourLicense,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: isLoading ? null : _pickLicensePhoto,
          child: Container(
            height: 200,
            decoration: BoxDecoration(
              color: context.isDark
                  ? AppColors.darkBackground
                  : AppColors.background,
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.center,
            child: hasPhoto
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.memory(
                      _licenseBytes!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      const Icon(
                        Icons.photo_camera_outlined,
                        size: 48,
                        color: AppColors.primary,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.takeLicensePhoto,
                        style: Theme.of(context).textTheme.bodyMedium
                            ?.copyWith(color: AppColors.subtitle),
                      ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 16),
        AppButton(
          label: hasPhoto ? l10n.uploadPhoto : l10n.takeLicensePhoto,
          onPressed: isLoading ? null : _pickLicensePhoto,
        ),
        if (hasPhoto) ...<Widget>[
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: isLoading ? null : _pickLicensePhoto,
            child: Text(l10n.retake),
          ),
        ],
        const SizedBox(height: 12),
        AppButton(
          label: l10n.next,
          onPressed: isLoading
              ? null
              : () async {
                  // No photo yet: the licence is required for
                  // vet/shelter accounts — stay on this step.
                  if (_licenseBytes == null) {
                    showAppToast(
                      context,
                      l10n.licenseRequired,
                      isError: true,
                    );
                    return;
                  }
                  // Session already exists (confirmation OFF):
                  // upload now, then continue to the username step.
                  if (context.read<AuthCubit>().state.isAuthenticated) {
                    await _uploadPendingLicense();
                    if (!mounted) {
                      return;
                    }
                    setState(() => _step = _SignUpStep.username);
                    return;
                  }
                  // Confirmation ON: no session yet — the photo is
                  // held and uploaded right after OTP verification.
                  setState(() => _step = _SignUpStep.otp);
                  context.read<AuthCubit>().requestSignupOtp(
                    email: _emailController.text.trim(),
                  );
                },
        ),
      ],
    );
  }

  /// Camera or gallery, then keep the JPEG bytes for upload.
  Future<void> _pickLicensePhoto() async {
    final ImageSource? source = await _pickPhotoSource();
    if (source == null) {
      return;
    }
    final XFile? file = await _imagePicker.pickImage(
      source: source,
      maxWidth: 1024,
      imageQuality: 80,
    );
    if (file == null) {
      return;
    }
    final Uint8List bytes = await file.readAsBytes();
    setState(() => _licenseBytes = bytes);
  }

  // -- Step 5: Email OTP -------------------------------------------------

  Widget _otpStep(bool isLoading) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _StepIllustration(track: _track),
        const SizedBox(height: 12),
        Text(
          l10n.verifyYourEmail,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.subtitle,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.emailOnlyOtp,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.subtitle,
          ),
        ),
        const SizedBox(height: 24),
        OtpCodeInput(
          controller: _otpController,
          hasError: _otpWrong,
        ),
        if (_otpWrong) ...<Widget>[
          const SizedBox(height: 12),
          Text(
            l10n.wrongCode,
            style: TextStyle(color: context.colors.error),
          ),
        ],
        const SizedBox(height: 16),
        Row(
          children: <Widget>[
            Text(
              l10n.didNotReceiveCode,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            TextButton(
              onPressed: isLoading
                  ? null
                  : () {
                      setState(() => _otpWrong = false);
                      context.read<AuthCubit>().requestSignupOtp(
                        email: _emailController.text.trim(),
                      );
                      showAppToast(context, l10n.otpSent);
                    },
              child: Text(l10n.resendCode),
            ),
          ],
        ),
        const SizedBox(height: 8),
        AppButton(
          label: l10n.verify,
          onPressed: isLoading
              ? null
              : () {
                  if (!_otpController.isComplete) {
                    return;
                  }
                  setState(() => _otpWrong = false);
                  context.read<AuthCubit>().verifySignupOtp(
                    email: _emailController.text.trim(),
                    token: _otpController.code,
                  );
                },
        ),
        const SizedBox(height: 12),
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: TextButton(
            onPressed: () {
              // Skip verification: the account exists, the user
              // can verify later from the email link — send them
              // to log in instead of leaving them stuck.
              context.go(AppRoutes.login);
              showAppToast(context, l10n.emailConfirmationSent);
            },
            child: Text(l10n.skip),
          ),
        ),
      ],
    );
  }

  // -- Step 6: Username + photo ------------------------------------------

  Widget _usernameStep(bool isLoading) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const BaytariLogoMark(size: 56),
        const SizedBox(height: 12),
        Text(
          l10n.welcomeToBaytari,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.pickUsernameMessage,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.subtitle,
          ),
        ),
        const SizedBox(height: 24),
        GestureDetector(
          onTap: isLoading ? null : _pickAvatarPhoto,
          child: Column(
            children: <Widget>[
              CircleAvatar(
                radius: 44,
                backgroundColor: AppColors.peach,
                backgroundImage: _avatarBytes != null
                    ? MemoryImage(_avatarBytes!)
                    : null,
                child: _avatarBytes == null
                    ? const Icon(
                        Icons.photo_camera_outlined,
                        size: 36,
                        color: AppColors.primary,
                      )
                    : null,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.addProfilePhoto,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        AuthTextField(
          controller: _usernameController,
          hint: l10n.username,
          textInputAction: TextInputAction.done,
          validator: null,
        ),
        const SizedBox(height: 16),
        AppButton(
          label: l10n.confirm,
          onPressed: isLoading
              ? null
              : () async {
                  if (_usernameController.text.trim().isEmpty) {
                    showAppToast(
                      context,
                      l10n.usernameRequired,
                      isError: true,
                    );
                    return;
                  }
                  // Upload the photo first (if any), then save
                  // username + avatar URL on the profile.
                  String? avatarUrl;
                  if (_avatarBytes != null) {
                    avatarUrl = await context
                        .read<AuthCubit>()
                        .uploadAvatar(_avatarBytes!);
                    if (avatarUrl == null && mounted) {
                      // Upload failed: the error is in state; stop.
                      return;
                    }
                  }
                  if (!mounted) {
                    return;
                  }
                  await context.read<AuthCubit>().completeProfile(
                    username: _usernameController.text.trim(),
                    avatarUrl: avatarUrl,
                  );
                },
        ),
      ],
    );
  }

  /// Camera or gallery for the avatar photo.
  Future<void> _pickAvatarPhoto() async {
    final ImageSource? source = await _pickPhotoSource();
    if (source == null) {
      return;
    }
    final XFile? file = await _imagePicker.pickImage(
      source: source,
      maxWidth: 512,
      imageQuality: 80,
    );
    if (file == null) {
      return;
    }
    final Uint8List bytes = await file.readAsBytes();
    setState(() => _avatarBytes = bytes);
  }

  /// Camera / gallery chooser (bottom sheet, localized labels).
  Future<ImageSource?> _pickPhotoSource() async {
    final l10n = context.l10n;
    return showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text(l10n.camera),
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(l10n.gallery),
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.close),
              title: Text(l10n.cancel),
              onTap: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }

  // -- Step 7: Confirmation ----------------------------------------------

  Widget _doneStep() {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const _StepIllustration(track: _SignUpTrack.community),
        const SizedBox(height: 16),
        Text(
          l10n.accountReady,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _track == _SignUpTrack.community
              ? l10n.accountReadyCommunity
              : l10n.accountReadyVet,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.subtitle,
          ),
        ),
        const SizedBox(height: 24),
        AppButton(
          label: l10n.goToHome,
          onPressed: () => context.go(AppRoutes.home),
        ),
      ],
    );
  }
}

/// Step 1: the three role cards (Figma `Sign_Up.png`).
class _RoleStep extends StatelessWidget {
  const _RoleStep({required this.onPick});

  final ValueChanged<_SignUpTrack> onPick;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: _RoleCard(
                label: l10n.communityMember,
                variant: OnboardingIllustration.impact,
                onTap: () => onPick(_SignUpTrack.community),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _RoleCard(
                label: l10n.veterinarian,
                variant: OnboardingIllustration.vetClinics,
                onTap: () => onPick(_SignUpTrack.vet),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: <Widget>[
            Expanded(
              child: _RoleCard(
                label: l10n.shelter,
                variant: OnboardingIllustration.shelter,
                onTap: () => onPick(_SignUpTrack.shelter),
              ),
            ),
            const Spacer(),
          ],
        ),
      ],
    );
  }
}

/// One role card: white rounded card, Figma SVG illustration on
/// top, label below (Figma layout).
class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.label,
    required this.variant,
    required this.onTap,
  });

  final String label;
  final OnboardingIllustration variant;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: context.isDark
              ? AppColors.darkBackground
              : AppColors.background,
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          children: <Widget>[
            SizedBox(
              height: 110,
              child: OnboardingIllustrationWidget(variant: variant),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The two-choice toggle on the info step ("Clinic owner /
/// Staff vet", "Shelter owner / Shelter worker"): two checkboxes,
/// exactly one checked — the Figma design uses checkboxes, not a
/// segmented control.
class _SubRoleToggle extends StatelessWidget {
  const _SubRoleToggle({
    required this.firstLabel,
    required this.secondLabel,
    required this.isFirst,
    required this.onChanged,
  });

  final String firstLabel;
  final String secondLabel;
  final bool isFirst;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: _CheckOption(
            label: firstLabel,
            checked: isFirst,
            onTap: () => onChanged(true),
          ),
        ),
        Expanded(
          child: _CheckOption(
            label: secondLabel,
            checked: !isFirst,
            onTap: () => onChanged(false),
          ),
        ),
      ],
    );
  }
}

class _CheckOption extends StatelessWidget {
  const _CheckOption({
    required this.label,
    required this.checked,
    required this.onTap,
  });

  final String label;
  final bool checked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: <Widget>[
          Checkbox(
            value: checked,
            onChanged: (_) => onTap(),
            activeColor: AppColors.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          Expanded(child: Text(label)),
        ],
      ),
    );
  }
}

/// The illustration header of the info / password / OTP steps
/// (Figma shows the role illustration above the form).
class _StepIllustration extends StatelessWidget {
  const _StepIllustration({required this.track});

  final _SignUpTrack track;

  @override
  Widget build(BuildContext context) {
    final OnboardingIllustration variant = switch (track) {
      _SignUpTrack.community => OnboardingIllustration.impact,
      _SignUpTrack.vet => OnboardingIllustration.vetClinics,
      _SignUpTrack.shelter => OnboardingIllustration.shelter,
    };
    return SizedBox(
      height: 150,
      child: OnboardingIllustrationWidget(variant: variant),
    );
  }
}

/// The country-code prefix inside the phone field ("🇪🇬 +20").
class _CountryPrefix extends StatelessWidget {
  const _CountryPrefix({required this.country, required this.onTap});

  final CountryCode country;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsetsDirectional.only(start: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(country.flag, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 4),
            Text(country.dialCode),
            const SizedBox(width: 4),
            Container(width: 1, height: 24, color: AppColors.mintBorder),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }
}
