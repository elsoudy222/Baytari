/// App-level state: theme mode, locale, and whether Supabase is
/// configured. Held by [AppCubit] and consumed by [BaytariApp].
///
/// The state is immutable — it is never edited in place. Every change
/// goes through [copyWith], which returns a *new* [AppState] with only
/// the given fields replaced. [Equatable] compares the three fields in
/// [props], so `BlocBuilder` rebuilds only when something actually
/// changed (emitting an identical state does nothing).
library;

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import '../core/constants/app_constants.dart';
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
