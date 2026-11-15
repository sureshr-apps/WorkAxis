import 'package:flutter_test/flutter_test.dart';
import 'package:workaxis/features/access/data/sql_connect_access_remote_data_source.dart';
import 'package:workaxis/features/authentication/domain/models/account_status.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';

import '../../helpers/fake_data_gateway.dart';

Map<String, dynamic> _branch({bool withOrg = false}) => {
  'id': 'b1',
  'name': 'Main',
  'code': 'MAIN',
  'location': null,
  'status': 'active',
  'isMainBranch': true,
  'geofenceRadiusMeters': 150,
  'latitude': 12.5,
  'longitude': 77,
  'kioskEnabled': null,
  if (withOrg) 'organization': {'id': 'org1'},
};

void main() {
  late FakeDataGateway gateway;
  late SqlConnectAccessRemoteDataSource source;

  setUp(() {
    gateway = FakeDataGateway();
    source = SqlConnectAccessRemoteDataSource(gateway: gateway);
  });

  test('fetchMyMember maps the member and organization', () async {
    gateway.respond('GetMyMember', {
      'organizationMembers': [
        {
          'id': 'm1',
          'authUid': 'u1',
          'fullName': 'Asha',
          'username': 'asha',
          'email': 'asha@x.com',
          'phone': null,
          'role': 'branchManager',
          'status': 'active',
          'organization': {
            'id': 'org1',
            'name': 'Acme',
            'code': 'ACME',
            'status': 'suspended',
          },
        },
      ],
    });

    final record = await source.fetchMyMember();

    expect(gateway.calls.single.op, 'GetMyMember');
    expect(gateway.calls.single.vars, isEmpty);
    expect(record!.memberId, 'm1');
    expect(record.authUid, 'u1');
    expect(record.role, UserRole.branchManager);
    expect(record.status, AccountStatus.active);
    expect(record.organization!.id, 'org1');
    expect(record.organization!.isActive, isFalse);
  });

  test('fetchMyMember returns null when the caller has no member', () async {
    gateway.respond('GetMyMember', {'organizationMembers': <dynamic>[]});
    expect(await source.fetchMyMember(), isNull);
  });

  test('fetchMyAssignedBranches maps nested branch rows', () async {
    gateway.respond('ListMyBranchAssignments', {
      'userBranchAssignments': [
        {'id': 'a1', 'branch': _branch(withOrg: true)},
      ],
    });

    final branches = await source.fetchMyAssignedBranches();

    expect(gateway.calls.single.op, 'ListMyBranchAssignments');
    expect(gateway.calls.single.vars, isEmpty);
    final b = branches.single;
    expect(b.id, 'b1');
    expect(b.organizationId, 'org1');
    expect(b.location, '');
    expect(b.latitude, 12.5);
    expect(b.longitude, 77.0);
    expect(b.geofenceRadiusMeters, 150);
    expect(b.isActive, isTrue);
  });

  test('fetchOrganizationBranches sends orgId and stamps it', () async {
    gateway.respond('ListBranchesByOrg', {
      'branches': [_branch()],
    });

    final branches = await source.fetchOrganizationBranches('org9');

    expect(gateway.singleVarsOf('ListBranchesByOrg'), {'orgId': 'org9'});
    expect(branches.single.organizationId, 'org9');
  });
}
