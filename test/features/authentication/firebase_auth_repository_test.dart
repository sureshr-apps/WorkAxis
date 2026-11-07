import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workaxis/features/authentication/data/firebase_auth_repository.dart';
import 'package:workaxis/features/authentication/domain/models/account_status.dart';
import 'package:workaxis/features/authentication/domain/models/authentication_result.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';

void main() {
  group('FirebaseAuthRepository Tests', () {
    late FakeFirebaseFirestore fakeFirestore;
    late MockFirebaseAuth mockAuth;
    late MockUser mockUser;
    late FirebaseAuthRepository repository;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      mockUser = MockUser(
        uid: 'user-uuid-123',
        email: 'alice@acme.com',
        displayName: 'Alice Engineer',
        phoneNumber: '+15551234567',
      );
      mockAuth = MockFirebaseAuth(mockUser: mockUser, signedIn: false);
      repository = FirebaseAuthRepository(
        auth: mockAuth,
        firestore: fakeFirestore,
      );
    });

    test('validates empty identifier or password', () async {
      final res1 = await repository.signIn(identifier: '', password: 'password123');
      expect(res1, isA<AuthenticationFailure>());
      expect((res1 as AuthenticationFailure).errorMessage, contains('username, email, or phone number'));

      final res2 = await repository.signIn(identifier: 'alice@acme.com', password: '');
      expect(res2, isA<AuthenticationFailure>());
      expect((res2 as AuthenticationFailure).errorMessage, contains('Please enter your password'));
    });

    test('direct email sign in succeeds and maps user from firestore', () async {
      // Seed Firestore profile
      await fakeFirestore.collection('users').doc('user-uuid-123').set({
        'name': 'Alice Engineer',
        'username': 'alice',
        'email': 'alice@acme.com',
        'phone': '+15551234567',
        'role': 'orgAdmin',
        'status': 'active',
        'organizationId': 'org-acme-1',
      });

      final result = await repository.signIn(
        identifier: 'alice@acme.com',
        password: 'validPassword123',
      );

      expect(result, isA<AuthenticationSuccess>());
      final user = (result as AuthenticationSuccess).user;
      expect(user.id, equals('user-uuid-123'));
      expect(user.email, equals('alice@acme.com'));
      expect(user.role, equals(UserRole.orgAdmin));
      expect(user.status, equals(AccountStatus.active));
      expect(user.organizationId, equals('org-acme-1'));
    });

    test('username alias resolves to email and authenticates', () async {
      // Seed alias
      await fakeFirestore.collection('user_aliases').doc('alice').set({
        'email': 'alice@acme.com',
        'userId': 'user-uuid-123',
      });

      // Seed profile
      await fakeFirestore.collection('users').doc('user-uuid-123').set({
        'name': 'Alice Engineer',
        'username': 'alice',
        'email': 'alice@acme.com',
        'role': 'branchManager',
        'status': 'active',
      });

      final result = await repository.signIn(
        identifier: 'alice',
        password: 'validPassword123',
      );

      expect(result, isA<AuthenticationSuccess>());
      final user = (result as AuthenticationSuccess).user;
      expect(user.role, equals(UserRole.branchManager));
      expect(user.email, equals('alice@acme.com'));
    });

    test('phone number alias resolves to email and authenticates', () async {
      // Seed phone alias
      await fakeFirestore.collection('user_aliases').doc('+15551234567').set({
        'email': 'alice@acme.com',
        'userId': 'user-uuid-123',
      });

      final result = await repository.signIn(
        identifier: '+15551234567',
        password: 'validPassword123',
      );

      expect(result, isA<AuthenticationSuccess>());
      expect((result as AuthenticationSuccess).user.id, equals('user-uuid-123'));
    });

    test('unknown username alias returns descriptive failure', () async {
      final result = await repository.signIn(
        identifier: 'nonexistent_user',
        password: 'validPassword123',
      );

      expect(result, isA<AuthenticationFailure>());
      expect(
        (result as AuthenticationFailure).errorMessage,
        contains('No account found matching "nonexistent_user"'),
      );
    });

    test('alias exists but has empty email field returns failure', () async {
      await fakeFirestore.collection('user_aliases').doc('broken_user').set({
        'email': '',
      });

      final result = await repository.signIn(
        identifier: 'broken_user',
        password: 'validPassword123',
      );

      expect(result, isA<AuthenticationFailure>());
      expect(
        (result as AuthenticationFailure).errorMessage,
        contains('No email address associated'),
      );
    });

    test('suspended account rejects login and forces sign out', () async {
      await fakeFirestore.collection('users').doc('user-uuid-123').set({
        'name': 'Alice Suspended',
        'email': 'alice@acme.com',
        'status': 'suspended',
        'role': 'employee',
      });

      final result = await repository.signIn(
        identifier: 'alice@acme.com',
        password: 'validPassword123',
      );

      expect(result, isA<AuthenticationFailure>());
      expect(
        (result as AuthenticationFailure).errorMessage,
        contains('account is suspended'),
      );
      expect(mockAuth.currentUser, isNull);
    });

    test('fallback profile is generated when user doc does not exist', () async {
      final result = await repository.signIn(
        identifier: 'alice@acme.com',
        password: 'validPassword123',
      );

      expect(result, isA<AuthenticationSuccess>());
      final user = (result as AuthenticationSuccess).user;
      expect(user.id, equals('user-uuid-123'));
      expect(user.name, equals('Alice Engineer'));
      expect(user.email, equals('alice@acme.com'));
      expect(user.role, equals(UserRole.employee));
      expect(user.status, equals(AccountStatus.active));
    });

    test('signOut terminates session', () async {
      await repository.signIn(
        identifier: 'alice@acme.com',
        password: 'validPassword123',
      );
      expect(mockAuth.currentUser, isNotNull);

      await repository.signOut();
      expect(mockAuth.currentUser, isNull);
    });

    test('getCurrentUser returns profile when signed in, null otherwise', () async {
      expect(await repository.getCurrentUser(), isNull);

      await fakeFirestore.collection('users').doc('user-uuid-123').set({
        'name': 'Alice Current',
        'username': 'alice_c',
        'email': 'alice@acme.com',
        'role': 'platformOwner',
        'status': 'active',
      });

      await repository.signIn(
        identifier: 'alice@acme.com',
        password: 'validPassword123',
      );

      final current = await repository.getCurrentUser();
      expect(current, isNotNull);
      expect(current!.role, equals(UserRole.platformOwner));
      expect(current.name, equals('Alice Current'));
    });

    test('authStateChanges emits user updates', () async {
      await fakeFirestore.collection('users').doc('user-uuid-123').set({
        'name': 'Alice Stream',
        'username': 'alice_stream',
        'email': 'alice@acme.com',
        'role': 'employee',
        'status': 'active',
      });

      final expectation = expectLater(
        repository.authStateChanges(),
        emitsInOrder([
          isNull, // Initially signed out
          predicate<Object?>((u) => u != null), // After sign in
          isNull, // After sign out
        ]),
      );

      await repository.signIn(
        identifier: 'alice@acme.com',
        password: 'validPassword123',
      );
      await repository.signOut();

      await expectation;
    });
  });
}
