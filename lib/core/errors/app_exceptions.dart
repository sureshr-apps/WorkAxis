/// Base exception for WorkAxis application failures.
///
/// [message] is a developer-facing description and may be logged. It must never
/// be shown to users. [userMessage] is always safe to render in the UI.
abstract class AppException implements Exception {
  const AppException(this.message, {this._userMessage});

  final String message;
  final String? _userMessage;

  /// Message safe to display to end users (no backend/stack details).
  String get userMessage => _userMessage ?? defaultUserMessage;

  /// Whether the thrower supplied an explicit, user-safe message.
  bool get hasCustomUserMessage => _userMessage != null;

  /// Fallback user-facing text for this failure category.
  String get defaultUserMessage => 'Something went wrong. Please try again.';

  @override
  String toString() => message;
}

/// Thrown when authentication fails (invalid credentials, suspended account, etc.).
class AuthenticationException extends AppException {
  const AuthenticationException(super.message, {super.userMessage});

  @override
  String get defaultUserMessage => 'Authentication failed. Please try again.';
}

/// Thrown when access context resolution or permission check fails.
class AccessResolutionException extends AppException {
  const AccessResolutionException(super.message, {super.userMessage});

  @override
  String get defaultUserMessage =>
      'We could not verify your access. Please try again.';
}

/// Thrown when branch authorization check fails.
class BranchAuthorizationException extends AppException {
  const BranchAuthorizationException(super.message, {super.userMessage});

  @override
  String get defaultUserMessage => 'You do not have access to this branch.';
}

/// Thrown when an operation is denied due to role or scope boundaries.
class AccessDeniedException extends AppException {
  const AccessDeniedException([
    super.message = 'Access denied',
    String? userMessage,
  ]) : super(userMessage: userMessage);

  @override
  String get defaultUserMessage =>
      'You do not have permission to perform this action.';
}

/// Thrown when a requested entity is not found in the persistence store.
class NotFoundException extends AppException {
  const NotFoundException(super.message, {super.userMessage});

  @override
  String get defaultUserMessage => 'The requested item could not be found.';
}

/// Thrown when a database or backend query fails.
class DatabaseException extends AppException {
  const DatabaseException(super.message, {super.userMessage});
}

/// Thrown when the device cannot reach the backend.
class NetworkException extends AppException {
  const NetworkException([
    super.message = 'Network unavailable',
    String? userMessage,
  ]) : super(userMessage: userMessage);

  @override
  String get defaultUserMessage =>
      'Network problem. Check your connection and try again.';
}

/// Thrown when a backend call exceeds its deadline.
class RequestTimeoutException extends AppException {
  const RequestTimeoutException([
    super.message = 'Request timed out',
    String? userMessage,
  ]) : super(userMessage: userMessage);

  @override
  String get defaultUserMessage =>
      'The request took too long. Please try again.';
}

/// Why a device location could not be obtained.
enum LocationFailure {
  /// Device location services (GPS) are switched off.
  serviceDisabled,

  /// The user declined the permission prompt; it can be asked again.
  permissionDenied,

  /// Permission is blocked; only the system settings can re-enable it.
  permissionDeniedForever,

  /// No fix within the deadline.
  timeout,

  /// The platform failed to produce a position.
  unavailable,
}

/// Thrown when the device location needed for an action is unavailable.
class LocationException extends AppException {
  const LocationException(this.failure, super.message, {super.userMessage});

  final LocationFailure failure;

  @override
  String get defaultUserMessage =>
      'We could not get your location. Please try again.';
}
