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
  bool _isConfigured = false;

  bool get isConfigured => _isConfigured;

  /// The Supabase client. Throws [SupabaseNotConfiguredException] when
  /// the service was not configured — callers must check [isConfigured].
  SupabaseClient get client {
    if (!_isConfigured) {
      throw const SupabaseNotConfiguredException();
    }
    return Supabase.instance.client;
  }

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
