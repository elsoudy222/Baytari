import 'package:equatable/equatable.dart';

/// Domain-level failures. The domain layer only knows these — never
/// Dio, Supabase, or any other framework type.
abstract class Failure extends Equatable {
  const Failure(this.message);

  final String message;

  @override
  List<Object?> get props => <Object?>[message];
}

class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

class CacheFailure extends Failure {
  const CacheFailure(super.message);
}

class AuthFailure extends Failure {
  const AuthFailure(super.message);
}

class NotConfiguredFailure extends Failure {
  const NotConfiguredFailure(super.message);
}
