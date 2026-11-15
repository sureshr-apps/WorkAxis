import 'package:flutter_test/flutter_test.dart';
import 'package:workaxis/features/platform_organizations/data/sql_connect_platform_organizations_remote_data_source.dart';
import 'package:workaxis/features/platform_organizations/domain/models/create_organization_request.dart';
import 'package:workaxis/features/platform_organizations/domain/models/customer_organization.dart';
import 'package:workaxis/features/platform_organizations/domain/models/organization_status.dart';

import '../../helpers/fake_data_gateway.dart';

Map<String, dynamic> _org() => {
  'id': 'org1',
  'name': 'Acme',
  'code': 'ACME',
  'category': 'Retail',
  'country': 'India',
  'status': 'active',
  'currency': 'INR',
  'logoUrl': null,
  'taxIdentification': 'GST1',
  'description': '  ',
  'contactName': 'Anil',
  'contactEmail': 'a@acme.com',
  'contactPhone': null,
  'address': 'Pune',
  'createdAt': '2026-03-01T08:00:00.000Z',
};

void main() {
  late FakeDataGateway gateway;
  late SqlConnectPlatformOrganizationsRemoteDataSource source;

  setUp(() {
    gateway = FakeDataGateway();
    source = SqlConnectPlatformOrganizationsRemoteDataSource(gateway: gateway);
  });

  test('listPage omits unset filters and maps rows and total', () async {
    gateway.respond('ListOrganizationsPaged', {
      'organizations': [_org()],
      'total': [
        {'_count': 9},
      ],
    });

    final page = await source.listPage(limit: 25, offset: 0);

    expect(gateway.singleVarsOf('ListOrganizationsPaged'), {
      'limit': 25,
      'offset': 0,
    });
    expect(page.total, 9);
    final o = page.items.single;
    expect(o.status, OrganizationStatus.active);
    expect(o.category, 'Retail');
    expect(o.createdAt, DateTime.utc(2026, 3, 1, 8));
    expect(o.branchCount, isNull);
  });

  test('listPage maps the branch and member counts each row carries', () async {
    gateway.respond('ListOrganizationsPaged', {
      'organizations': [
        {..._org(), 'branchCount': 3, 'memberCount': 11},
      ],
      'total': [
        {'_count': 1},
      ],
    });

    final o = (await source.listPage(limit: 25, offset: 0)).items.single;

    expect(o.branchCount, 3);
    expect(o.employeeCount, 11);
  });

  test('listPage sends trimmed name and status filters', () async {
    gateway.respond('ListOrganizationsPaged', {
      'organizations': <dynamic>[],
      'total': <dynamic>[],
    });
    await source.listPage(
      limit: 5,
      offset: 5,
      nameContains: ' ac ',
      status: OrganizationStatus.suspended,
    );
    expect(gateway.singleVarsOf('ListOrganizationsPaged'), {
      'limit': 5,
      'offset': 5,
      'nameContains': 'ac',
      'status': 'suspended',
    });
  });

  test('statusCounts reads GetPlatformStats groups', () async {
    gateway.respond('GetPlatformStats', {
      'organizationsByStatus': [
        {'status': 'active', '_count': 4},
        {'status': 'suspended', '_count': 1},
      ],
      'platformAdminCount': [
        {'_count': 2},
      ],
    });
    final counts = await source.statusCounts();
    expect(gateway.singleVarsOf('GetPlatformStats'), isEmpty);
    expect(counts.active, 4);
    expect(counts.suspended, 1);
  });

  test('getById combines org, stats and org admins', () async {
    gateway
      ..respond('GetOrganizationById', {'organization': _org()})
      ..respond('GetOrganizationStats', {
        'branchCount': [
          {'_count': 3},
        ],
        'memberCount': [
          {'_count': 12},
        ],
      })
      ..respond('ListMembersByOrgPaged', {
        'organizationMembers': [
          {
            'id': 'm1',
            'authUid': 'u1',
            'fullName': 'Anil',
            'username': 'anil',
            'email': 'anil@example.com',
            'phone': null,
            'role': 'orgAdmin',
            'status': 'active',
            'userBranchAssignments_on_member': <dynamic>[],
          },
        ],
        'total': [
          {'_count': 1},
        ],
      });

    final o = (await source.getById('org1'))!;

    expect(gateway.singleVarsOf('GetOrganizationById'), {'id': 'org1'});
    expect(gateway.singleVarsOf('GetOrganizationStats'), {'orgId': 'org1'});
    expect(gateway.singleVarsOf('ListMembersByOrgPaged'), {
      'orgId': 'org1',
      'limit': 50,
      'offset': 0,
      'role': 'orgAdmin',
    });
    expect(o.branchCount, 3);
    expect(o.employeeCount, 12);
    expect(o.description, isNull, reason: 'blank maps to null');
    expect(o.contactPhone, isNull);
    expect(o.taxIdentification, 'GST1');
    expect(o.admins.single.username, 'anil');
    expect(o.admins.single.phone, '');
  });

  test('getById returns null when the organization is absent', () async {
    gateway
      ..respond('GetOrganizationById', {'organization': null})
      ..respond('GetOrganizationStats', {
        'branchCount': <dynamic>[],
        'memberCount': <dynamic>[],
      })
      ..respond('ListMembersByOrgPaged', {
        'organizationMembers': <dynamic>[],
        'total': <dynamic>[],
      });
    expect(await source.getById('missing'), isNull);
  });

  test('create omits blank optionals and returns the new id', () async {
    gateway.respond('CreateOrganization', {
      'organization_insert': {'id': 'new-org'},
    });

    final id = await source.create(
      const CreateOrganizationRequest(
        name: ' Acme ',
        category: ' Retail ',
        description: '   ',
        contactEmail: 'a@acme.com',
      ),
      code: 'ACME',
    );

    expect(id, 'new-org');
    expect(gateway.singleVarsOf('CreateOrganization'), {
      'name': 'Acme',
      'code': 'ACME',
      'country': 'India',
      'currency': 'INR',
      'status': 'active',
      'category': 'Retail',
      'contactEmail': 'a@acme.com',
    });
  });

  test('update writes every editable field, blanks as empty strings', () async {
    gateway.respond('UpdateOrganization', {
      'organization_update': {'id': 'org1'},
    });

    await source.update(
      CustomerOrganization(
        id: 'org1',
        name: ' Acme ',
        code: 'ACME',
        status: OrganizationStatus.active,
        createdAt: DateTime.utc(2026),
        category: 'Retail',
        branchCount: null,
        employeeCount: null,
      ),
    );

    expect(gateway.singleVarsOf('UpdateOrganization'), {
      'id': 'org1',
      'name': 'Acme',
      'category': 'Retail',
      'description': '',
      'taxIdentification': '',
      'contactName': '',
      'contactEmail': '',
      'contactPhone': '',
      'address': '',
    });
  });
}
