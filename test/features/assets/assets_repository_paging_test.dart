import 'package:flutter_test/flutter_test.dart';
import 'package:workaxis/core/errors/app_exceptions.dart';
import 'package:workaxis/features/assets/data/mock_assets_repository.dart';
import 'package:workaxis/features/assets/data/sql_connect_assets_repository.dart';
import 'package:workaxis/features/assets/domain/models/asset_queue.dart';
import 'package:workaxis/features/employees/data/mock_organization_members_repository.dart';

import '../../helpers/access_fixtures.dart';
import '../../helpers/fake_data_gateway.dart';

Map<String, dynamic> _row(String id) => {
  'id': id,
  'organizationId': 'org-acme',
  'branchId': 'br-01',
  'branchName': 'Downtown Flagship',
  'employeeId': 'user-emp-01',
  'employeeName': 'Sarah Connor',
  'name': 'Work phone',
  'category': 'Device',
  'assetTag': 'WA-$id',
  'status': 'assigned',
};

FakeDataGateway _gateway() {
  Map<String, dynamic> answer(Map<String, dynamic> _) => {
    'employeeAssets': [_row('a1'), _row('a2')],
    'total': [
      {'_count': 7},
    ],
  };
  return FakeDataGateway({
    'ListMyEmployeeAssets': answer,
    'ListBranchEmployeeAssets': answer,
    'ListOrganizationEmployeeAssets': answer,
  });
}

void main() {
  group('SqlConnectAssetsRepository.getAssetsPage', () {
    test('Org Admin pages the organization listing', () async {
      final gateway = _gateway();
      final page = await SqlConnectAssetsRepository(gateway: gateway)
          .getAssetsPage(
            access: orgAdminAccess(),
            queue: AssetQueue.organization,
            offset: 25,
          );

      expect(gateway.singleVarsOf('ListOrganizationEmployeeAssets'), {
        'limit': 25,
        'offset': 25,
      });
      expect(page.items.map((a) => a.id), ['a1', 'a2']);
      expect(page.total, 7);
      expect(page.offset, 25);
    });

    test('a trimmed search is sent to the server; blank is omitted', () async {
      final gateway = _gateway();
      final repository = SqlConnectAssetsRepository(gateway: gateway);
      await repository.getAssetsPage(
        access: employeeAccess(),
        queue: AssetQueue.mine,
        query: '  laptop ',
        limit: 10,
      );
      await repository.getAssetsPage(
        access: employeeAccess(),
        queue: AssetQueue.mine,
        query: '   ',
      );

      expect(gateway.varsOf('ListMyEmployeeAssets'), [
        {'limit': 10, 'offset': 0, 'query': 'laptop'},
        {'limit': 25, 'offset': 0},
      ]);
    });

    test('each Branch Manager queue maps to exactly one server op', () async {
      final gateway = _gateway();
      final repository = SqlConnectAssetsRepository(gateway: gateway);
      final access = branchManagerAccess();

      await repository.getAssetsPage(
        access: access,
        queue: AssetQueue.mine,
        activeBranchId: 'br-02',
        query: 'scanner',
      );
      expect(gateway.calls.map((c) => c.op), ['ListMyEmployeeAssets']);
      expect(gateway.singleVarsOf('ListMyEmployeeAssets'), {
        'branchId': 'br-02',
        'activeBranchId': 'br-02',
        'limit': 25,
        'offset': 0,
        'query': 'scanner',
      });

      gateway.calls.clear();
      await repository.getAssetsPage(
        access: access,
        queue: AssetQueue.branchEmployees,
        offset: 50,
      );
      expect(gateway.calls.map((c) => c.op), ['ListBranchEmployeeAssets']);
      expect(gateway.singleVarsOf('ListBranchEmployeeAssets'), {
        'branchId': 'br-01',
        'activeBranchId': 'br-01',
        'limit': 25,
        'offset': 50,
      });
    });

    test('rejects queues outside the role locally', () async {
      final gateway = _gateway();
      final repository = SqlConnectAssetsRepository(gateway: gateway);

      await expectLater(
        repository.getAssetsPage(
          access: employeeAccess(),
          queue: AssetQueue.organization,
        ),
        throwsA(isA<AccessDeniedException>()),
      );
      await expectLater(
        repository.getAssetsPage(
          access: orgAdminAccess(),
          queue: AssetQueue.branchEmployees,
        ),
        throwsA(isA<AccessDeniedException>()),
      );
      await expectLater(
        repository.getAssetsPage(
          access: branchManagerAccess(activeBranchId: null),
          queue: AssetQueue.branchEmployees,
        ),
        throwsA(isA<BranchAuthorizationException>()),
      );
      expect(gateway.calls, isEmpty);
    });
  });

  group('MockAssetsRepository.getAssetsPage', () {
    late MockAssetsRepository repository;

    setUp(() {
      repository = MockAssetsRepository(
        members: MockOrganizationMembersRepository(),
      );
    });

    Future<List<String>> ids({String? query, int offset = 0, int limit = 25}) =>
        repository
            .getAssetsPage(
              access: orgAdminAccess(),
              queue: AssetQueue.organization,
              query: query,
              offset: offset,
              limit: limit,
            )
            .then((page) => page.items.map((a) => a.id).toList());

    test('orders by holder name, then asset name', () async {
      // Alex Chen, Daniel Kim, Priya Shah, then Sarah Connor's two assets
      // (Android handheld before Staff access card).
      expect(await ids(), [
        'asset-003',
        'asset-005',
        'asset-004',
        'asset-001',
        'asset-002',
      ]);
    });

    test('pages with offset and limit and reports the full total', () async {
      final page = await repository.getAssetsPage(
        access: orgAdminAccess(),
        queue: AssetQueue.organization,
        offset: 1,
        limit: 2,
      );
      expect(page.items.map((a) => a.id), ['asset-005', 'asset-004']);
      expect(page.total, 5);
      expect(page.offset, 1);
      expect(page.hasMore, isTrue);
    });

    test('searches name, category, tag, serial, holder, and branch', () async {
      expect(await ids(query: 'BARCODE'), ['asset-003']);
      expect(await ids(query: 'access card'), ['asset-002']);
      expect(await ids(query: 'wa-lap'), ['asset-004']);
      expect(await ids(query: 'sc-773'), ['asset-003']);
      expect(await ids(query: 'sarah'), ['asset-001', 'asset-002']);
      expect(await ids(query: 'westside'), ['asset-004']);
      expect(await ids(query: 'no such asset'), isEmpty);
    });

    test('an employee reads only their own assets', () async {
      final page = await repository.getAssetsPage(
        access: employeeAccess(),
        queue: AssetQueue.mine,
      );
      expect(page.items.map((a) => a.id), ['asset-001', 'asset-002']);
      await expectLater(
        repository.getAssetsPage(
          access: employeeAccess(),
          queue: AssetQueue.organization,
        ),
        throwsA(isA<AccessDeniedException>()),
      );
    });
  });
}
