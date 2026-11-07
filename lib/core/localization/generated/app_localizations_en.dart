// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get alreadyHaveAccount => 'Already have an account?';

  @override
  String get appTitle => 'Baytari';

  @override
  String get arabic => 'Arabic';

  @override
  String get authError => 'Something went wrong. Please try again.';

  @override
  String get authNotConfigured =>
      'Supabase is not configured, so sign-in is unavailable in demo mode.';

  @override
  String get confirmPassword => 'Confirm password';

  @override
  String get editProfile => 'Edit profile';

  @override
  String get email => 'Email';

  @override
  String get emailConfirmationSent =>
      'Account created! Check your email to confirm it, then sign in.';

  @override
  String get emptyTitle => 'Nothing here yet';

  @override
  String get english => 'English';

  @override
  String get errorTitle => 'Something went wrong';

  @override
  String get fullName => 'Full name';

  @override
  String get home => 'Home';

  @override
  String get homeDescription =>
      'This is the M0 scaffold. Features will be added one at a time: auth, pets, vets, appointments, schedule, dashboard and settings.';

  @override
  String get invalidEmail => 'Enter a valid email address';

  @override
  String get invalidPhone => 'Enter a valid phone number';

  @override
  String get language => 'Language';

  @override
  String get loading => 'Loading…';

  @override
  String get login => 'Sign in';

  @override
  String get logout => 'Sign out';

  @override
  String get myProfile => 'My profile';

  @override
  String get nameRequired => 'Enter your name';

  @override
  String get noAccount => 'Don\'t have an account?';

  @override
  String get password => 'Password';

  @override
  String get passwordTooShort => 'Password must be at least 6 characters';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get phone => 'Phone';

  @override
  String get phoneOptional => 'Phone (optional)';

  @override
  String get profileSaved => 'Profile saved';

  @override
  String get register => 'Create an account';

  @override
  String get retry => 'Retry';

  @override
  String get roleOwner => 'Pet owner';

  @override
  String get roleVet => 'Veterinarian';

  @override
  String get save => 'Save';

  @override
  String get selectRole => 'Choose your role';

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
