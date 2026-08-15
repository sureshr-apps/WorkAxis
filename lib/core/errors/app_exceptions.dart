import 'package:equatable/equatable.dart';

/// Base application exception with user-friendly mapped message.
sealed class AppException extends Equatable implements Exception {
  const AppException({required this.message, this.code});

  final String message;
  final String? code;

  @override
  List<Object?> get props => [message, code];

  @override
  String toString() => '$runtimeType(message: $message, code: $code)';
}

/// Authentication-related failures.
final class AuthException extends AppException {
  const AuthException({required super.message, super.code});

  factory AuthException.invalidPhoneNumber([String? message]) => AuthException(
        message: message ?? 'Please enter a valid mobile number.',
        code: 'invalid-phone-number',
      );

  factory AuthException.otpRateLimited([String? message]) => AuthException(
        message: message ??
            'Too many attempts. Please wait a few minutes before trying again.',
        code: 'otp-rate-limited',
      );

  factory AuthException.otpExpired([String? message]) => AuthException(
        message: message ??
            'The verification code has expired. Please request a new code.',
        code: 'otp-expired',
      );

  factory AuthException.invalidOtp([String? message]) => AuthException(
        message: message ??
            'The verification code entered is incorrect. Please check and try again.',
        code: 'invalid-otp',
      );

  factory AuthException.networkUnavailable([String? message]) => AuthException(
        message: message ??
            'No network connection. Please check your internet and try again.',
        code: 'network-unavailable',
      );

  factory AuthException.cancelled([String? message]) => AuthException(
        message: message ?? 'Sign in was cancelled.',
        code: 'sign-in-cancelled',
      );

  factory AuthException.failed([String? message]) => AuthException(
        message: message ?? 'Authentication failed. Please try again.',
        code: 'auth-failed',
      );

  factory AuthException.sessionExpired([String? message]) => AuthException(
        message: message ?? 'Your session has expired. Please sign in again.',
        code: 'session-expired',
      );
}

/// Network and external communication failures.
final class NetworkException extends AppException {
  const NetworkException({required super.message, super.code});

  factory NetworkException.unavailable([String? message]) => NetworkException(
        message: message ??
            'Unable to connect to the server. Please check your internet connection.',
        code: 'network-unavailable',
      );
}

/// Access resolution, authorization, and organization failures.
final class AccessResolutionException extends AppException {
  const AccessResolutionException({required super.message, super.code});

  factory AccessResolutionException.unknownUser([String? message]) =>
      AccessResolutionException(
        message: message ??
            'Your account is not registered. Please contact your organization administrator.',
        code: 'unknown-application-user',
      );

  factory AccessResolutionException.accountDisabled([String? message]) =>
      AccessResolutionException(
        message: message ??
            'Your account has been deactivated. Please contact support or your administrator.',
        code: 'account-disabled',
      );

  factory AccessResolutionException.membershipUnavailable([String? message]) =>
      AccessResolutionException(
        message:
            message ?? 'You do not have any active organization memberships.',
        code: 'membership-unavailable',
      );

  factory AccessResolutionException.organizationUnavailable(
          [String? message]) =>
      AccessResolutionException(
        message: message ??
            'This organization is currently suspended or undergoing maintenance.',
        code: 'organization-unavailable',
      );

  factory AccessResolutionException.branchAssignmentRequired(
          [String? message]) =>
      AccessResolutionException(
        message: message ??
            'You do not have an active branch assignment. Contact your branch manager.',
        code: 'branch-assignment-required',
      );

  factory AccessResolutionException.invitationExpired([String? message]) =>
      AccessResolutionException(
        message: message ??
            'This invitation has expired. Please ask your administrator to send a new invite.',
        code: 'invitation-expired',
      );

  factory AccessResolutionException.invitationIdentityMismatch(
          [String? message]) =>
      AccessResolutionException(
        message: message ??
            'This invitation was sent to a different phone number than your signed-in account.',
        code: 'invitation-identity-mismatch',
      );

  factory AccessResolutionException.unexpected([String? message]) =>
      AccessResolutionException(
        message: message ??
            'An unexpected error occurred while resolving your access.',
        code: 'unexpected',
      );
}
