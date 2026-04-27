abstract class Failure {
  final String message;
  
  const Failure(this.message);
}

// Database Failures
class DatabaseFailure extends Failure {
  const DatabaseFailure(super.message);
}

// Network Failures
class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

// Authentication Failures
class AuthFailure extends Failure {
  const AuthFailure(super.message);
}

// Validation Failures
class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

// Server Failures
class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

// Cache Failures
class CacheFailure extends Failure {
  const CacheFailure(super.message);
}

// Permission Failures
class PermissionFailure extends Failure {
  const PermissionFailure(super.message);
}

// Not Found Failures
class NotFoundFailure extends Failure {
  const NotFoundFailure(super.message);
}

// Sync Failures
class SyncFailure extends Failure {
  const SyncFailure(super.message);
}
