/// Unit tests for [AppCubit] — theme and locale, and their persistence.
///
/// These are *unit* tests, not widget tests: they create the Cubit
/// directly, with a real [AppSettingsService] backed by mock
/// SharedPreferences (see `setUp` below).
///
/// `SharedPreferences.setMockInitialValues({})` replaces the real
/// on-device storage with an empty in-memory map, so the tests never
/// touch the device and always start from the defaults. `createCubit()`
/// builds a fresh Cubit on the *same* mock storage, which is how the
/// "persisted across a new cubit" tests prove that a value was really
/// saved — a second Cubit, created later, reads the same storage and
/// must see the changed value.
library;

import 'package:baytari/app/app_cubit.dart';
import 'package:baytari/app/app_state.dart';
import 'package:baytari/core/services/app_settings_service.dart';
import 'package:baytari/core/services/supabase_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late AppSettingsService settings;
  late SupabaseService supabase;

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    supabase = SupabaseService();
  });

  Future<AppCubit> createCubit() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    settings = AppSettingsService(prefs);
    return AppCubit(settings, supabase);
  }

  // Default state on a fresh install: the system theme, Arabic, and
  // Supabase not configured (the tests never pass --dart-define keys).
  test('defaults to system theme and Arabic locale', () async {
    final AppCubit cubit = await createCubit();
    await cubit.load();
    expect(cubit.state.themeMode, ThemeMode.system);
    expect(cubit.state.locale, const Locale('ar'));
    expect(cubit.state.supabaseConfigured, isFalse);
    await cubit.close();
  });

  // Change the theme, close the Cubit, create a *new* Cubit on the
  // same mock storage: it must load the saved dark theme, proving the
  // value was persisted and not just held in memory.
  test('theme change is persisted across a new cubit', () async {
    final AppCubit cubit = await createCubit();
    await cubit.load();
    await cubit.setThemeMode(ThemeMode.dark);
    expect(cubit.state.themeMode, ThemeMode.dark);
    await cubit.close();

    final AppCubit reloaded = await createCubit();
    await reloaded.load();
    expect(reloaded.state.themeMode, ThemeMode.dark);
    await reloaded.close();
  });

  // Same persistence proof as the theme test, but for the locale.
  test('locale change is persisted across a new cubit', () async {
    final AppCubit cubit = await createCubit();
    await cubit.load();
    await cubit.setLocale(const Locale('en'));
    expect(cubit.state.locale, const Locale('en'));
    await cubit.close();

    final AppCubit reloaded = await createCubit();
    await reloaded.load();
    expect(reloaded.state.locale, const Locale('en'));
    await reloaded.close();
  });

  // `copyWith` must replace only the fields it is given and keep the
  // rest — a Cubit that emits a state with a reset locale would flip
  // the whole app back to Arabic on every theme change.
  test('AppState copyWith keeps unchanged fields', () {
    const AppState state = AppState();
    final AppState updated = state.copyWith(themeMode: ThemeMode.light);
    expect(updated.themeMode, ThemeMode.light);
    expect(updated.locale, const Locale('ar'));
    expect(updated.supabaseConfigured, isFalse);
  });
}
