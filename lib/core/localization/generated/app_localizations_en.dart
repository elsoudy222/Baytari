// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Baytari';

  @override
  String get arabic => 'Arabic';

  @override
  String get emptyTitle => 'Nothing here yet';

  @override
  String get english => 'English';

  @override
  String get errorTitle => 'Something went wrong';

  @override
  String get home => 'Home';

  @override
  String get homeDescription =>
      'This is the M0 scaffold. Features will be added one at a time: auth, pets, vets, appointments, schedule, dashboard and settings.';

  @override
  String get language => 'Language';

  @override
  String get loading => 'Loading…';

  @override
  String get retry => 'Retry';

  @override
  String get settings => 'Settings';

  @override
  String get supabaseConfigured => 'Supabase is configured.';

  @override
  String get supabaseNotConfigured =>
      'Supabase is not configured yet. The app is running in demo mode.';

  @override
  String get theme => 'Theme';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeLight => 'Light';

  @override
  String get themeSystem => 'System';

  @override
  String get welcome => 'Welcome to Baytari';

  @override
  String get welcomeMessage =>
      'Find a vet and book an appointment for your pet.';
}
