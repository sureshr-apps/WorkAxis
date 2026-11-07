import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_data_connect/firebase_data_connect.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workaxis/core/errors/app_exceptions.dart';
import 'package:workaxis/core/errors/backend_error_mapper.dart';
import 'package:workaxis/core/errors/user_message.dart';

void main() {
  const leakyText = 'PERMISSION_DENIED: projects/p/databases/(default) secret';

  group('mapBackendError', () {
    test('returns AppException instances unchanged', () {
      const original = NotFoundException('x');
      expect(identical(mapBackendError(original), original), isTrue);
    });

    test('permission-denied maps to AccessDeniedException', () {
      final mapped = mapBackendError(
        FirebaseException(
          plugin: 'cloud_firestore',
          code: 'permission-denied',
          message: leakyText,
        ),
      );
      expect(mapped, isA<AccessDeniedException>());
      expect(mapped.userMessage, isNot(contains('projects/')));
    });

    test('unavailable and deadline-exceeded map to network and timeout', () {
      expect(
        mapBackendError(FirebaseException(plugin: 'p', code: 'unavailable')),
        isA<NetworkException>(),
      );
      expect(
        mapBackendError(
          FirebaseException(plugin: 'p', code: 'deadline-exceeded'),
        ),
        isA<RequestTimeoutException>(),
      );
    });

    test('Data Connect errors map by their error code', () {
      expect(
        mapBackendError(
          DataConnectError(DataConnectErrorCode.unavailable, leakyText),
        ),
        isA<NetworkException>(),
      );
      expect(
        mapBackendError(
          DataConnectError(DataConnectErrorCode.unauthorized, leakyText),
        ),
        isA<AccessDeniedException>(),
      );
      final other = mapBackendError(
        DataConnectError(DataConnectErrorCode.codecFailed, leakyText),
      );
      expect(other, isA<DatabaseException>());
      expect(other.userMessage, isNot(contains('secret')));
    });

    test('auth errors never reveal whether an account exists', () {
      for (final code in [
        'user-not-found',
        'wrong-password',
        'invalid-credential',
      ]) {
        expect(
          mapBackendError(FirebaseAuthException(code: code)).userMessage,
          'Invalid username or password.',
          reason: code,
        );
      }
      expect(
        mapBackendError(FirebaseAuthException(code: 'network-request-failed')),
        isA<NetworkException>(),
      );
    });

    test('timeouts and unknown errors collapse to safe messages', () {
      expect(
        mapBackendError(TimeoutException('slow')),
        isA<RequestTimeoutException>(),
      );
      final unknown = mapBackendError(StateError(leakyText));
      expect(unknown, isA<DatabaseException>());
      expect(unknown.userMessage, isNot(contains('secret')));
      expect(unknown.userMessage, isNot(contains('StateError')));
    });
  });

  group('userMessageFor', () {
    test('uses the fallback for raw exceptions, never their text', () {
      final text = userMessageFor(
        Exception(leakyText),
        null,
        fallback: 'Could not load.',
      );
      expect(text, 'Could not load.');
    });

    test('keeps category-specific messages for typed failures', () {
      expect(
        userMessageFor(const NetworkException(), null, fallback: 'fallback'),
        contains('Network'),
      );
    });
  });
}
