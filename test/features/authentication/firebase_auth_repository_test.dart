import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workaxis/core/errors/app_exceptions.dart';
import 'package:workaxis/features/authentication/data/firebase_auth_repository.dart';
import 'package:workaxis/features/authentication/domain/models/account_status.dart';
import 'package:workaxis/features/authentication/domain/models/authentication_result.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';

import '../../helpers/fake_callable_functions.dart';

/// Auth double whose email/password sign-in always fails with [code].
class _RejectingAuth extends MockFirebaseAuth {
  _RejectingAuth(MockUser user, this.code)
    : super(mockUser: user, signedIn: false);

  final String code;

  @override
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async => throw FirebaseAuthException(code: code);
}

const _validClaims = {
  'role': 'orgAdmin',
  'organizationId': 'org-acme-1',
  'status': 'active',
};

void main() {
  group('FirebaseAuthRepository', () {
    late FakeFirebaseFirestore firestore;
    late FakeCallableFunctions functions;
    late MockFirebaseAuth auth;
    late FirebaseAuthRepository repository;

    /// Identifier -> login email, as the `resolveLoginIdentifier` callable.
    final directory = {
      'alice': 'alice@acme.com',
      'alice@acme.com': 'alice@acme.com',
      '+15551234567': 'alice@acme.com',
    };

    MockUser userWith(Map<String, dynamic> claims) => MockUser(
      uid: 'user-uuid-123',
      email: 'alice@acme.com',
      displayName: 'Alice Engineer',
      customClaim: claims,
    );

    void build({
      Map<String, dynamic> claims = _validClaims,
      MockFirebaseAuth? authOverride,
    }) {
      firestore = FakeFirebaseFirestore();
      functions = FakeCallableFunctions({
        'resolveLoginIdentifier': (payload) async {
          final email = directory[payload['identifier']];
          if (email == null) {
            throw const AccessDeniedException('Callable unauthenticated');
          }
          return {'email': email};
        },
      });
      auth =
          authOverride ??
          MockFirebaseAuth(mockUser: userWith(claims), signedIn: false);
      repository = FirebaseAuthRepository(
        auth: auth,
        firestore: firestore,
        functions: functions,
      );
    }

    setUp(build);

    Future<void> seedProfile([Map<String, dynamic>? data]) => firestore
        .collection('users')
        .doc('user-uuid-123')
        .set(
          data ??
              {
                'name': 'Alice Engineer',
                'username': 'alice',
                'email': 'alice@acme.com',
                'phone': '+15551234567',
              },
        );

    Future<AuthenticationResult> signIn([String id = 'alice@acme.com']) =>
        repository.signIn(identifier: id, password: 'validPassword123');

    test('validates empty identifier or password', () async {
      final res1 = await repository.signIn(identifier: '', password: 'x');
      expect(
        (res1 as AuthenticationFailure).errorMessage,
        contains('username, email, or phone number'),
      );
      final res2 = await repository.signIn(
        identifier: 'alice@acme.com',
        password: '',
      );
      expect(
        (res2 as AuthenticationFailure).errorMessage,
        contains('Please enter your password'),
      );
      expect(functions.calls, isEmpty);
    });

    test('maps role, organization and status from token claims', () async {
      await seedProfile();
      final result = await signIn();
      expect(result, isA<AuthenticationSuccess>());
      final user = (result as AuthenticationSuccess).user;
      expect(user.id, 'user-uuid-123');
      expect(user.name, 'Alice Engineer');
      expect(user.role, UserRole.orgAdmin);
      expect(user.status, AccountStatus.active);
      expect(user.organizationId, 'org-acme-1');
    });

    test('a profile document cannot grant a role the claims do not', () async {
      await seedProfile({
        'name': 'Alice',
        'role': 'platformOwner',
        'status': 'active',
        'organizationId': 'someone-else',
      });
      final user = ((await signIn()) as AuthenticationSuccess).user;
      expect(user.role, UserRole.orgAdmin);
      expect(user.organizationId, 'org-acme-1');
    });

    test(
      'works without a profile projection (claims are authoritative)',
      () async {
        final result = await signIn();
        expect(result, isA<AuthenticationSuccess>());
        expect((result as AuthenticationSuccess).user.name, 'Alice Engineer');
      },
    );

    for (final id in ['alice', '+15551234567', 'alice@acme.com']) {
      test('resolves "$id" through the callable', () async {
        await seedProfile();
        final result = await signIn(id);
        expect(result, isA<AuthenticationSuccess>());
        expect(functions.payloadsOf('resolveLoginIdentifier').single, {
          'identifier': id,
        });
      });
    }

    test('never reads user_aliases from the client', () async {
      await firestore.collection('user_aliases').doc('mallory').set({
        'email': 'alice@acme.com',
        'userId': 'user-uuid-123',
      });
      final result = await signIn('mallory');
      expect(
        (result as AuthenticationFailure).errorMessage,
        'Invalid username or password.',
      );
    });

    test('unknown identifier returns the generic message', () async {
      final result = await signIn('nonexistent_user');
      final message = (result as AuthenticationFailure).errorMessage;
      expect(message, 'Invalid username or password.');
      expect(message, isNot(contains('nonexistent_user')));
      expect(auth.currentUser, isNull);
    });

    test('an empty resolved email returns the generic message', () async {
      functions.handlers['resolveLoginIdentifier'] = (_) async => {'email': ''};
      final result = await signIn('alice');
      expect(
        (result as AuthenticationFailure).errorMessage,
        'Invalid username or password.',
      );
    });

    test('rate limiting is surfaced with a safe message', () async {
      functions.handlers['resolveLoginIdentifier'] = (_) async =>
          throw const DatabaseException(
            'Callable resource-exhausted',
            userMessage: 'Too many attempts. Try again later.',
          );
      final result = await signIn('alice');
      expect(
        (result as AuthenticationFailure).errorMessage,
        'Too many attempts. Try again later.',
      );
    });

    test(
      'network failure resolving the identifier is reported as such',
      () async {
        functions.handlers['resolveLoginIdentifier'] = (_) async =>
            throw const NetworkException();
        final result = await signIn('alice');
        expect(
          (result as AuthenticationFailure).errorMessage,
          contains('Network problem'),
        );
      },
    );

    test(
      'wrong password returns the same message as an unknown identifier',
      () async {
        build(
          authOverride: _RejectingAuth(
            userWith(_validClaims),
            'wrong-password',
          ),
        );
        final result = await signIn();
        expect(
          (result as AuthenticationFailure).errorMessage,
          'Invalid username or password.',
        );
      },
    );

    test('a suspended claim rejects login and signs out', () async {
      build(claims: {..._validClaims, 'status': 'suspended'});
      final result = await signIn();
      expect(
        (result as AuthenticationFailure).errorMessage,
        contains('account is suspended'),
      );
      expect(auth.currentUser, isNull);
    });

    for (final entry in {
      'missing claims': <String, dynamic>{},
      'unknown role': {
        'role': 'superuser',
        'status': 'active',
        'organizationId': 'o',
      },
      'unknown status': {
        'role': 'employee',
        'status': 'pending',
        'organizationId': 'o',
      },
      'missing status': {'role': 'employee', 'organizationId': 'o'},
      'customer role without organization': {
        'role': 'employee',
        'status': 'active',
      },
    }.entries) {
      test('${entry.key} denies access and signs out', () async {
        build(claims: entry.value);
        await seedProfile({'role': 'platformOwner', 'status': 'active'});
        final result = await signIn();
        expect(result, isA<AuthenticationFailure>());
        expect(
          (result as AuthenticationFailure).errorMessage,
          contains('not available'),
        );
        expect(auth.currentUser, isNull);
      });
    }

    test('platform roles do not need an organization', () async {
      build(claims: {'role': 'platformOwner', 'status': 'active'});
      final user = ((await signIn()) as AuthenticationSuccess).user;
      expect(user.role, UserRole.platformOwner);
      expect(user.organizationId, isNull);
    });

    test('synthetic login emails are hidden from the user', () async {
      await seedProfile({
        'name': 'Alice',
        'email': 'alice@login.workaxis.invalid',
      });
      final user = ((await signIn()) as AuthenticationSuccess).user;
      expect(user.email, isNull);
    });

    test(
      'getCurrentUser denies a signed-in user whose claims are missing',
      () async {
        build(claims: {});
        await auth.signInWithEmailAndPassword(
          email: 'alice@acme.com',
          password: 'validPassword123',
        );
        expect(await repository.getCurrentUser(), isNull);
        expect(auth.currentUser, isNull);
      },
    );

    test(
      'getCurrentUser returns the user when signed in, null otherwise',
      () async {
        expect(await repository.getCurrentUser(), isNull);
        await seedProfile();
        await signIn();
        final current = await repository.getCurrentUser();
        expect(current?.role, UserRole.orgAdmin);
        expect(current?.name, 'Alice Engineer');
      },
    );

    test('changePassword re-authenticates and updates the password', () async {
      await signIn();
      await repository.changePassword(
        currentPassword: 'validPassword123',
        newPassword: 'brandNewPassword456',
      );
    });

    test('changePassword without a signed-in user throws a safe error', () {
      expect(
        () => repository.changePassword(
          currentPassword: 'x',
          newPassword: 'yyyyyyyy',
        ),
        throwsA(
          isA<AuthenticationException>().having(
            (e) => e.userMessage,
            'userMessage',
            contains('sign in again'),
          ),
        ),
      );
    });

    test('signOut terminates the session', () async {
      await signIn();
      expect(auth.currentUser, isNotNull);
      await repository.signOut();
      expect(auth.currentUser, isNull);
    });

    test('authStateChanges emits user updates', () async {
      await seedProfile();
      final expectation = expectLater(
        repository.authStateChanges(),
        emitsInOrder([isNull, predicate<Object?>((u) => u != null), isNull]),
      );
      await signIn();
      await repository.signOut();
      await expectation;
    });
  });
}
