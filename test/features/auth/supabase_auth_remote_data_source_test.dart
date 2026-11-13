/// Tests for the Supabase auth data source's OTP pairing (B3).
///
/// The recovery flow was broken because `requestPasswordReset`
/// called `signInWithOtp` (which issues a magic-link token) while
/// `verifyRecoveryOtp` verifies with `OtpType.recovery` (which
/// expects a token from `resetPasswordForEmail`). These tests pin
/// the pairing at the Supabase call level, using hand-written
/// fakes — no network, no real Supabase project.
///
/// The fakes subclass the real Supabase classes: `GoTrueClient`
/// has an all-optional constructor, and `SupabaseClient.auth` is
/// an overridable getter, so the fake client only replaces the
/// auth namespace and never touches the network. Auto-refresh is
/// off, and both clients are disposed in `tearDown`.
library;

import 'package:baytari/core/services/supabase_service.dart';
import 'package:baytari/features/auth/data/datasources/supabase_auth_remote_data_source.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Records which GoTrue OTP methods were called, instead of
/// hitting the network. Only the two methods the data source
/// uses for OTP are overridden; everything else is the real
/// client (unused by these tests).
class FakeGoTrueClient extends GoTrueClient {
  FakeGoTrueClient() : super(autoRefreshToken: false);

  /// Emails passed to `resetPasswordForEmail`, in call order.
  final List<String> resetPasswordEmails = <String>[];

  /// Emails passed to `signInWithOtp`, in call order.
  final List<String> otpEmails = <String>[];

  @override
  Future<void> resetPasswordForEmail(
    String email, {
    String? redirectTo,
    String? captchaToken,
  }) async {
    resetPasswordEmails.add(email);
  }

  @override
  Future<void> signInWithOtp({
    String? email,
    String? phone,
    String? emailRedirectTo,
    bool? shouldCreateUser,
    Map<String, dynamic>? data,
    String? captchaToken,
    OtpChannel channel = OtpChannel.sms,
  }) async {
    otpEmails.add(email ?? phone ?? '');
  }
}

/// A Supabase client whose `auth` namespace is [fakeAuth]. The
/// base constructor only builds local clients (no network), and
/// `dispose` shuts the isolate / streams back down.
class FakeSupabaseClient extends SupabaseClient {
  FakeSupabaseClient(this.fakeAuth)
    : super(
        'https://example.supabase.co',
        'fake-anon-key',
        authOptions: const AuthClientOptions(autoRefreshToken: false),
      );

  final FakeGoTrueClient fakeAuth;

  @override
  GoTrueClient get auth => fakeAuth;
}

void main() {
  late FakeGoTrueClient fakeAuth;
  late FakeSupabaseClient fakeClient;
  late SupabaseAuthRemoteDataSource dataSource;

  setUp(() {
    fakeAuth = FakeGoTrueClient();
    fakeClient = FakeSupabaseClient(fakeAuth);
    // The test-only seam on SupabaseService: the data source
    // reads its client from here instead of the global singleton.
    dataSource = SupabaseAuthRemoteDataSource(
      SupabaseService(testClient: fakeClient),
    );
  });

  tearDown(() async {
    await fakeClient.dispose();
    fakeAuth.dispose();
  });

  test('requestPasswordReset uses resetPasswordForEmail, not signInWithOtp',
      () async {
    await dataSource.requestPasswordReset(email: 'test@example.com');

    // The recovery token must come from /recover — only then does
    // `verifyOTP(type: OtpType.recovery)` accept it.
    expect(fakeAuth.resetPasswordEmails, <String>['test@example.com']);
    expect(fakeAuth.otpEmails, isEmpty);
  });

  test('requestSignupOtp still uses signInWithOtp', () async {
    await dataSource.requestSignupOtp(email: 'new@example.com');

    // The sign-up pairing is unchanged: signInWithOtp +
    // OtpType.signup. This test guards against "fixing" it by
    // accident while changing the recovery call.
    expect(fakeAuth.otpEmails, <String>['new@example.com']);
    expect(fakeAuth.resetPasswordEmails, isEmpty);
  });
}
