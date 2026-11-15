import 'package:flutter_test/flutter_test.dart';
import 'package:workaxis/features/authentication/domain/models/account_status.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';
import 'package:workaxis/features/employees/data/sql_connect_organization_members_remote_data_source.dart';

import '../../helpers/fake_data_gateway.dart';

Map<String, dynamic> _member({String role = 'employee', String? phone}) => {
  'id': 'm1',
  'authUid': 'u1',
  'fullName': 'Ravi',
  'username': 'ravi',
  'email': 'ravi@example.com',
  'phone': phone,
  'role': role,
  'status': 'active',
  'userBranchAssignments_on_member': [
    {
      'branch': {'id': 'b1'},
    },
    {
      'branch': {'id': 'b2'},
    },
  ],
};

void main() {
  late FakeDataGateway gateway;
  late SqlConnectOrganizationMembersRemoteDataSource source;

  setUp(() {
    gateway = FakeDataGateway();
    source = SqlConnectOrganizationMembersRemoteDataSource(gateway: gateway);
  });

  test('listByOrganization omits unset filters and maps the page', () async {
    gateway.respond('ListMembersByOrgPaged', {
      'organizationMembers': [_member(role: 'bogus')],
      'total': [
        {'_count': 41},
      ],
    });

    final page = await source.listByOrganization(
      organizationId: 'org1',
      limit: 25,
      offset: 50,
    );

    expect(gateway.singleVarsOf('ListMembersByOrgPaged'), {
      'orgId': 'org1',
      'limit': 25,
      'offset': 50,
    });
    expect(page.total, 41);
    expect(page.offset, 50);
    final m = page.items.single;
    expect(m.organizationId, 'org1');
    expect(m.role, UserRole.employee, reason: 'unknown roles fail closed');
    expect(m.branchIds, ['b1', 'b2']);
    expect(m.phone, isNull);
  });

  test('listByOrganization sends filters when set', () async {
    gateway.respond('ListMembersByOrgPaged', {
      'organizationMembers': <dynamic>[],
      'total': <dynamic>[],
    });

    final page = await source.listByOrganization(
      organizationId: 'org1',
      limit: 10,
      offset: 0,
      nameContains: 'rav',
      status: AccountStatus.suspended,
      role: UserRole.branchManager,
    );

    expect(page.total, 0);
    expect(gateway.singleVarsOf('ListMembersByOrgPaged'), {
      'orgId': 'org1',
      'limit': 10,
      'offset': 0,
      'nameContains': 'rav',
      'status': 'suspended',
      'role': 'branchManager',
    });
  });

  test('listByBranch reads members from assignment rows', () async {
    gateway.respond('ListMembersByBranchPaged', {
      'userBranchAssignments': [
        {'member': _member(phone: '+911234567890')},
      ],
      'total': [
        {'_count': 1},
      ],
    });

    final page = await source.listByBranch(
      organizationId: 'org1',
      branchId: 'b1',
      limit: 25,
      offset: 0,
      status: AccountStatus.active,
    );

    expect(gateway.singleVarsOf('ListMembersByBranchPaged'), {
      'branchId': 'b1',
      'limit': 25,
      'offset': 0,
      'status': 'active',
    });
    expect(page.items.single.phone, '+911234567890');
    expect(page.items.single.organizationId, 'org1');
    expect(page.total, 1);
  });

  test('getById maps a member and returns null when absent', () async {
    gateway.respond('GetMemberById', {
      'organizationMember': {
        ..._member(),
        'createdAt': '2026-01-01T00:00:00Z',
        'organization': {'id': 'org7'},
      },
    });
    final found = await source.getById('m1');
    expect(gateway.singleVarsOf('GetMemberById'), {'id': 'm1'});
    expect(found!.organizationId, 'org7');

    gateway.respond('GetMemberById', {'organizationMember': null});
    expect(await source.getById('m2'), isNull);
  });
}
