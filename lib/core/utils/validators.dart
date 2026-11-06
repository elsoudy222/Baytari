/// Pure-Dart input validators. No Flutter dependency, so these can be
/// used from the domain layer and unit tested without a widget test.
abstract final class Validators {
  static final RegExp _emailRegExp = RegExp(
    r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
  );

  static bool isValidEmail(String value) => _emailRegExp.hasMatch(value);

  static bool isNotEmpty(String? value) =>
      value != null && value.trim().isNotEmpty;

  static bool isValidPhone(String value) {
    final String digits = value.replaceAll(RegExp(r'\D'), '');
    return digits.length >= 10 && digits.length <= 15;
  }
}
