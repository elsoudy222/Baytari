/// Dependency-injection entry point (GetIt).
///
/// `sl` is the single service locator for the whole app. Every class
/// that needs a service asks for it here (`sl<AppCubit>()`) instead of
/// creating it with `new` — that is what makes the code testable and
/// keeps the layers separate: a Cubit never constructs its own
/// repository, and a widget never constructs its own Cubit.
///
/// Registration order is dependency order: a service is registered
/// only after everything it needs already exists. The actual
/// registrations live in `core/di/register_core.dart` (core) and, from
/// M1 on, in one `register<Feature>()` function per feature.
library;

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
