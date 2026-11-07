import 'package:flutter_test/flutter_test.dart';
import 'package:workaxis/core/errors/app_exceptions.dart';
import 'package:workaxis/features/access/data/mock_access_data_source.dart';
import 'package:workaxis/features/access/domain/models/app_permission.dart';
import 'package:workaxis/features/access/domain/repositories/access_repository.dart';
import 'package:workaxis/features/authentication/data/mock_auth_data_source.dart';
import 'package:workaxis/features/authentication/domain/models/account_status.dart';
import 'package:workaxis/features/authentication/domain/models/app_user.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';

/// Creates the repository under test for [userId]. [orgActive] and
/// [memberStatus] describe the server-side facts for that run.
typedef AccessRepositoryFactory = AccessRepository Function(
  MockAccessDataSource facts, {
  required String userId,
  bool orgActive,
});

/// Behaviour every [AccessRepository] must provide.
void runAccessRepositoryContract(String label, AccessRepositoryFactory create) {
  group('AccessRepository contract ($label)', () {
    late MockAuthDataSource accounts;
    late MockAccessDataSource facts;

    setUp(() {
      accounts = MockAuthDataSource();
      facts = MockAccessDataSource();
    });

    AppUser user(String id) => accounts.findById(id)!;

    test('platform users have no organization or branches', () async {
      final repo = create(facts, userId: 'user-po-01');
      final context = await repo.resolveCurrentUserAccess(user('user-po-01'));
      expect(context.organization, isNull);
      expect(context.assignedBranches, isEmpty);
      expect(context.activeBranch, isNull);
      expect(context.hasPermission(AppPermission.platformOwner), isTrue);
    });

    test('branch manager sees only assigned active branches', () async {
      final repo = create(facts, userId: 'user-bm-multi-01');
      final context = await repo.resolveCurrentUserAccess(
        user('user-bm-multi-01'),
      );
      expect(context.assignedBranches.map((b) => b.id).toSet(), {
        'br-01',
        'br-02',
      });
      expect(context.activeBranch, isNull);
      expect(context.requiresBranchSelection, isTrue);
    });

    test('single-branch manager gets that branch selected', () async {
      final repo = create(facts, userId: 'user-bm-single-01');
      final context = await repo.resolveCurrentUserAccess(
        user('user-bm-single-01'),
      );
      expect(context.activeBranch?.branchId, 'br-04');
      expect(context.requiresBranchSelection, isFalse);
    });

    test('employee gets only their assigned branch', () async {
      final repo = create(facts, userId: 'user-emp-01');
      final context = await repo.resolveCurrentUserAccess(user('user-emp-01'));
      expect(context.assignedBranches.map((b) => b.id), ['br-01']);
      expect(context.activeBranch?.branchId, 'br-01');
    });

    test('org admin is organization-wide with no active branch', () async {
      final repo = create(facts, userId: 'user-oa-01');
      final context = await repo.resolveCurrentUserAccess(user('user-oa-01'));
      expect(context.organization?.id, 'org-acme');
      expect(context.activeBranch, isNull);
      expect(context.assignedBranches.map((b) => b.id).toSet(), {
        'br-01',
        'br-02',
        'br-04',
      });
      expect(context.requiresBranchSelection, isFalse);
    });

    test('a suspended organization is denied', () async {
      final repo = create(facts, userId: 'user-emp-01', orgActive: false);
      await expectLater(
        repo.resolveCurrentUserAccess(user('user-emp-01')),
        throwsA(isA<AccessDeniedException>()),
      );
    });

    test('a suspended member is denied', () async {
      final suspended = AppUser(
        id: 'user-emp-01',
        name: 'Sarah',
        username: 'employee',
        role: UserRole.employee,
        organizationId: 'org-acme',
        status: AccountStatus.suspended,
      );
      final repo = create(facts, userId: 'user-emp-01');
      await expectLater(
        repo.resolveCurrentUserAccess(suspended),
        throwsA(isA<AccessDeniedException>()),
      );
    });

    test(
      'an employee cannot validate a branch outside their assignment',
      () async {
        final repo = create(facts, userId: 'user-emp-01');
        expect(
          await repo.validateBranchAccess(
            userId: 'user-emp-01',
            branchId: 'br-01',
          ),
          isTrue,
        );
        expect(
          await repo.validateBranchAccess(
            userId: 'user-emp-01',
            branchId: 'br-04',
          ),
          isFalse,
        );
      },
    );

    test(
      'branch managers cannot validate unassigned or inactive branches',
      () async {
        final repo = create(facts, userId: 'user-bm-multi-01');
        Future<bool> can(String branch) => repo.validateBranchAccess(
          userId: 'user-bm-multi-01',
          branchId: branch,
        );
        expect(await can('br-01'), isTrue);
        expect(await can('br-04'), isFalse);
        expect(await can('br-03'), isFalse);
      },
    );

    test('assigned branches are active only', () async {
      final repo = create(facts, userId: 'user-bm-multi-01');
      final branches = await repo.getAssignedBranches('user-bm-multi-01');
      expect(branches.every((b) => b.isActive), isTrue);
      expect(branches.map((b) => b.id).toSet(), {'br-01', 'br-02'});
    });
  });
}
