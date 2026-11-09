import 'package:flutter_test/flutter_test.dart';
import 'package:workaxis/core/errors/app_exceptions.dart';
import 'package:workaxis/core/errors/validation_exception.dart';
import 'package:workaxis/features/access/domain/models/branch_summary.dart';
import 'package:workaxis/features/branches/domain/models/branch_record.dart';
import 'package:workaxis/features/branches/domain/repositories/branch_management_repository.dart';

import 'acme_scenario.dart';

BranchRecord branchDraft({
  String id = '',
  String name = 'Harbour Branch',
  String code = '',
  String location = 'Harbour Road',
  int radius = 120,
  double? latitude = 12.9716,
  double? longitude = 77.5946,
  bool isActive = true,
  bool isMain = false,
  List<String> managerIds = const [],
}) => BranchRecord(
  summary: BranchSummary(
    id: id,
    organizationId: 'org-acme',
    name: name,
    code: code,
    location: location,
    isActive: isActive,
  ),
  geofenceRadiusMeters: radius,
  latitude: latitude,
  longitude: longitude,
  isMainBranch: isMain,
  managerIds: managerIds,
  kioskStatus: KioskPairingStatus.notPaired,
);

/// Behaviour every [BranchManagementRepository] must provide. Fixture: Acme
/// branches br-01..br-04; Marcus manages br-01..br-03, Sophia manages br-04.
void runBranchManagementContract(
  String label,
  BranchManagementRepository Function() create,
) {
  group('BranchManagementRepository contract ($label)', () {
    late BranchManagementRepository repo;
    setUp(() => repo = create());

    test('org admin lists every organization branch', () async {
      final branches = await repo.getBranches(orgAdminAccess());
      expect(branches.map((b) => b.id).toSet(), {
        'br-01',
        'br-02',
        'br-03',
        'br-04',
      });
    });

    test('branch managers cannot read or manage branches', () async {
      await expectLater(
        repo.getBranches(branchManagerAccess()),
        throwsA(isA<AccessDeniedException>()),
      );
    });

    test('getBranch returns managers or null for unknown ids', () async {
      final branch = await repo.getBranch(orgAdminAccess(), 'br-01');
      expect(branch, isNotNull);
      expect(branch!.managerIds, contains('user-bm-multi-01'));
      expect(branch.managerIds, isNot(contains('user-bm-single-01')));
      expect(await repo.getBranch(orgAdminAccess(), 'nope'), isNull);
    });

    test('branch managers cannot create branches', () async {
      await expectLater(
        repo.saveBranch(access: branchManagerAccess(), branch: branchDraft()),
        throwsA(isA<AccessDeniedException>()),
      );
    });

    test('create returns a server id and the saved fields', () async {
      final saved = await repo.saveBranch(
        access: orgAdminAccess(),
        branch: branchDraft(isMain: true),
      );
      expect(saved.id, isNotEmpty);
      expect(saved.code, isNotEmpty);
      expect(saved.name, 'Harbour Branch');
      expect(saved.geofenceRadiusMeters, 120);
      expect(saved.latitude, 12.9716);
      expect(saved.longitude, 77.5946);
      expect(saved.isMainBranch, isTrue);
      expect(saved.isActive, isTrue);
      expect(saved.hasGeofence, isTrue);
      expect(await repo.getBranch(orgAdminAccess(), saved.id), isNotNull);
    });

    test('a branch without coordinates is saved as not configured', () async {
      final saved = await repo.saveBranch(
        access: orgAdminAccess(),
        branch: branchDraft(latitude: null, longitude: null),
      );
      expect(saved.latitude, isNull);
      expect(saved.longitude, isNull);
      expect(saved.hasGeofence, isFalse);
    });

    test('rejects invalid geofence input', () async {
      final bad = <String, BranchRecord>{
        'zero coordinates': branchDraft(latitude: 0, longitude: 0),
        'latitude out of range': branchDraft(latitude: 91),
        'longitude out of range': branchDraft(longitude: -181),
        'only latitude': branchDraft(longitude: null),
        'radius too small': branchDraft(radius: 24),
        'radius too large': branchDraft(radius: 5001),
        'blank name': branchDraft(name: ' '),
        'blank location': branchDraft(location: ' '),
      };
      for (final entry in bad.entries) {
        await expectLater(
          repo.saveBranch(access: orgAdminAccess(), branch: entry.value),
          throwsA(isA<ValidationException>()),
          reason: entry.key,
        );
      }
    });

    test('rejects a duplicate branch code', () async {
      await expectLater(
        repo.saveBranch(
          access: orgAdminAccess(),
          branch: branchDraft(code: 'BR-101'),
        ),
        throwsA(isA<AppException>()),
      );
    });

    test('update persists status, main flag and geofence', () async {
      final existing = (await repo.getBranch(orgAdminAccess(), 'br-02'))!;
      final saved = await repo.saveBranch(
        access: orgAdminAccess(),
        branch: existing.copyWith(
          summary: existing.summary.copyWith(
            name: 'Westside Renamed',
            isActive: false,
          ),
          isMainBranch: true,
          geofenceRadiusMeters: 300,
          latitude: 19.07,
          longitude: 72.87,
        ),
      );
      expect(saved.id, 'br-02');
      expect(saved.name, 'Westside Renamed');
      expect(saved.isActive, isFalse);
      expect(saved.isMainBranch, isTrue);
      expect(saved.geofenceRadiusMeters, 300);
      expect(saved.latitude, 19.07);
      final reloaded = (await repo.getBranch(orgAdminAccess(), 'br-02'))!;
      expect(reloaded.isActive, isFalse);
      expect(reloaded.isMainBranch, isTrue);
    });

    test('clearing an existing geofence persists null coordinates', () async {
      final existing = (await repo.getBranch(orgAdminAccess(), 'br-02'))!;
      final cleared = BranchRecord(
        summary: existing.summary,
        geofenceRadiusMeters: existing.geofenceRadiusMeters,
        managerIds: existing.managerIds,
        kioskStatus: existing.kioskStatus,
        latitude: null,
        longitude: null,
      );
      await repo.saveBranch(access: orgAdminAccess(), branch: cleared);
      expect(
        (await repo.getBranch(orgAdminAccess(), existing.id))!.hasGeofence,
        isFalse,
      );
    });

    test('assigns and unassigns branch managers', () async {
      final existing = (await repo.getBranch(orgAdminAccess(), 'br-01'))!;
      final saved = await repo.saveBranch(
        access: orgAdminAccess(),
        branch: existing.copyWith(managerIds: ['user-bm-single-01']),
      );
      expect(saved.managerIds, ['user-bm-single-01']);
    });

    test('managers outside the organization cannot be assigned', () async {
      final existing = (await repo.getBranch(orgAdminAccess(), 'br-01'))!;
      await expectLater(
        repo.saveBranch(
          access: orgAdminAccess(),
          branch: existing.copyWith(managerIds: ['not-a-member']),
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('a manager cannot be left without any branch', () async {
      final existing = (await repo.getBranch(orgAdminAccess(), 'br-04'))!;
      await expectLater(
        repo.saveBranch(
          access: orgAdminAccess(),
          branch: existing.copyWith(managerIds: const []),
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('kiosk pairing issues a code for permitted callers only', () async {
      final token = await repo.createKioskPairingToken(
        access: orgAdminAccess(),
        branchId: 'br-01',
      );
      expect(token.branchId, 'br-01');
      expect(token.value, isNotEmpty);

      final own = await repo.createKioskPairingToken(
        access: branchManagerAccess(),
        branchId: 'br-01',
      );
      expect(own.value, isNotEmpty);
      await expectLater(
        repo.createKioskPairingToken(
          access: branchManagerAccess(),
          branchId: 'br-04',
        ),
        throwsA(isA<AccessDeniedException>()),
      );
      await expectLater(
        repo.createKioskPairingToken(
          access: employeeAccess(),
          branchId: 'br-01',
        ),
        throwsA(isA<AccessDeniedException>()),
      );
    });

    test('pairing codes differ between requests', () async {
      final a = await repo.createKioskPairingToken(
        access: orgAdminAccess(),
        branchId: 'br-01',
      );
      final b = await repo.createKioskPairingToken(
        access: orgAdminAccess(),
        branchId: 'br-01',
      );
      expect(a.value, isNot(b.value));
    });
  });
}
