/// Base exception for WorkAxis application failures.
abstract class AppException implements Exception {
  const AppException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Thrown when authentication fails (invalid credentials, suspended account, etc.).
class AuthenticationException extends AppException {
  const AuthenticationException(super.message);
}

/// Thrown when access context resolution or permission check fails.
class AccessResolutionException extends AppException {
  const AccessResolutionException(super.message);
}

/// Thrown when branch authorization check fails.
class BranchAuthorizationException extends AppException {
  const BranchAuthorizationException(super.message);
}
