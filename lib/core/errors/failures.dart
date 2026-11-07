/// Domain-level failures. The domain layer only knows these — never
/// Dio, Supabase, or any other framework type.
///
/// A Failure is *returned* (usually inside a result type) rather than
/// thrown, so a Cubit can handle it as a normal state: Loading ->
/// Failure(message). The `message` is a technical string for logging;
/// the user-facing text comes from the ARB files, chosen by the UI
/// from the failure type.
library;

import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  const Failure(this.message);

  final String message;

  @override
  List<Object?> get props => <Object?>[message];
}

/// The server answered with an error.
class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

/// No internet / timeout — the request never reached the server.
class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

/// Local storage failed.
class CacheFailure extends Failure {
  const CacheFailure(super.message);
}

/// Not logged in, or no permission.
class AuthFailure extends Failure {
  const AuthFailure(super.message);
}

/// A required service (e.g. Supabase) was not configured.
class NotConfiguredFailure extends Failure {
  const NotConfiguredFailure(super.message);
}
