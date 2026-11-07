import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workaxis/core/errors/app_exceptions.dart';
import 'package:workaxis/features/authentication/domain/models/account_status.dart';
import 'package:workaxis/features/platform_users/data/firestore_platform_users_repository.dart';
import 'package:workaxis/features/platform_users/domain/errors/platform_users_failure.dart';
import 'package:workaxis/features/platform_users/domain/models/platform_administrator.dart';

void main() {
  group('FirestorePlatformUsersRepository Tests', () {
    late FakeFirebaseFirestore fakeFirestore;
    late FirestorePlatformUsersRepository repository;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      repository = FirestorePlatformUsersRepository(firestore: fakeFirestore);
    });

    test('getAdministrators returns empty list when no admins exist', () async {
      final admins = await repository.getAdministrators();
      expect(admins, isEmpty);
    });

    test('createAdministrator creates user record and multi-identifier aliases in Firestore', () async {
      final created = await repository.createAdministrator(
        administrator: PlatformAdministrator(
          id: 'admin-01',
          fullName: 'Sarah Connor',
          username: 'sarah.connor',
          email: 'sarah@workaxis.com',
          phone: '+919876543210',
          status: AccountStatus.active,
          createdAt: DateTime(2026, 11, 7),
        ),
        initialPassword: 'TempPassword123!',
      );

      expect(created.id, equals('admin-01'));
      expect(created.fullName, equals('Sarah Connor'));
      expect(created.username, equals('sarah.connor'));
      expect(created.email, equals('sarah@workaxis.com'));
      expect(created.phone, equals('+919876543210'));

      // Verify Firestore user doc
      final userDoc = await fakeFirestore.collection('users').doc('admin-01').get();
      expect(userDoc.exists, isTrue);
      expect(userDoc.data()?['role'], equals('platformAdmin'));
      expect(userDoc.data()?['username'], equals('sarah.connor'));

      // Verify username alias doc
      final usernameAlias =
          await fakeFirestore.collection('user_aliases').doc('sarah.connor').get();
      expect(usernameAlias.exists, isTrue);
      expect(usernameAlias.data()?['email'], equals('sarah@workaxis.com'));

      // Verify phone alias doc
      final phoneAlias =
          await fakeFirestore.collection('user_aliases').doc('+919876543210').get();
      expect(phoneAlias.exists, isTrue);
      expect(phoneAlias.data()?['email'], equals('sarah@workaxis.com'));
    });

    test('createAdministrator throws PlatformUsersFailure when username alias already exists', () async {
      await fakeFirestore.collection('user_aliases').doc('john.doe').set({
        'uid': 'existing-uid',
        'email': 'existing@workaxis.com',
      });

      expect(
        () => repository.createAdministrator(
          administrator: PlatformAdministrator(
            id: 'admin-02',
            fullName: 'John Doe',
            username: 'john.doe',
            email: 'john@workaxis.com',
            status: AccountStatus.active,
            createdAt: DateTime(2026, 11, 7),
          ),
          initialPassword: 'TempPassword123!',
        ),
        throwsA(isA<PlatformUsersFailure>()),
      );
    });

    test('getAdministrators filters by query and status', () async {
      await fakeFirestore.collection('users').doc('admin-1').set({
        'role': 'platformAdmin',
        'name': 'Alice Wonder',
        'username': 'alice',
        'email': 'alice@platform.com',
        'status': 'active',
        'createdAt': Timestamp.fromDate(DateTime(2026, 1, 1)),
      });

      await fakeFirestore.collection('users').doc('admin-2').set({
        'role': 'platformAdmin',
        'name': 'Bob Builder',
        'username': 'bob',
        'email': 'bob@platform.com',
        'status': 'suspended',
        'createdAt': Timestamp.fromDate(DateTime(2026, 1, 2)),
      });

      // Filter by status active
      final activeAdmins = await repository.getAdministrators(status: AccountStatus.active);
      expect(activeAdmins.length, equals(1));
      expect(activeAdmins.first.username, equals('alice'));

      // Filter by query
      final bobSearch = await repository.getAdministrators(query: 'Bob');
      expect(bobSearch.length, equals(1));
      expect(bobSearch.first.username, equals('bob'));

      // Non-matching query
      final emptySearch = await repository.getAdministrators(query: 'Charlie');
      expect(emptySearch, isEmpty);
    });

    test('getAdministratorById returns admin when found and null when missing', () async {
      await fakeFirestore.collection('users').doc('admin-found').set({
        'role': 'platformAdmin',
        'name': 'Found Admin',
        'username': 'found',
        'email': 'found@platform.com',
        'status': 'active',
        'createdAt': Timestamp.fromDate(DateTime(2026, 1, 1)),
      });

      final found = await repository.getAdministratorById('admin-found');
      expect(found, isNotNull);
      expect(found!.username, equals('found'));

      final missing = await repository.getAdministratorById('admin-nonexistent');
      expect(missing, isNull);
    });

    test('updateAdministratorStatus modifies status and returns updated admin', () async {
      await fakeFirestore.collection('users').doc('admin-status').set({
        'role': 'platformAdmin',
        'name': 'Status Admin',
        'username': 'status_admin',
        'email': 'status@platform.com',
        'status': 'active',
        'createdAt': Timestamp.fromDate(DateTime(2026, 1, 1)),
      });

      final updated = await repository.updateAdministratorStatus('admin-status', AccountStatus.suspended);
      expect(updated.status, equals(AccountStatus.suspended));

      final updatedDoc = await fakeFirestore.collection('users').doc('admin-status').get();
      expect(updatedDoc.data()?['status'], equals('suspended'));
    });

    test('updateAdministratorStatus throws NotFoundException when id does not exist', () async {
      expect(
        () => repository.updateAdministratorStatus('missing-id', AccountStatus.suspended),
        throwsA(isA<NotFoundException>()),
      );
    });
  });
}
