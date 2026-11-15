import 'package:flutter_test/flutter_test.dart';
import 'package:workaxis/features/branches/data/sql_connect_branches_remote_data_source.dart';
import 'package:workaxis/features/branches/domain/models/branch_record.dart';

import '../../helpers/fake_data_gateway.dart';

Map<String, dynamic> _row({bool withOrg = false}) => {
  'id': 'b1',
  'name': 'Main',
  'code': 'MAIN',
  'location': 'Pune',
  'status': 'active',
  'isMainBranch': true,
  'geofenceRadiusMeters': null,
  'latitude': 18.5,
  'longitude': 73.8,
  'kioskEnabled': true,
  if (withOrg) 'organization': {'id': 'org1'},
};

void main() {
  late FakeDataGateway gateway;
  late SqlConnectBranchesRemoteDataSource source;

  setUp(() {
    gateway = FakeDataGateway();
    source = SqlConnectBranchesRemoteDataSource(gateway: gateway);
  });

  test('listByOrganization maps rows and defaults the radius', () async {
    gateway.respond('ListBranchesByOrg', {
      'branches': [_row()],
    });

    final branches = await source.listByOrganization('org1');

    expect(gateway.singleVarsOf('ListBranchesByOrg'), {'orgId': 'org1'});
    final b = branches.single;
    expect(b.organizationId, 'org1');
    expect(b.location, 'Pune');
    expect(b.latitude, 18.5);
    expect(b.isMainBranch, isTrue);
    expect(b.kioskStatus, KioskPairingStatus.paired);
    expect(b.geofenceRadiusMeters, isPositive);
  });

  test(
    'getById reads the organization from the row; null when absent',
    () async {
      gateway.respond('GetBranchById', {'branch': _row(withOrg: true)});
      final found = await source.getById('b1');
      expect(gateway.singleVarsOf('GetBranchById'), {'id': 'b1'});
      expect(found!.organizationId, 'org1');

      gateway.respond('GetBranchById', {'branch': null});
      expect(await source.getById('b2'), isNull);
    },
  );
}
