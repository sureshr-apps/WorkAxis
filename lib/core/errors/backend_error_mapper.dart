import 'dart:async';
import 'dart:developer' as developer;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_data_connect/firebase_data_connect.dart';
import 'package:workaxis/core/errors/app_exceptions.dart';

/// Converts any backend/infrastructure failure into a typed [AppException]
/// whose [AppException.userMessage] is safe to show to users.
///
/// The raw error and stack trace are logged through `dart:developer` so they
/// stay available for diagnostics without ever reaching the UI.
AppException mapBackendError(Object error, [StackTrace? stackTrace]) {
  if (error is AppException) return error;

  developer.log(
    'Backend error',
    name: 'workaxis.backend',
    level: 1000,
    error: error,
    stackTrace: stackTrace,
  );

  if (error is TimeoutException) {
    return RequestTimeoutException('Timed out: ${error.message ?? ''}');
  }

  if (error is FirebaseAuthException) {
    return _mapAuthCode(error);
  }

  if (error is DataConnectError) {
    return switch (error.dataConnectErrorCode) {
      DataConnectErrorCode.unavailable => NetworkException(
        'Data Connect unavailable',
      ),
      DataConnectErrorCode.unauthorized => AccessDeniedException(
        'Data Connect unauthorized',
      ),
      _ => DatabaseException('Data Connect failure: ${error.code}'),
    };
  }

  if (error is FirebaseException) {
    return _mapFirebaseCode(error);
  }

  return DatabaseException('Unexpected failure: ${error.runtimeType}');
}

AppException _mapFirebaseCode(FirebaseException error) {
  switch (error.code) {
    case 'permission-denied':
    case 'unauthenticated':
      return AccessDeniedException('Firebase ${error.code}');
    case 'not-found':
      return NotFoundException('Firebase ${error.code}');
    case 'unavailable':
    case 'network-request-failed':
      return NetworkException('Firebase ${error.code}');
    case 'deadline-exceeded':
      return RequestTimeoutException('Firebase ${error.code}');
    default:
      return DatabaseException('Firebase failure: ${error.code}');
  }
}

AppException _mapAuthCode(FirebaseAuthException error) {
  switch (error.code) {
    case 'network-request-failed':
      return NetworkException('Auth ${error.code}');
    case 'too-many-requests':
      return AuthenticationException(
        'Auth ${error.code}',
        userMessage: 'Too many failed attempts. Please wait a few minutes and try again.',
      );
    case 'user-disabled':
      return AuthenticationException(
        'Auth ${error.code}',
        userMessage:
            'This account is not active. Please contact your administrator.',
      );
    case 'requires-recent-login':
      return AuthenticationException(
        'Auth ${error.code}',
        userMessage: 'Please sign in again before making this change.',
      );
    case 'weak-password':
      return AuthenticationException(
        'Auth ${error.code}',
        userMessage: 'Choose a stronger password.',
      );
    case 'user-not-found':
    case 'wrong-password':
    case 'invalid-credential':
    case 'invalid-email':
      return AuthenticationException(
        'Auth ${error.code}',
        userMessage: 'Invalid username or password.',
      );
    default:
      return AuthenticationException('Auth failure: ${error.code}');
  }
}
