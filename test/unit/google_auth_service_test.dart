import 'package:flutter_test/flutter_test.dart';
import 'package:workaxis/features/authentication/data/services/in_memory_google_auth_service.dart';
import 'package:workaxis/features/authentication/domain/entities/auth_user.dart';

void main() {
  group('InMemoryGoogleAuthService', () {
    late InMemoryGoogleAuthService service;

    setUp(() {
      service = InMemoryGoogleAuthService();
    });

    test('signIn returns mock user on success', () async {
      final user = await service.signIn();
      expect(user, isNotNull);
      expect(user?.email, 'alex.morgan@workaxis.io');
      expect(await service.isSignedIn(), isTrue);
      expect(await service.getCurrentUser(), equals(user));
    });

    test('signIn returns null on cancellation', () async {
      service.shouldCancel = true;
      final user = await service.signIn();
      expect(user, isNull);
      expect(await service.isSignedIn(), isFalse);
    });

    test('signIn throws exception when configured', () async {
      service.exceptionToThrow = Exception('Google Play Services unavailable');
      expect(() => service.signIn(), throwsException);
    });

    test('signOut clears signed in status', () async {
      await service.signIn();
      expect(await service.isSignedIn(), isTrue);

      await service.signOut();
      expect(await service.isSignedIn(), isFalse);
      expect(await service.getCurrentUser(), isNull);
    });

    test('custom mock user is supported', () async {
      service.mockUser = const AuthUser(
        uid: 'google_custom_999',
        email: 'custom@workaxis.io',
        displayName: 'Custom User',
      );

      final user = await service.signIn();
      expect(user?.uid, 'google_custom_999');
      expect(user?.email, 'custom@workaxis.io');
    });
  });
}
