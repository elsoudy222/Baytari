/// The forgot-password flow, from the Figma screens:
///
/// 1. Reset Your Password (`Forgot_password.png`): "Enter your
///    email address below to receive a one-time password (OTP) for
///    resetting your password", Email field, "Send OTP".
/// 2. Enter Verification Code (`OTP.png` / `OTP-1.png`): 6 boxes
///    (Figma shows 4, but Supabase OTP codes are 6 digits
///    minimum), "Didn't receive code? Resend Code", "Verify Code".
///    A wrong code turns the boxes red with "Wrong Code. Please
///    try again or reset your code."
/// 3. Create New Password (`Create_New_Password.png`): the same
///    live rules checklist as sign-up, Confirm Password,
///    "Confirm New Password".
/// 4. Success (`password_confirmation.png`): "Your Password Was
///    Reset Successfully!" + "Go to Home" (goes to LOGIN — the
///    user is signed out after the reset, see [AuthCubit]).
///
/// Each step is its own route (`/forgot-password`,
/// `/forgot-password/verify`, `/forgot-password/new-password`,
/// `/forgot-password/success`) and this screen takes the step +
/// email as constructor arguments; a [BlocListener] advances the
/// route on the Cubit's one-shot [AuthAction]s.
///
/// EMAIL ONLY: the OTP goes to the user's email. Phone OTP needs
/// an SMS provider and is out of v1 — the design's "Email or
/// Phone Number" field is email-only here, and the Arabic doc
/// says so plainly.
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_toast.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';
import '../widgets/auth_scaffold.dart';
import '../widgets/otp_code_input.dart';
import '../widgets/password_rules.dart';

/// The four forgot-password steps, one per route.
enum ForgotPasswordStep { request, verify, newPassword, success }

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({
    required this.step,
    super.key,
    this.email,
  });

  final ForgotPasswordStep step;

  /// The email the OTP was sent to (steps 2–4).
  final String? email;

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  final OtpCodeController _otpController = OtpCodeController();

  String _passwordText = '';
  bool _otpWrong = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  String get _email =>
      widget.email ?? _emailController.text.trim();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) => _onAuthState(context, state),
      child: AuthScaffold(
        title: switch (widget.step) {
          ForgotPasswordStep.request => l10n.resetYourPassword,
          ForgotPasswordStep.verify => l10n.enterVerificationCode,
          ForgotPasswordStep.newPassword => l10n.createNewPassword,
          ForgotPasswordStep.success => '',
        },
        showCard: false,
        showTermsFooter: widget.step != ForgotPasswordStep.success,
        onBack: () {
          switch (widget.step) {
            case ForgotPasswordStep.request:
              context.go(AppRoutes.login);
            case ForgotPasswordStep.verify:
              context.go(AppRoutes.forgotPassword);
            case ForgotPasswordStep.newPassword:
              context.go(AppRoutes.forgotPasswordVerify, extra: _email);
            case ForgotPasswordStep.success:
              context.go(AppRoutes.login);
          }
        },
        child: BlocBuilder<AuthCubit, AuthState>(
          builder: (context, state) {
            final bool isLoading = state.status == AuthStatus.loading;
            return switch (widget.step) {
              ForgotPasswordStep.request => _requestStep(isLoading, state),
              ForgotPasswordStep.verify => _verifyStep(isLoading),
              ForgotPasswordStep.newPassword => _newPasswordStep(isLoading),
              ForgotPasswordStep.success => _successStep(),
            };
          },
        ),
      ),
    );
  }

  /// Advances the route on Cubit actions; a fresh error on the
  /// verify step means a wrong code.
  void _onAuthState(BuildContext context, AuthState state) {
    if (state.errorMessage != null &&
        widget.step == ForgotPasswordStep.verify) {
      setState(() => _otpWrong = true);
      return;
    }
    if (state.action == AuthAction.otpSent &&
        widget.step == ForgotPasswordStep.request) {
      context.read<AuthCubit>().clearAction();
      context.push(AppRoutes.forgotPasswordVerify, extra: _email);
    } else if (state.action == AuthAction.otpVerified &&
        widget.step == ForgotPasswordStep.verify) {
      context.read<AuthCubit>().clearAction();
      context.push(AppRoutes.forgotPasswordNewPassword, extra: _email);
    } else if (state.action == AuthAction.passwordReset &&
        widget.step == ForgotPasswordStep.newPassword) {
      context.read<AuthCubit>().clearAction();
      context.push(AppRoutes.forgotPasswordSuccess);
    }
  }

  // -- Step 1: request the OTP ------------------------------------------

  Widget _requestStep(bool isLoading, AuthState state) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          l10n.resetPasswordMessage,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        AuthTextField(
          controller: _emailController,
          hint: l10n.emailOrPhone,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => _requestOtp(isLoading),
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
            label: l10n.sendOtp,
            onPressed: () => _requestOtp(isLoading),
          ),
      ],
    );
  }

  void _requestOtp(bool isLoading) {
    if (isLoading) {
      return;
    }
    final String email = _emailController.text.trim();
    if (!Validators.isValidEmail(email)) {
      showAppToast(context, context.l10n.invalidEmail, isError: true);
      return;
    }
    context.read<AuthCubit>().requestPasswordReset(email: email);
  }

  // -- Step 2: verify the code -------------------------------------------

  Widget _verifyStep(bool isLoading) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          l10n.enterVerificationCodeMessage,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 24),
        OtpCodeInput(controller: _otpController, hasError: _otpWrong),
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
                      context.read<AuthCubit>().requestPasswordReset(
                        email: _email,
                      );
                      showAppToast(context, l10n.otpSent);
                    },
              child: Text(l10n.resendCode),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (isLoading)
          const LinearProgressIndicator()
        else
          AppButton(
            label: l10n.verifyCode,
            onPressed: () {
              if (!_otpController.isComplete) {
                return;
              }
              setState(() => _otpWrong = false);
              context.read<AuthCubit>().verifyRecoveryOtp(
                email: _email,
                token: _otpController.code,
              );
            },
          ),
      ],
    );
  }

  // -- Step 3: create the new password ------------------------------------

  Widget _newPasswordStep(bool isLoading) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
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
          onFieldSubmitted: (_) => _submitNewPassword(isLoading),
        ),
        const SizedBox(height: 16),
        if (isLoading)
          const LinearProgressIndicator()
        else
          AppButton(
            label: l10n.confirmNewPassword,
            onPressed: () => _submitNewPassword(isLoading),
          ),
      ],
    );
  }

  void _submitNewPassword(bool isLoading) {
    if (isLoading) {
      return;
    }
    if (!Validators.isStrongPassword(_passwordController.text)) {
      return;
    }
    if (_confirmController.text != _passwordController.text) {
      showAppToast(
        context,
        context.l10n.passwordsDoNotMatch,
        isError: true,
      );
      return;
    }
    context.read<AuthCubit>().resetPassword(
      newPassword: _passwordController.text,
    );
  }

  // -- Step 4: success -----------------------------------------------------

  Widget _successStep() {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const SizedBox(height: 24),
        const Icon(
          Icons.check_circle_outline,
          size: 72,
          color: AppColors.primary,
        ),
        const SizedBox(height: 16),
        Text(
          l10n.passwordResetSuccess,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.passwordResetSuccessMessage,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 24),
        AppButton(
          label: l10n.goToHome,
          onPressed: () => context.go(AppRoutes.login),
        ),
      ],
    );
  }
}
