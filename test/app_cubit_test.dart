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

  test('defaults to system theme and Arabic locale', () async {
    final AppCubit cubit = await createCubit();
    await cubit.load();
    expect(cubit.state.themeMode, ThemeMode.system);
    expect(cubit.state.locale, const Locale('ar'));
    expect(cubit.state.supabaseConfigured, isFalse);
    await cubit.close();
  });

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

  test('AppState copyWith keeps unchanged fields', () {
    const AppState state = AppState();
    final AppState updated = state.copyWith(themeMode: ThemeMode.light);
    expect(updated.themeMode, ThemeMode.light);
    expect(updated.locale, const Locale('ar'));
    expect(updated.supabaseConfigured, isFalse);
  });
}
