/// Pure-Dart string helpers.
///
/// They live in `core/extensions` (not in a feature) because any
/// feature may need them, and they have no Flutter dependency, so they
/// can be used from the domain layer and unit-tested without a widget.
extension NullableStringExtensions on String? {
  // `trim()` is included: a string of only spaces counts as empty.
  bool get isNullOrEmpty => this == null || this!.trim().isEmpty;
}

extension StringExtensions on String {
  // `capitalized` is used for display names (e.g. a pet type). It
  // returns the string unchanged when it is already empty, instead of
  // crashing on `this[0]`.
  String get capitalized =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
}
