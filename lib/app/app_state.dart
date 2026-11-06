import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import '../core/constants/app_constants.dart';

/// App-level state: theme mode, locale, and whether Supabase is
/// configured. Held by [AppCubit] and consumed by [BaytariApp].
class AppState extends Equatable {
  const AppState({
    this.themeMode = ThemeMode.system,
    this.locale = AppConstants.defaultLocale,
    this.supabaseConfigured = false,
  });

  final ThemeMode themeMode;
  final Locale locale;
  final bool supabaseConfigured;

  AppState copyWith({
    ThemeMode? themeMode,
    Locale? locale,
    bool? supabaseConfigured,
  }) {
    return AppState(
      themeMode: themeMode ?? this.themeMode,
      locale: locale ?? this.locale,
      supabaseConfigured: supabaseConfigured ?? this.supabaseConfigured,
    );
  }

  @override
  List<Object?> get props => <Object?>[themeMode, locale, supabaseConfigured];
}
