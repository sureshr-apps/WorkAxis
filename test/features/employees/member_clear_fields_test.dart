import 'package:flutter_test/flutter_test.dart';
import 'package:workaxis/core/backend/account_callables.dart';
import 'package:workaxis/features/employees/data/sql_connect_organization_members_repository.dart';
import 'package:workaxis/features/employees/domain/models/member_field.dart';
import 'package:workaxis/features/employees/domain/models/organization_member.dart';
import 'package:workaxis/features/employees/domain/policies/organization_member_policy.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';

import '../../contracts/acme_scenario.dart';
import '../../helpers/fake_callable_functions.dart';
import '../../helpers/fake_identity_server.dart';

const _clearable = [
  'aadhaarNumber',
  'aadhaarPhotoUrl',
  'dateOfBirth',
  'gender',
  'address',
  'profilePhotoUrl',
  'designation',
  'joiningDate',
  'relievingDate',
  'salary',
  'assetDetails',
];

OrganizationMember _fullyPopulated() => OrganizationMember(
  id: 'user-emp-01',
  authUid: 'user-emp-01',
  organizationId: 'org-acme',
  fullName: 'Sarah Connor',
  username: 'sarah.connor',
  email: 'sarah.connor@example.com',
  role: UserRole.employee,
  branchIds: const ['br-01'],
  status: acmeMemberSeed()[2].status,
  aadhaarNumber: '123456789012',
  aadhaarPhotoUrl: 'gs://bucket/aadhaar.jpg',
  dateOfBirth: DateTime(1990, 1, 2),
  gender: 'Female',
  address: '1 Main Street',
  profilePhotoUrl: 'gs://bucket/me.jpg',
  designation: 'Cashier',
  joiningDate: DateTime(2024, 3, 4),
  relievingDate: DateTime(2026, 12, 31),
  salary: 25000,
  assetDetails: 'Phone',
);

void main() {
  group('AccountCallables.update payload', () {
    late FakeCallableFunctions functions;
    late AccountCallables accounts;

    setUp(() {
      functions = FakeCallableFunctions({
        'updateUserAccount': (_) async => {'uid': 'u1'},
      });
      accounts = AccountCallables(functions);
    });

    test('cleared fields are sent as explicit null', () async {
      await accounts.update(
        targetUid: 'u1',
        clear: ClearableProfileField.values.toSet(),
      );
      final payload = functions.payloadsOf('updateUserAccount').single;
      for (final key in _clearable) {
        expect(payload, containsPair(key, null), reason: key);
      }
      expect(payload.containsKey('shiftHours'), isFalse);
      expect(payload.containsKey('dailyWorkHours'), isFalse);
      expect(payload.containsKey('employeeCode'), isFalse);
    });

    test(
      'untouched fields are omitted and set fields carry their value',
      () async {
        await accounts.update(
          targetUid: 'u1',
          designation: 'Lead',
          clear: {ClearableProfileField.address},
        );
        final payload = functions.payloadsOf('updateUserAccount').single;
        expect(payload['designation'], 'Lead');
        expect(payload, containsPair('address', null));
        for (final key in _clearable.where(
          (k) => k != 'designation' && k != 'address',
        )) {
          expect(payload.containsKey(key), isFalse, reason: key);
        }
      },
    );
  });

  group('repository clear semantics', () {
    late FakeIdentityServer server;
    late SqlConnectOrganizationMembersRepository repo;

    setUp(() {
      server = FakeIdentityServer([
        _fullyPopulated(),
        ...acmeMemberSeed().where((m) => m.id != 'user-emp-01'),
      ]);
      repo = SqlConnectOrganizationMembersRepository(
        dataSource: FakeMembersDataSource(server),
        accounts: AccountCallables(server),
      );
    });

    Map<String, dynamic> lastUpdate() =>
        server.callsTo('updateUserAccount').last.payload;

    test(
      'emptying every optional field sends an explicit null for each',
      () async {
        final existing = _fullyPopulated();
        await repo.saveMember(
          access: orgAdminAccess(),
          member: existing.copyWith(clear: MemberField.values.toSet()),
          initialPassword: '',
        );
        final payload = lastUpdate();
        for (final key in _clearable) {
          expect(payload, containsPair(key, null), reason: key);
        }
        // Required-for-everyone fields are never cleared.
        expect(payload['fullName'], 'Sarah Connor');
        expect(payload.containsKey('shiftHours'), isFalse);
        expect(payload.containsKey('dailyWorkHours'), isFalse);
        expect(payload.containsKey('employeeCode'), isFalse);
      },
    );

    test('an unchanged save sends none of the optional fields', () async {
      await repo.saveMember(
        access: orgAdminAccess(),
        member: _fullyPopulated(),
        initialPassword: '',
      );
      final payload = lastUpdate();
      for (final key in _clearable) {
        expect(payload.containsKey(key), isFalse, reason: key);
      }
    });

    test('only the emptied field is cleared, others stay omitted', () async {
      await repo.saveMember(
        access: orgAdminAccess(),
        member: _fullyPopulated().copyWith(
          clear: {MemberField.profilePhoto},
          designation: 'Senior Cashier',
        ),
        initialPassword: '',
      );
      final payload = lastUpdate();
      expect(payload, containsPair('profilePhotoUrl', null));
      expect(payload['designation'], 'Senior Cashier');
      expect(payload.containsKey('address'), isFalse);
      expect(payload.containsKey('salary'), isFalse);
    });

    test('a blank (not just null) field also counts as emptied', () async {
      await repo.saveMember(
        access: orgAdminAccess(),
        member: _fullyPopulated().copyWith(address: '   '),
        initialPassword: '',
      );
      expect(lastUpdate(), containsPair('address', null));
    });

    test(
      'a manager who could not read private fields never sends clears for them',
      () async {
        // What a Branch Manager loads: salary / Aadhaar are unknown (null).
        final seen = _fullyPopulated().copyWith(
          clear: {
            MemberField.salary,
            MemberField.aadhaarNumber,
            MemberField.aadhaarPhoto,
          },
        );
        server = FakeIdentityServer([seen]);
        repo = SqlConnectOrganizationMembersRepository(
          dataSource: FakeMembersDataSource(server),
          accounts: AccountCallables(server),
        );
        await repo.saveMember(
          access: branchManagerAccess(
            branchIds: const ['br-01'],
            activeBranchId: 'br-01',
          ),
          member: seen.copyWith(fullName: 'Sarah J Connor'),
          initialPassword: '',
          activeBranchId: 'br-01',
        );
        final payload = lastUpdate();
        expect(payload['fullName'], 'Sarah J Connor');
        for (final key in ['salary', 'aadhaarNumber', 'aadhaarPhotoUrl']) {
          expect(payload.containsKey(key), isFalse, reason: key);
        }
      },
    );
  });

  group('policy prepareUpdate', () {
    test('clearing a stored optional field yields null, not the old value', () {
      final existing = _fullyPopulated();
      final next = OrganizationMemberPolicy.prepareUpdate(
        access: orgAdminAccess(),
        existing: existing,
        draft: existing.copyWith(
          clear: {MemberField.designation, MemberField.salary},
        ),
      );
      expect(next.designation, isNull);
      expect(next.salary, isNull);
      expect(next.address, existing.address);
    });
  });
}
