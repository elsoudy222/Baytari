/// A tiny result type: every use case returns a [Result] instead of
/// throwing, so a Cubit can handle success and failure as normal
/// states (Loading -> Success / Failure) without try/catch in the UI.
///
/// Why not `dartz` / `Either`? The project avoids unnecessary
/// dependencies (user's spec: "avoid unnecessary dependencies"), and
/// Dart 3 `sealed` classes give the same exhaustive `switch` safety
/// with zero packages. The two cases:
/// - [Success] carries the value (`value`).
/// - [FailureResult] carries the domain [Failure] (`failure`).
///
/// Usage in a Cubit:
/// ```dart
/// final Result<Profile> result = await _signIn(params);
/// switch (result) {
///   case Success(:final value):
///     emit(state.copyWith(status: AuthStatus.authenticated, profile: value));
///   case FailureResult(:final failure):
///     emit(state.copyWith(status: AuthStatus.unauthenticated,
///         errorMessage: failure.message));
/// }
/// ```
/// The `switch` is exhaustive — adding a third case later would be a
/// compile error everywhere a Result is handled, not a silent bug.
library;

import 'failures.dart';

sealed class Result<T> {
  const Result();
}

/// The operation succeeded. [value] is the result (nullable when the
/// operation legitimately returns nothing, e.g. "no logged-in user").
final class Success<T> extends Result<T> {
  const Success(this.value);

  final T value;
}

/// The operation failed. [failure] is a domain [Failure] (never a
/// Dio / Supabase / framework type) so the Cubit and UI never import
/// the data layer to understand what went wrong.
final class FailureResult<T> extends Result<T> {
  const FailureResult(this.failure);

  final Failure failure;
}

/// Convenience getters so callers that do not want a `switch` can
/// still read a Result in one line. Prefer `switch` in Cubits — it
/// is exhaustive; these getters are for tests and simple checks.
extension ResultExtensions<T> on Result<T> {
  bool get isSuccess => this is Success<T>;

  bool get isFailure => this is FailureResult<T>;

  T? get valueOrNull => switch (this) {
    Success(:final value) => value,
    FailureResult() => null,
  };

  Failure? get failureOrNull => switch (this) {
    Success() => null,
    FailureResult(:final failure) => failure,
  };
}
