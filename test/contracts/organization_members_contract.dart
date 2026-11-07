import 'package:flutter_test/flutter_test.dart';
import 'package:workaxis/core/errors/app_exceptions.dart';
import 'package:workaxis/core/errors/validation_exception.dart';
import 'package:workaxis/features/authentication/domain/models/account_status.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';
import 'package:workaxis/features/employees/domain/models/organization_member.dart';
import 'package:workaxis/features/employees/domain/repositories/organization_members_repository.dart';

import 'acme_scenario.dart';

const _password = 'Str0ng-Pass!';

/// Behaviour every [OrganizationMembersRepository] must provide. Run against
/// the mock and against the production repository with fake remote sources.
void runOrganizationMembersContract(
  String label,
  OrganizationMembersRepository Function() create,
) {
  group('OrganizationMembersRepository contract ($label)', () {
    late OrganizationMembersRepository repo;
    setUp(() => repo = create());

    Future<OrganizationMember> createEmployee({
      String username = 'new.person',
      List<String> branches = const ['br-01', 'br-02'],
    }) => repo.saveMember(
      access: orgAdminAccess(),
      member: memberDraft(username: username, branches: branches),
      initialPassword: _password,
    );

    test('branch manager sees only members of the active branch', () async {
      final page = await repo.getMembersPage(
        access: branchManagerAccess(),
        activeBranchId: 'br-01',
      );
      final ids = page.items.map((m) => m.id).toSet();
      expect(ids, containsAll(['user-emp-01', 'user-emp-02']));
      expect(ids, isNot(contains('user-emp-03')));
      expect(ids, isNot(contains('user-emp-04')));
      expect(ids, isNot(contains('user-bm-single-01')));
    });

    test('branch manager cannot list a branch outside the assigned set', () {
      expect(
        () => repo.getMembersPage(
          access: branchManagerAccess(),
          activeBranchId: 'br-04',
        ),
        throwsA(isA<AppException>()),
      );
      expect(
        () => repo.getMembersPage(
          access: branchManagerAccess(activeBranchId: null),
        ),
        throwsA(isA<AppException>()),
      );
    });

    test('employees cannot list organization members', () {
      expect(
        () => repo.getMembersPage(access: employeeAccess()),
        throwsA(isA<AccessDeniedException>()),
      );
    });

    test('pages through every member exactly once', () async {
      final seen = <String>[];
      var offset = 0;
      while (true) {
        final page = await repo.getMembersPage(
          access: orgAdminAccess(),
          limit: 2,
          offset: offset,
        );
        expect(page.total, 6);
        expect(page.items.length, lessThanOrEqualTo(2));
        seen.addAll(page.items.map((m) => m.id));
        if (!page.hasMore) break;
        offset = page.nextOffset;
      }
      expect(seen.toSet().length, 6);
      expect(seen.length, 6);
    });

    test('filters by status, role and name on the server side', () async {
      final suspended = await repo.getMembersPage(
        access: orgAdminAccess(),
        status: AccountStatus.suspended,
      );
      expect(suspended.items.map((m) => m.id), ['user-emp-04']);

      final managers = await repo.getMembersPage(
        access: orgAdminAccess(),
        role: UserRole.branchManager,
      );
      expect(managers.total, 2);

      final byName = await repo.getMembersPage(
        access: orgAdminAccess(),
        query: 'priya',
      );
      expect(byName.items.single.id, 'user-emp-03');
    });

    test('org admin creates an employee and receives the server id', () async {
      final created = await createEmployee();
      expect(created.id, isNotEmpty);
      expect(created.role, UserRole.employee);
      expect(created.branchIds.toSet(), {'br-01', 'br-02'});
      expect(created.status, AccountStatus.active);

      final fetched = await repo.getMember(
        access: orgAdminAccess(),
        memberId: created.id,
      );
      expect(fetched?.username, 'new.person');
    });

    test('org admin cannot create platform roles', () async {
      for (final role in [UserRole.platformAdmin, UserRole.platformOwner]) {
        await expectLater(
          repo.saveMember(
            access: orgAdminAccess(),
            member: memberDraft(role: role),
            initialPassword: _password,
          ),
          throwsA(isA<ValidationException>()),
          reason: role.name,
        );
      }
    });

    test(
      'branch manager creates employees only, in the active branch',
      () async {
        final bm = branchManagerAccess();
        await expectLater(
          repo.saveMember(
            access: bm,
            member: memberDraft(
              role: UserRole.branchManager,
              branches: ['br-01'],
            ),
            initialPassword: _password,
            activeBranchId: 'br-01',
          ),
          throwsA(isA<AccessDeniedException>()),
        );
        await expectLater(
          repo.saveMember(
            access: bm,
            member: memberDraft(branches: ['br-02']),
            initialPassword: _password,
            activeBranchId: 'br-01',
          ),
          throwsA(isA<ValidationException>()),
        );
        final ok = await repo.saveMember(
          access: bm,
          member: memberDraft(branches: ['br-01']),
          initialPassword: _password,
          activeBranchId: 'br-01',
        );
        expect(ok.branchIds, ['br-01']);
        expect(ok.role, UserRole.employee);
      },
    );

    test('editing preserves role and the other branch assignments', () async {
      final created = await createEmployee();
      final saved = await repo.saveMember(
        access: branchManagerAccess(),
        member: created.copyWith(
          fullName: 'Renamed Person',
          // A tampered or careless draft must not change role or branches.
          role: UserRole.branchManager,
          branchIds: ['br-01'],
        ),
        initialPassword: '',
        activeBranchId: 'br-01',
      );
      expect(saved.fullName, 'Renamed Person');
      expect(saved.role, UserRole.employee);
      expect(saved.branchIds.toSet(), {'br-01', 'br-02'});
    });

    test('branch manager cannot edit a co-manager', () async {
      final coManager = await repo.saveMember(
        access: orgAdminAccess(),
        member: memberDraft(
          username: 'co.manager',
          role: UserRole.branchManager,
          branches: ['br-01'],
        ),
        initialPassword: _password,
      );
      await expectLater(
        repo.saveMember(
          access: branchManagerAccess(),
          member: coManager.copyWith(fullName: 'Hijacked'),
          initialPassword: '',
          activeBranchId: 'br-01',
        ),
        throwsA(isA<AccessDeniedException>()),
      );
    });

    test('email and phone are optional but validated when provided', () async {
      final blank = await repo.saveMember(
        access: orgAdminAccess(),
        member: memberDraft(username: 'no.contact'),
        initialPassword: _password,
      );
      expect(blank.email, isEmpty);
      expect(blank.phone, isNull);

      Future<void> rejected(OrganizationMember draft, String password) =>
          expectLater(
            repo.saveMember(
              access: orgAdminAccess(),
              member: draft,
              initialPassword: password,
            ),
            throwsA(isA<ValidationException>()),
          );
      await rejected(
        memberDraft(username: 'bad.email', email: 'nope'),
        _password,
      );
      await rejected(
        memberDraft(username: 'bad.phone', phone: '98765'),
        _password,
      );
      await rejected(memberDraft(username: 'short.pass'), 'short');
      await rejected(memberDraft(username: 'x'), _password);
    });

    test('rejects a duplicate username', () async {
      await createEmployee(username: 'dup.user');
      await expectLater(
        createEmployee(username: 'dup.user'),
        throwsA(isA<AppException>()),
      );
    });

    test('suspends and restores within scope only', () async {
      final suspended = await repo.setMemberStatus(
        access: branchManagerAccess(),
        member: (await repo.getMember(
          access: orgAdminAccess(),
          memberId: 'user-emp-01',
        ))!,
        status: AccountStatus.suspended,
        activeBranchId: 'br-01',
      );
      expect(suspended.status, AccountStatus.suspended);

      final outside = (await repo.getMember(
        access: orgAdminAccess(),
        memberId: 'user-emp-03',
      ))!;
      await expectLater(
        repo.setMemberStatus(
          access: branchManagerAccess(),
          member: outside,
          status: AccountStatus.suspended,
          activeBranchId: 'br-01',
        ),
        throwsA(isA<AppException>()),
      );
    });

    test('getMember is scoped to the caller', () async {
      expect(
        await repo.getMember(access: orgAdminAccess(), memberId: 'nope'),
        isNull,
      );
      expect(
        await repo.getMember(
          access: branchManagerAccess(),
          memberId: 'user-emp-03',
          activeBranchId: 'br-01',
        ),
        isNull,
      );
    });
  });
}
