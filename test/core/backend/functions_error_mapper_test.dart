import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workaxis/core/backend/functions_error_mapper.dart';
import 'package:workaxis/core/errors/app_exceptions.dart';

void main() {
  AppException map(String code, [String? message]) => mapFunctionsError(
    FirebaseFunctionsException(code: code, message: message ?? 'server text'),
    StackTrace.empty,
  );

  test('permission-denied and unauthenticated map to AccessDenied', () {
    for (final code in ['permission-denied', 'unauthenticated']) {
      final e = map(code);
      expect(e, isA<AccessDeniedException>());
      expect(e.userMessage, 'server text');
    }
  });

  test('not-found keeps the server message', () {
    final e = map('not-found');
    expect(e, isA<NotFoundException>());
    expect(e.userMessage, 'server text');
  });

  test('invalid-argument and already-exists map to DatabaseException', () {
    for (final code in ['invalid-argument', 'already-exists']) {
      final e = map(code);
      expect(e, isA<DatabaseException>());
      expect(e.userMessage, 'server text');
    }
  });

  test('transport failures map to network and timeout', () {
    expect(map('unavailable'), isA<NetworkException>());
    expect(map('deadline-exceeded'), isA<RequestTimeoutException>());
  });
}
