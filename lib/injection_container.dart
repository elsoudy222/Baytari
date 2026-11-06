import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/di/register_core.dart';

/// The service locator. All dependencies are registered here, in
/// dependency order, and nowhere else. Widgets and Cubits never create
/// their own dependencies — they receive them from this container.
final GetIt sl = GetIt.instance;

Future<void> configureDependencies(SharedPreferences prefs) async {
  registerCore(sl, prefs);

  // Feature registrations (M1+):
  //   auth, pets, vets, appointments, schedule, dashboard, settings.
  // Each feature registers, in order: data source -> repository
  // implementation -> use case -> cubit.
}
