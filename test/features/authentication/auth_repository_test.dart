import 'package:flutter_test/flutter_test.dart';
import 'package:workaxis/features/authentication/data/mock_auth_repository.dart';
import 'package:workaxis/features/authentication/domain/models/account_status.dart';
import 'package:workaxis/features/authentication/domain/models/authentication_result.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';

void main() {
  late MockAuthenticationRepository repository;

  setUp(() {
    repository = MockAuthenticationRepository(delay: Duration.zero);
  });

  tearDown(() {
    repository.dispose();
  });

  group('AuthenticationRepository - Credentials & Aliases', () {
    test('authenticates successfully with valid username', () async {
      final result = await repository.signIn(
        identifier: 'owner',
        password: 'Password123!',
      );

      expect(result, isA<AuthenticationSuccess>());
      final success = result as AuthenticationSuccess;
      expect(success.user.username, 'owner');
      expect(success.user.role, UserRole.platformOwner);
      expect(success.user.status, AccountStatus.active);
    });

    test('authenticates successfully with email alias', () async {
      final result = await repository.signIn(
        identifier: 'owner@workaxis.io',
        password: 'Password123!',
      );

      expect(result, isA<AuthenticationSuccess>());
      final success = result as AuthenticationSuccess;
      expect(success.user.username, 'owner');
    });

    test('authenticates successfully with phone number alias', () async {
      final result = await repository.signIn(
        identifier: '+15550001',
        password: 'Password123!',
      );

      expect(result, isA<AuthenticationSuccess>());
      final success = result as AuthenticationSuccess;
      expect(success.user.username, 'owner');
    });

    test('case-insensitivity works for username and email aliases', () async {
      final resultUpper = await repository.signIn(
        identifier: 'OWNER',
        password: 'Password123!',
      );
      expect(resultUpper, isA<AuthenticationSuccess>());

      final resultEmailMixed = await repository.signIn(
        identifier: 'Owner@WorkAxis.io',
        password: 'Password123!',
      );
      expect(resultEmailMixed, isA<AuthenticationSuccess>());
    });

    test('fails authentication with invalid password', () async {
      final result = await repository.signIn(
        identifier: 'owner',
        password: 'WrongPassword',
      );

      expect(result, isA<AuthenticationFailure>());
      final failure = result as AuthenticationFailure;
      expect(failure.errorMessage, 'Invalid username, email, or password.');
    });

    test('fails authentication with unknown identifier', () async {
      final result = await repository.signIn(
        identifier: 'nonexistent_user',
        password: 'Password123!',
      );

      expect(result, isA<AuthenticationFailure>());
    });

    test('fails authentication with empty fields', () async {
      final result = await repository.signIn(identifier: '', password: '');

      expect(result, isA<AuthenticationFailure>());
    });

    test('denies authentication for disabled / inactive account', () async {
      final result = await repository.signIn(
        identifier: 'disabled_user',
        password: 'Password123!',
      );

      expect(result, isA<AuthenticationFailure>());
      final failure = result as AuthenticationFailure;
      expect(failure.errorMessage, contains('inactive'));
    });
  });

  group('AuthenticationRepository - Session Management & Sign Out', () {
    test('maintains current user and clears upon sign out', () async {
      expect(await repository.getCurrentUser(), isNull);

      await repository.signIn(identifier: 'orgadmin', password: 'Password123!');

      expect(await repository.getCurrentUser(), isNotNull);
      expect((await repository.getCurrentUser())?.username, 'orgadmin');

      await repository.signOut();
      expect(await repository.getCurrentUser(), isNull);
    });

    test('emits auth state changes', () async {
      final states = <String?>[];
      final sub = repository.authStateChanges().listen((user) {
        states.add(user?.username);
      });

      await repository.signIn(identifier: 'employee', password: 'Password123!');
      await repository.signOut();

      await Future<void>.delayed(Duration.zero);
      expect(states, ['employee', null]);

      await sub.cancel();
    });
  });
}
