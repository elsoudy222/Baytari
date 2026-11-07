/// Pure-Dart input validators. No Flutter dependency, so these can be
/// used from the domain layer and unit tested without a widget test.
///
/// These are ready for M1 (auth forms) and are not used by any M0
/// screen yet — M0 has no text inputs.
abstract final class Validators {
  // A simple, strict-enough email check: something, `@`, something,
  // `.`, something — with no spaces anywhere. It is not a full RFC
  // check on purpose; the server (Supabase Auth) is the final judge.
  static final RegExp _emailRegExp = RegExp(
    r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
  );

  static bool isValidEmail(String value) => _emailRegExp.hasMatch(value);

  static bool isNotEmpty(String? value) =>
      value != null && value.trim().isNotEmpty;

  /// Supabase requires a minimum of 6 characters for passwords.
  static bool isValidPassword(String value) => value.length >= 6;

  /// A phone number is valid if, after removing everything that is
  /// not a digit (`+`, spaces, `-`), 10–15 digits remain — that range
  /// covers local and international numbers without hardcoding one
  /// country's format.
  static bool isValidPhone(String value) {
    final String digits = value.replaceAll(RegExp(r'\D'), '');
    return digits.length >= 10 && digits.length <= 15;
  }
}
