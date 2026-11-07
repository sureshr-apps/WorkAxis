import 'package:flutter_test/flutter_test.dart';
import 'package:workaxis/features/authentication/data/mock_auth_repository.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';
import 'package:workaxis/features/authentication/presentation/controllers/auth_controller.dart';

import '../../helpers/session_fakes.dart';

void main() {
  group('AuthController.changePassword (mock repository)', () {
    late MockAuthenticationRepository repository;
    late AuthController controller;

    setUp(() async {
      repository = MockAuthenticationRepository(delay: Duration.zero);
      controller = AuthController(authRepository: repository);
      await controller.signIn(identifier: 'employee', password: 'Password123!');
    });

    tearDown(() {
      controller.dispose();
      repository.dispose();
    });

    test(
      'succeeds with the right current password and the new one works',
      () async {
        final ok = await controller.changePassword(
          currentPassword: 'Password123!',
          newPassword: 'AnotherSecret456!',
        );

        expect(ok, isTrue);
        expect(controller.passwordChangeError, isNull);

        final oldLogin = await repository.signIn(
          identifier: 'employee',
          password: 'Password123!',
        );
        final newLogin = await repository.signIn(
          identifier: 'employee',
          password: 'AnotherSecret456!',
        );
        expect(oldLogin.runtimeType.toString(), 'AuthenticationFailure');
        expect(newLogin.runtimeType.toString(), 'AuthenticationSuccess');
      },
    );

    test('rejects a wrong current password with a safe message', () async {
      final ok = await controller.changePassword(
        currentPassword: 'wrong',
        newPassword: 'AnotherSecret456!',
      );

      expect(ok, isFalse);
      expect(
        controller.passwordChangeError,
        'Your current password is incorrect.',
      );
      expect(controller.isChangingPassword, isFalse);
    });

    test('rejects a too-short new password', () async {
      final ok = await controller.changePassword(
        currentPassword: 'Password123!',
        newPassword: 'short',
      );

      expect(ok, isFalse);
      expect(controller.passwordChangeError, contains('at least 8'));
    });
  });

  group('AuthController session restore and monitoring', () {
    late FakeAuthRepository repository;
    late AuthController controller;

    setUp(() {
      repository = FakeAuthRepository(testUser(UserRole.employee));
      controller = AuthController(authRepository: repository);
    });

    tearDown(() => controller.dispose());

    test('init restores an existing session before reporting ready', () async {
      repository.restoreSession();

      final init = controller.init();
      expect(controller.isInitializing, isTrue);
      await init;

      expect(controller.isInitializing, isFalse);
      expect(controller.isAuthenticated, isTrue);
    });

    test('init without a session leaves the user signed out', () async {
      await controller.init();

      expect(controller.isAuthenticated, isFalse);
      expect(controller.isInitializing, isFalse);
    });

    test('a provider-side sign-out ends the session and notifies', () async {
      var lost = 0;
      controller.onSessionLost = () => lost++;
      await controller.init();
      await controller.signIn(identifier: 'x', password: 'y');

      repository.states.add(null);
      await Future<void>.delayed(Duration.zero);

      expect(controller.isAuthenticated, isFalse);
      expect(lost, 1);
    });

    test('a stream error does not sign the user out', () async {
      await controller.init();
      await controller.signIn(identifier: 'x', password: 'y');

      repository.states.addError(StateError('firestore unavailable'));
      await Future<void>.delayed(Duration.zero);

      expect(controller.isAuthenticated, isTrue);
    });

    test(
      'sign-out nulls the user synchronously and survives provider failure',
      () async {
        await controller.signIn(identifier: 'x', password: 'y');
        repository.failSignOut = true;

        final pending = controller.signOut();
        expect(controller.isAuthenticated, isFalse);

        await pending; // must not throw
      },
    );
  });
}
