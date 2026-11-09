import 'package:flutter_test/flutter_test.dart';
import 'package:workaxis/core/errors/app_exceptions.dart';
import 'package:workaxis/features/access/data/mock_access_data_source.dart';
import 'package:workaxis/features/access/domain/models/organization_summary.dart';
import 'package:workaxis/features/branches/data/mock_branch_management_repository.dart';
import 'package:workaxis/features/branches/data/sql_connect_branch_management_repository.dart';
import 'package:workaxis/features/branches/domain/branch_geofence_validator.dart';
import 'package:workaxis/features/branches/domain/policies/branch_management_policy.dart';

import '../../contracts/acme_scenario.dart';
import '../../contracts/branch_management_contract.dart';
import '../../helpers/fake_branches_data_source.dart';
import '../../helpers/fake_branch_save.dart';
import '../../helpers/fake_callable_functions.dart';
import '../../helpers/fake_identity_server.dart';

class _Wiring {
  _Wiring() {
    server = FakeIdentityServer(acmeMemberSeed());
    branches = FakeBranchesDataSource();
    functions = FakeCallableFunctions({
      'saveBranch': (p) => fakeBranchSave(branches, server, p),
      'createKioskPairingToken': (payload) async {
        _tokens++;
        return {
          'token': 'tok-$_tokens-${payload['branchId']}',
          'expiresAt': '2026-11-07T10:00:00.000Z',
          'branchId': payload['branchId'],
        };
      },
    });
    repo = SqlConnectBranchManagementRepository(
      branches: branches,
      members: FakeMembersDataSource(server),

      functions: functions,
    );
  }

  late final FakeIdentityServer server;
  late final FakeBranchesDataSource branches;
  late final FakeCallableFunctions functions;
  late final SqlConnectBranchManagementRepository repo;
  int _tokens = 0;
}

void main() {
  runBranchManagementContract(
    'mock',
    () => MockBranchManagementRepository(
      accessDataSource: MockAccessDataSource(),
    ),
  );
  runBranchManagementContract('SQL Connect with fakes', () => _Wiring().repo);

  group('SqlConnectBranchManagementRepository specifics', () {
    late _Wiring w;
    setUp(() => w = _Wiring());

    test('kiosk pairing uses the callable, not a client-made token', () async {
      final token = await w.repo.createKioskPairingToken(
        access: orgAdminAccess(),
        branchId: 'br-01',
      );
      expect(token.value, startsWith('tok-1-br-01'));
      expect(token.expiresAt, isNotNull);
      expect(w.functions.payloadsOf('createKioskPairingToken').single, {
        'branchId': 'br-01',
      });
    });

    test('kiosk pairing completes on the device, not from the app', () async {
      await expectLater(
        w.repo.completeKioskPairing(
          access: orgAdminAccess(),
          branchId: 'br-01',
        ),
        throwsA(isA<AppException>()),
      );
    });

    test(
      'manager assignment edits the manager account, preserving others',
      () async {
        final existing = (await w.repo.getBranch(orgAdminAccess(), 'br-01'))!;
        await w.repo.saveBranch(
          access: orgAdminAccess(),
          branch: existing.copyWith(managerIds: ['user-bm-single-01']),
        );
        final sophia = w.server.byId('user-bm-single-01')!;
        expect(sophia.branchIds.toSet(), {'br-04', 'br-01'});
        final marcus = w.server.byId('user-bm-multi-01')!;
        expect(marcus.branchIds.toSet(), {'br-02', 'br-03'});
        final payload = w.functions.payloadsOf('saveBranch').single;
        expect(payload['managerIds'], ['user-bm-single-01']);
      },
    );

    test('a branch the user cannot see is reported as missing', () async {
      final other = orgAdminAccess().copyWith(
        organization: const OrganizationSummary(
          id: 'org-other',
          name: 'Other',
          code: 'OTH',
        ),
      );
      expect(await w.repo.getBranch(other, 'br-01'), isNull);
    });

    test('update does not move a branch to another organization', () async {
      final existing = (await w.repo.getBranch(orgAdminAccess(), 'br-01'))!;
      final moved = existing.copyWith(
        summary: existing.summary.copyWith(organizationId: 'org-other'),
      );
      await expectLater(
        w.repo.saveBranch(access: orgAdminAccess(), branch: moved),
        throwsA(isA<AppException>()),
      );
      expect(w.branches.updated, isEmpty);
    });

    test('create sends no coordinates when none are configured', () async {
      final saved = await w.repo.saveBranch(
        access: orgAdminAccess(),
        branch: branchDraft(latitude: null, longitude: null),
      );
      expect(saved.hasGeofence, isFalse);
      expect(w.branches.added.single.latitude, isNull);
    });

    test('server-assigned ids are used', () async {
      final saved = await w.repo.saveBranch(
        access: orgAdminAccess(),
        branch: branchDraft(),
      );
      expect(saved.id, startsWith('srv-br-'));
    });
  });

  group('BranchGeofenceValidator', () {
    test('accepts the documented range and unconfigured coordinates', () {
      BranchGeofenceValidator.validate(
        latitude: null,
        longitude: null,
        radiusMeters: BranchGeofenceValidator.minRadiusMeters,
      );
      BranchGeofenceValidator.validate(
        latitude: -33.86,
        longitude: 151.2,
        radiusMeters: BranchGeofenceValidator.maxRadiusMeters,
      );
    });

    test('the app minimum is stricter than the server minimum', () {
      expect(BranchGeofenceValidator.minRadiusMeters, greaterThanOrEqualTo(10));
      expect(BranchGeofenceValidator.maxRadiusMeters, lessThanOrEqualTo(5000));
    });
  });

  group('BranchManagementPolicy', () {
    test('only org admins manage branches', () {
      expect(
        () => BranchManagementPolicy.requireOrgAdminOrganization(
          branchManagerAccess(),
        ),
        throwsA(isA<AccessDeniedException>()),
      );
      expect(
        BranchManagementPolicy.requireOrgAdminOrganization(orgAdminAccess()),
        'org-acme',
      );
    });
  });

  test('BranchRecord keeps coordinates nullable', () {
    final record = branchDraft(latitude: null, longitude: null);
    expect(record.hasGeofence, isFalse);
    expect(record.copyWith(latitude: 1, longitude: 2).hasGeofence, isTrue);
  });
}
