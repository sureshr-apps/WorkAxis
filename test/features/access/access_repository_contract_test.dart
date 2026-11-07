import 'package:flutter_test/flutter_test.dart';
import 'package:workaxis/core/errors/app_exceptions.dart';
import 'package:workaxis/features/access/data/mock_access_data_source.dart';
import 'package:workaxis/features/access/data/mock_access_repository.dart';
import 'package:workaxis/features/access/data/sql_connect_access_repository.dart';
import 'package:workaxis/features/authentication/data/mock_auth_data_source.dart';
import 'package:workaxis/features/authentication/domain/models/account_status.dart';
import 'package:workaxis/features/authentication/domain/models/app_user.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';

import '../../contracts/access_repository_contract.dart';
import '../../helpers/fake_access_remote_data_source.dart';

void main() {
  runAccessRepositoryContract('mock', (
    facts, {
    required userId,
    bool orgActive = true,
  }) {
    facts.setOrganizationActive('org-acme', isActive: orgActive);
    return MockAccessRepository(dataSource: facts, delay: Duration.zero);
  });

  runAccessRepositoryContract('SQL Connect with fakes', (
    facts, {
    required userId,
    bool orgActive = true,
  }) {
    facts.setOrganizationActive('org-acme', isActive: orgActive);
    return SqlConnectAccessRepository(
      dataSource: FakeAccessRemoteDataSource(facts, currentUserId: userId),
    );
  });

  group('SqlConnectAccessRepository specifics', () {
    final accounts = MockAuthDataSource();

    SqlConnectAccessRepository repoFor(FakeAccessRemoteDataSource source) =>
        SqlConnectAccessRepository(dataSource: source);

    FakeAccessRemoteDataSource sourceFor(String userId) =>
        FakeAccessRemoteDataSource(
          MockAccessDataSource(),
          currentUserId: userId,
        );

    test('does not touch Firebase (no live backend needed)', () async {
      final repo = repoFor(sourceFor('user-oa-01'));
      final context = await repo.resolveCurrentUserAccess(
        accounts.findById('user-oa-01')!,
      );
      expect(context.organization?.id, 'org-acme');
    });

    test('a token role that disagrees with SQL is denied', () async {
      final source = sourceFor('user-emp-01')..roleOverride = UserRole.employee;
      final forged = AppUser(
        id: 'user-emp-01',
        name: 'Forged',
        username: 'employee',
        role: UserRole.orgAdmin,
        organizationId: 'org-acme',
      );
      await expectLater(
        repoFor(source).resolveCurrentUserAccess(forged),
        throwsA(isA<AccessDeniedException>()),
      );
    });

    test('a token organization that disagrees with SQL is denied', () async {
      final wrongOrg = AppUser(
        id: 'user-emp-01',
        name: 'Sarah',
        username: 'employee',
        role: UserRole.employee,
        organizationId: 'org-other',
      );
      await expectLater(
        repoFor(sourceFor('user-emp-01')).resolveCurrentUserAccess(wrongOrg),
        throwsA(isA<AccessDeniedException>()),
      );
    });

    test(
      'a non-active SQL member row is denied even if the token is active',
      () async {
        final source = sourceFor('user-emp-01')
          ..memberStatus = AccountStatus.suspended;
        await expectLater(
          repoFor(source)
              .resolveCurrentUserAccess(accounts.findById('user-emp-01')!),
          throwsA(isA<AccessDeniedException>()),
        );
      },
    );

    test('an unknown member status is denied (fails closed)', () async {
      final source = sourceFor('user-emp-01')..memberStatus = null;
      await expectLater(
        repoFor(source)
            .resolveCurrentUserAccess(accounts.findById('user-emp-01')!),
        throwsA(isA<AccessDeniedException>()),
      );
    });

    test('a missing member row fails with a typed resolution error', () async {
      final source = sourceFor('user-emp-01')..noMember = true;
      await expectLater(
        repoFor(source)
            .resolveCurrentUserAccess(accounts.findById('user-emp-01')!),
        throwsA(isA<AccessResolutionException>()),
      );
    });

    test('customer user without an organization id is rejected', () async {
      const orphan = AppUser(
        id: 'user-emp-01',
        name: 'Orphan',
        username: 'orphan',
        role: UserRole.employee,
      );
      await expectLater(
        repoFor(sourceFor('user-emp-01')).resolveCurrentUserAccess(orphan),
        throwsA(isA<AppException>()),
      );
    });

    test('backend failures are mapped and do not leak raw text', () async {
      final source = sourceFor('user-emp-01')
        ..failWith = StateError('host=10.0.0.5 token=abc');
      await expectLater(
        repoFor(source)
            .resolveCurrentUserAccess(accounts.findById('user-emp-01')!),
        throwsA(
          isA<AppException>().having(
            (e) => e.userMessage,
            'userMessage',
            isNot(contains('10.0.0.5')),
          ),
        ),
      );
    });

    test('validateBranchAccess denies on error', () async {
      final source = sourceFor('user-emp-01')..failWith = StateError('down');
      expect(
        await repoFor(source)
            .validateBranchAccess(userId: 'user-emp-01', branchId: 'br-01'),
        isFalse,
      );
    });

    test('validateBranchAccess cannot answer for another user', () async {
      final repo = repoFor(sourceFor('user-emp-01'));
      expect(
        await repo.validateBranchAccess(
          userId: 'user-bm-multi-01',
          branchId: 'br-01',
        ),
        isFalse,
      );
    });
  });
}
