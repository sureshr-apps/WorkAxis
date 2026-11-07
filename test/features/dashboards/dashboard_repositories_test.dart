import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workaxis/core/errors/app_exceptions.dart';
import 'package:workaxis/features/attendance/data/attendance_day_counter.dart';
import 'package:workaxis/features/branch_dashboard/data/branch_dashboard_remote.dart';
import 'package:workaxis/features/branch_dashboard/data/sql_connect_branch_dashboard_repository.dart';
import 'package:workaxis/features/organization_dashboard/data/organization_dashboard_remote.dart';
import 'package:workaxis/features/organization_dashboard/data/sql_connect_organization_dashboard_repository.dart';
import 'package:workaxis/features/organization_dashboard/domain/models/attendance_summary.dart';
import 'package:workaxis/features/organization_dashboard/domain/models/attention_item.dart';
import 'package:workaxis/features/platform_dashboard/data/platform_dashboard_remote.dart';
import 'package:workaxis/features/platform_dashboard/data/sql_connect_platform_dashboard_repository.dart';
import 'package:workaxis/features/platform_dashboard/domain/models/recent_organization_summary.dart';

import '../../helpers/access_fixtures.dart';
import '../../helpers/fixed_clock.dart';

class _FakeOrgRemote implements OrganizationDashboardRemote {
  _FakeOrgRemote(this.counts);
  OrganizationCounts counts;
  Object? failWith;
  final List<String> requestedOrgs = [];

  @override
  Future<OrganizationCounts> loadCounts(String organizationId) async {
    requestedOrgs.add(organizationId);
    if (failWith != null) throw failWith!;
    return counts;
  }
}

class _FakeBranchRemote implements BranchDashboardRemote {
  _FakeBranchRemote(this.counts);
  BranchCounts counts;
  final List<String> requestedBranches = [];

  @override
  Future<BranchCounts> loadCounts(String branchId) async {
    requestedBranches.add(branchId);
    return counts;
  }
}

class _FakePlatformRemote implements PlatformDashboardRemote {
  PlatformStats stats = const PlatformStats(
    organizationsByStatus: {'active': 5, 'suspended': 2},
    platformAdminCount: 4,
  );
  List<RecentOrganizationSummary> recent = [];
  Object? failWith;
  int? lastLimit;

  @override
  Future<PlatformStats> loadStats() async {
    if (failWith != null) throw failWith!;
    return stats;
  }

  @override
  Future<List<RecentOrganizationSummary>> loadRecentOrganizations({
    required int limit,
  }) async {
    lastLimit = limit;
    if (failWith != null) throw failWith!;
    return recent;
  }
}

Future<void> _entry(
  FakeFirebaseFirestore db, {
  required String id,
  required String org,
  required String branch,
  required String status,
  String day = '2026-11-07',
}) => db.collection('attendance_entries').doc(id).set({
  'organizationId': org,
  'branchId': branch,
  'employeeId': 'emp-$id',
  'workDateString': day,
  'status': status,
});

void main() {
  late FakeFirebaseFirestore db;
  late AttendanceDayCounter counter;

  setUp(() async {
    db = FakeFirebaseFirestore();
    counter = AttendanceDayCounter(firestore: db, now: fixedNow);
    // Acme, today: 2 on time + 1 late (two in br-01, one in br-02).
    await _entry(
      db,
      id: 'a',
      org: 'org-acme',
      branch: 'br-01',
      status: 'present',
    );
    await _entry(db, id: 'b', org: 'org-acme', branch: 'br-01', status: 'late');
    await _entry(
      db,
      id: 'c',
      org: 'org-acme',
      branch: 'br-02',
      status: 'present',
    );
    // Noise that must never be counted.
    await _entry(
      db,
      id: 'd',
      org: 'org-other',
      branch: 'br-01',
      status: 'present',
    );
    await _entry(
      db,
      id: 'e',
      org: 'org-acme',
      branch: 'br-01',
      status: 'present',
      day: '2026-11-06',
    );
  });

  group('AttendanceDayCounter', () {
    test('counts the organization for the business day only', () async {
      final counts = await counter.forOrganization('org-acme');
      expect(counts.checkedIn, 3);
      expect(counts.late, 1);
    });

    test('counts a single branch of the organization', () async {
      final counts = await counter.forBranch(
        organizationId: 'org-acme',
        branchId: 'br-01',
      );
      expect(counts.checkedIn, 2);
      expect(counts.late, 1);
    });

    test('uses the business day even when the device date differs', () async {
      // 2026-11-06 20:00 UTC is already 2026-11-07 in Asia/Kolkata.
      final lateEvening = AttendanceDayCounter(
        firestore: db,
        now: () => DateTime.utc(2026, 11, 6, 20),
      );
      expect((await lateEvening.forOrganization('org-acme')).checkedIn, 3);
    });
  });

  group('AttendanceSummary.fromCheckIns', () {
    test(
      'derives absent from the expected headcount; leave is not tracked',
      () {
        final s = AttendanceSummary.fromCheckIns(
          checkedIn: 3,
          late: 1,
          expectedHeadcount: 10,
        );
        expect(s.present, 2);
        expect(s.late, 1);
        expect(s.absent, 7);
        expect(s.onLeave, isNull);
        expect(s.totalScheduled, 10);
      },
    );

    test(
      'never reports negative absences when more checked in than expected',
      () {
        final s = AttendanceSummary.fromCheckIns(
          checkedIn: 5,
          late: 0,
          expectedHeadcount: 2,
        );
        expect(s.absent, 0);
        expect(s.totalScheduled, 5);
      },
    );
  });

  group('SqlConnectOrganizationDashboardRepository', () {
    late _FakeOrgRemote remote;
    late SqlConnectOrganizationDashboardRepository repo;

    setUp(() {
      remote = _FakeOrgRemote(
        const OrganizationCounts(
          branchesByStatus: {'active': 2, 'maintenance': 1},
          activeEmployees: 10,
          returnsByStatus: {'pending': 4, 'approved': 9},
        ),
      );
      repo = SqlConnectOrganizationDashboardRepository(
        remote: remote,
        attendanceCounter: counter,
      );
    });

    test(
      'maps aggregates and today\'s attendance, scoped to the admin\'s org',
      () async {
        final summary = await repo.getOrganizationDashboardSummary(
          access: orgAdminAccess(),
        );

        expect(remote.requestedOrgs, ['org-acme']);
        expect(summary.totalBranches, 3);
        expect(summary.activeBranches, 2);
        expect(summary.maintenanceBranches, 1);
        expect(summary.totalEmployees, 10);
        expect(summary.pendingReturns, 4);
        expect(summary.attendance.present, 2);
        expect(summary.attendance.late, 1);
        expect(summary.attendance.absent, 7);
        expect(summary.attendance.totalScheduled, 10);
        expect(summary.branchSnapshots, isEmpty);
      },
    );

    test('attention items are derived from real counts', () async {
      final summary = await repo.getOrganizationDashboardSummary(
        access: orgAdminAccess(),
      );
      final kinds = summary.attentionItems.map((i) => i.kind).toList();
      expect(kinds, [
        AttentionKind.pendingReturns,
        AttentionKind.lateArrivals,
        AttentionKind.branchOffline,
      ]);
      expect(summary.attentionItems.first.statusLabel, '4 Pending');
    });

    test(
      'nothing to flag means no attention items (no placeholders)',
      () async {
        remote.counts = const OrganizationCounts(
          branchesByStatus: {'active': 1},
          activeEmployees: 0,
          returnsByStatus: {},
        );
        final summary = await repo.getOrganizationDashboardSummary(
          access: orgAdminAccess(org: otherOrg, branchIds: const []),
        );
        expect(summary.attentionItems, isEmpty);
        // Counts the other org's own entry (1), proving Acme's are not used.
        expect(summary.attendance.present, 1);
        expect(summary.attendance.late, 0);
      },
    );

    test('an admin of another org gets that org, never Acme', () async {
      await repo.getOrganizationDashboardSummary(
        access: orgAdminAccess(org: otherOrg, branchIds: const []),
      );
      expect(remote.requestedOrgs, ['org-other']);
    });

    test('only Organization Admins may load it', () async {
      for (final access in [
        branchManagerAccess(),
        employeeAccess(),
        platformAccess(),
      ]) {
        await expectLater(
          repo.getOrganizationDashboardSummary(access: access),
          throwsA(isA<AccessDeniedException>()),
        );
      }
      expect(remote.requestedOrgs, isEmpty);
    });

    test('backend failures are typed and never replaced by numbers', () async {
      remote.failWith = StateError('secret connection string');
      await expectLater(
        repo.getOrganizationDashboardSummary(access: orgAdminAccess()),
        throwsA(
          isA<DatabaseException>().having(
            (e) => e.userMessage,
            'userMessage',
            isNot(contains('secret')),
          ),
        ),
      );
    });
  });

  group('SqlConnectBranchDashboardRepository', () {
    late _FakeBranchRemote remote;
    late SqlConnectBranchDashboardRepository repo;

    setUp(() {
      remote = _FakeBranchRemote(
        const BranchCounts(memberCount: 6, returnsByStatus: {'pending': 2}),
      );
      repo = SqlConnectBranchDashboardRepository(
        remote: remote,
        attendanceCounter: counter,
      );
    });

    test('maps stats for the authorized branch', () async {
      final summary = await repo.getBranchDashboardSummary(
        access: branchManagerAccess(),
        branchId: 'br-01',
      );

      expect(remote.requestedBranches, ['br-01']);
      expect(summary.branchId, 'br-01');
      expect(summary.branchName, 'Downtown Flagship');
      expect(summary.totalEmployees, 6);
      expect(summary.pendingReturns, 2);
      // Only br-01 entries: 2 checked in, 1 late.
      expect(summary.attendance.present, 1);
      expect(summary.attendance.late, 1);
      expect(summary.attendance.absent, 4);
      expect(summary.attentionItems.map((i) => i.kind), [
        AttentionKind.pendingReturns,
        AttentionKind.lateArrivals,
      ]);
    });

    test('an unassigned branch is NotFound, never another branch', () async {
      await expectLater(
        repo.getBranchDashboardSummary(
          access: branchManagerAccess(branchIds: ['br-01']),
          branchId: 'br-02',
        ),
        throwsA(isA<NotFoundException>()),
      );
      expect(remote.requestedBranches, isEmpty);
    });

    test('employees and platform users are denied', () async {
      for (final access in [employeeAccess(), platformAccess()]) {
        await expectLater(
          repo.getBranchDashboardSummary(access: access, branchId: 'br-01'),
          throwsA(isA<AccessDeniedException>()),
        );
      }
    });

    test('org admins may view a branch of their organization', () async {
      final summary = await repo.getBranchDashboardSummary(
        access: orgAdminAccess(),
        branchId: 'br-02',
      );
      expect(summary.branchId, 'br-02');
      expect(summary.attendance.present, 1);
    });
  });

  group('SqlConnectPlatformDashboardRepository', () {
    late _FakePlatformRemote remote;
    late SqlConnectPlatformDashboardRepository repo;

    setUp(() {
      remote = _FakePlatformRemote();
      repo = SqlConnectPlatformDashboardRepository(remote: remote);
    });

    test(
      'summarizes GetPlatformStats without a second organization list',
      () async {
        final summary = await repo.getPlatformDashboardSummary();
        expect(summary.totalOrganizations, 7);
        expect(summary.activeOrganizations, 5);
        expect(summary.suspendedOrganizations, 2);
        expect(summary.platformAdminsCount, 4);
      },
    );

    test(
      'recent organizations keep real data and no invented admin email',
      () async {
        remote.recent = [
          RecentOrganizationSummary(
            id: 'o1',
            name: 'Org One',
            code: 'ONE',
            status: 'active',
            branchCount: 3,
            employeeCount: 12,
            createdAt: testNow,
          ),
        ];
        final recent = await repo.getRecentOrganizations();
        expect(recent.single.adminEmail, isNull);
        expect(recent.single.branchCount, 3);
        expect(remote.lastLimit, repo.recentLimit);
      },
    );

    test('failures are typed, with no fallback admin count', () async {
      remote.failWith = const NetworkException();
      await expectLater(
        repo.getPlatformDashboardSummary(),
        throwsA(isA<NetworkException>()),
      );
      await expectLater(
        repo.getRecentOrganizations(),
        throwsA(isA<NetworkException>()),
      );
    });
  });
}
