import 'package:flutter_test/flutter_test.dart';
import 'package:workaxis/features/branch_dashboard/data/branch_dashboard_remote.dart';
import 'package:workaxis/features/organization_dashboard/data/organization_dashboard_remote.dart';
import 'package:workaxis/features/platform_dashboard/data/platform_dashboard_remote.dart';

import '../../helpers/fake_data_gateway.dart';

void main() {
  late FakeDataGateway gateway;

  setUp(() => gateway = FakeDataGateway());

  test('branch counts come from GetBranchStats', () async {
    gateway.respond('GetBranchStats', {
      'memberCount': [
        {'_count': 6},
      ],
      'returnsByStatus': [
        {'status': 'Pending', '_count': 2},
        {'status': 'approved', '_count': 5},
      ],
      'returnsByReason': <dynamic>[],
    });

    final counts = await DataConnectBranchDashboardRemote(gateway: gateway)
        .loadCounts('b1');

    expect(gateway.singleVarsOf('GetBranchStats'), {'branchId': 'b1'});
    expect(counts.memberCount, 6);
    expect(counts.returns('pending'), 2);
    expect(counts.returns('approved'), 5);
  });

  test(
    'organization counts come from GetOrganizationDashboardCounts',
    () async {
      gateway.respond('GetOrganizationDashboardCounts', {
        'branchesByStatus': [
          {'status': 'active', '_count': 3},
          {'status': 'maintenance', '_count': 1},
        ],
        'membersByRole': [
          {'role': 'employee', 'status': 'active', '_count': 20},
          {'role': 'employee', 'status': 'suspended', '_count': 4},
          {'role': 'branchManager', 'status': 'active', '_count': 2},
        ],
        'returnsByStatus': [
          {'status': 'pending', '_count': 7},
        ],
      });

      final counts = await DataConnectOrganizationDashboardRemote(
        gateway: gateway,
      ).loadCounts('org1');

      expect(gateway.singleVarsOf('GetOrganizationDashboardCounts'), {
        'orgId': 'org1',
      });
      expect(counts.activeEmployees, 20);
      expect(counts.totalBranches, 4);
      expect(counts.branches('maintenance'), 1);
      expect(counts.returns('pending'), 7);
    },
  );

  test('platform stats come from GetPlatformStats', () async {
    gateway.respond('GetPlatformStats', {
      'organizationsByStatus': [
        {'status': 'active', '_count': 8},
        {'status': 'suspended', '_count': 2},
      ],
      'platformAdminCount': [
        {'_count': 3},
      ],
    });

    final stats = await DataConnectPlatformDashboardRemote(gateway: gateway)
        .loadStats();

    expect(gateway.singleVarsOf('GetPlatformStats'), isEmpty);
    expect(stats.organizationsByStatus, {'active': 8, 'suspended': 2});
    expect(stats.platformAdminCount, 3);
  });

  test('recent organizations fetch a page, then stats per row', () async {
    gateway
      ..respond('ListOrganizationsPaged', {
        'organizations': [
          {
            'id': 'o1',
            'name': 'Acme',
            'code': 'ACME',
            'category': null,
            'country': 'India',
            'status': 'active',
            'currency': 'INR',
            'createdAt': '2026-04-01T00:00:00Z',
          },
        ],
        'total': [
          {'_count': 1},
        ],
      })
      ..respond('GetOrganizationStats', {
        'branchCount': [
          {'_count': 2},
        ],
        'memberCount': [
          {'_count': 9},
        ],
      });

    final recent = await DataConnectPlatformDashboardRemote(gateway: gateway)
        .loadRecentOrganizations(limit: 5);

    expect(gateway.singleVarsOf('ListOrganizationsPaged'), {
      'limit': 5,
      'offset': 0,
    });
    expect(gateway.singleVarsOf('GetOrganizationStats'), {'orgId': 'o1'});
    final r = recent.single;
    expect(r.branchCount, 2);
    expect(r.employeeCount, 9);
    expect(r.createdAt, DateTime.utc(2026, 4));
  });
}
