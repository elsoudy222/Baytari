/// App entry point — the first code that runs.
///
/// Startup order matters, so read this file top to bottom:
/// 1. `WidgetsFlutterBinding.ensureInitialized()` — needed because the
///    next lines use platform channels (SharedPreferences) before any
///    widget exists; without it the app would crash on startup.
/// 2. Load `SharedPreferences` and register every dependency with
///    `configureDependencies()` — nothing is created before its
///    dependencies exist (see `injection_container.dart`).
/// 3. Try to initialise Supabase. It is *optional* in M0: if the
///    `--dart-define` keys are missing, `SupabaseService` throws
///    `SupabaseNotConfiguredException`, we only log it, and the app
///    keeps running in demo mode instead of crashing (see below).
/// 4. `runApp(const BaytariApp())` — builds the MaterialApp.
library;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'core/errors/exceptions.dart';
import 'core/services/supabase_service.dart';
import 'injection_container.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final SharedPreferences prefs = await SharedPreferences.getInstance();
  await configureDependencies(prefs);

  // Supabase is optional in M0: the project has not been created yet.
  // If it is not configured, the app still runs in demo mode and the
  // home screen says so clearly — this is not a silent failure.
  try {
    await sl<SupabaseService>().initialize();
  } on SupabaseNotConfiguredException catch (e) {
    // Caught on purpose: a missing Supabase config is an expected M0
    // state, not a programming error, so it is logged, not rethrown.
    debugPrint('Baytari: $e');
  }

  runApp(const BaytariApp());
}
