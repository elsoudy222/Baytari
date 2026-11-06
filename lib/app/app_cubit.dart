import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/services/app_settings_service.dart';
import '../core/services/supabase_service.dart';
import 'app_state.dart';

/// App-level Cubit: theme mode + locale, persisted through
/// [AppSettingsService]. It contains no business logic and no API calls.
class AppCubit extends Cubit<AppState> {
  AppCubit(this._settings, this._supabase) : super(const AppState());

  final AppSettingsService _settings;
  final SupabaseService _supabase;

  /// Loads persisted settings (or the defaults: system theme, Arabic).
  Future<void> load() async {
    emit(
      state.copyWith(
        themeMode: _settings.getThemeMode(),
        locale: _settings.getLocale(),
        supabaseConfigured: _supabase.isConfigured,
      ),
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    await _settings.setThemeMode(mode);
    emit(state.copyWith(themeMode: mode));
  }

  Future<void> setLocale(Locale locale) async {
    await _settings.setLocale(locale);
    emit(state.copyWith(locale: locale));
  }
}
