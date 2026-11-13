import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../constants/supabase_constants.dart';
import '../errors/exceptions.dart';

/// Owns the Supabase client lifecycle.
///
/// The URL and anon key come from `--dart-define` only — they are never
/// hardcoded and never read from a file in the repo. If they are missing,
/// [initialize] throws [SupabaseNotConfiguredException]; `main.dart`
/// catches that and lets the app run in a clearly-marked demo mode
/// ([isConfigured] == false) instead of crashing.
class SupabaseService {
  /// Test-only seam: a client to return from [client] instead of
  /// the global `Supabase.instance.client`. Production code never
  /// passes one (GetIt registers `SupabaseService()` with no
  /// arguments) — it exists so data-source tests can inject a fake
  /// client without initializing real Supabase.
  SupabaseService({this.testClient});

  final SupabaseClient? testClient;

  bool _isConfigured = false;

  bool get isConfigured => _isConfigured;

  /// The Supabase client. Throws [SupabaseNotConfiguredException] when
  /// the service was not configured — callers must check [isConfigured].
  SupabaseClient get client {
    final SupabaseClient? override = testClient;
    if (override != null) {
      return override;
    }
    if (!_isConfigured) {
      throw const SupabaseNotConfiguredException();
    }
    return Supabase.instance.client;
  }

  /// Initialises Supabase from the `--dart-define` values.
  ///
  /// `String.fromEnvironment` reads values baked in at *compile* time
  /// (when you run `flutter run --dart-define ...`), not at runtime —
  /// that is why the keys are never in a file in the repo and never
  /// typed in chat.
  ///
  /// `publishableKey:` (not `anonKey:`): in supabase_flutter 2.18 the
  /// parameter was renamed — the key itself is still the same anon /
  /// publishable key from the Supabase dashboard, only the parameter
  /// name changed. The `--dart-define` name stays `SUPABASE_ANON_KEY`
  /// so the run command does not change.
  Future<void> initialize() async {
    const String url = String.fromEnvironment(
      SupabaseConstants.urlDefineKey,
    );
    const String anonKey = String.fromEnvironment(
      SupabaseConstants.anonKeyDefineKey,
    );
    if (url.isEmpty || anonKey.isEmpty) {
      debugPrint(
        'Baytari: Supabase not configured — run with '
        '--dart-define SUPABASE_URL=... '
        '--dart-define SUPABASE_ANON_KEY=...',
      );
      throw const SupabaseNotConfiguredException();
    }
    await Supabase.initialize(url: url, publishableKey: anonKey);
    _isConfigured = true;
  }
}
