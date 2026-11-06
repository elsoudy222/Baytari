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
    debugPrint('Baytari: $e');
  }

  runApp(const BaytariApp());
}
