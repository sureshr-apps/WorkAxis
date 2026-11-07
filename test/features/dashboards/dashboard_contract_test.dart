import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workaxis/core/errors/app_exceptions.dart';
import 'package:workaxis/features/attendance/data/attendance_day_counter.dart';
import 'package:workaxis/features/branch_dashboard/data/branch_dashboard_remote.dart';
import 'package:workaxis/features/branch_dashboard/data/mock_branch_dashboard_repository.dart';
import 'package:workaxis/features/branch_dashboard/data/sql_connect_branch_dashboard_repository.dart';
import 'package:workaxis/features/branch_dashboard/domain/repositories/branch_dashboard_repository.dart';
import 'package:workaxis/features/organization_dashboard/data/mock_organization_dashboard_repository.dart';
import 'package:workaxis/features/organization_dashboard/data/organization_dashboard_remote.dart';
import 'package:workaxis/features/organization_dashboard/data/sql_connect_organization_dashboard_repository.dart';
import 'package:workaxis/features/organization_dashboard/domain/repositories/organization_dashboard_repository.dart';

import '../../helpers/access_fixtures.dart';
import '../../helpers/fixed_clock.dart';

class _OrgRemote implements OrganizationDashboardRemote {
  @override
  Future<OrganizationCounts> loadCounts(String organizationId) async =>
      const OrganizationCounts(
        branchesByStatus: {'active': 3},
        activeEmployees: 12,
        returnsByStatus: {'pending': 1},
      );
}

class _BranchRemote implements BranchDashboardRemote {
  @override
  Future<BranchCounts> loadCounts(String branchId) async =>
      const BranchCounts(memberCount: 8, returnsByStatus: {'pending': 1});
}

void _orgContract(
  String name,
  OrganizationDashboardRepository Function() create,
) {
  group('OrganizationDashboardRepository contract: $name', () {
    late OrganizationDashboardRepository repo;
    setUp(() => repo = create());

    test('an org admin gets a summary', () async {
      final summary = await repo.getOrganizationDashboardSummary(
        access: orgAdminAccess(),
      );
      expect(summary.totalBranches, greaterThan(0));
    });

    test('every other role is denied', () async {
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
    });
  });
}

void _branchContract(String name, BranchDashboardRepository Function() create) {
  group('BranchDashboardRepository contract: $name', () {
    late BranchDashboardRepository repo;
    setUp(() => repo = create());

    test('a manager gets the active assigned branch', () async {
      final summary = await repo.getBranchDashboardSummary(
        access: branchManagerAccess(),
        branchId: 'br-02',
      );
      expect(summary.branchId, 'br-02');
      expect(summary.branchName, 'Westside Hub');
    });

    test(
      'an unassigned branch is NotFound, not a fallback to another',
      () async {
        await expectLater(
          repo.getBranchDashboardSummary(
            access: branchManagerAccess(branchIds: ['br-01']),
            branchId: 'br-02',
          ),
          throwsA(isA<NotFoundException>()),
        );
      },
    );

    test('employees are denied', () async {
      await expectLater(
        repo.getBranchDashboardSummary(
          access: employeeAccess(),
          branchId: 'br-01',
        ),
        throwsA(isA<AccessDeniedException>()),
      );
    });

    test('an org admin may view a branch of their organization', () async {
      final summary = await repo.getBranchDashboardSummary(
        access: orgAdminAccess(),
        branchId: 'br-04',
      );
      expect(summary.branchId, 'br-04');
    });
  });
}

void main() {
  AttendanceDayCounter counter() =>
      AttendanceDayCounter(firestore: FakeFirebaseFirestore(), now: fixedNow);

  _orgContract(
    'mock',
    () => MockOrganizationDashboardRepository(delay: Duration.zero),
  );
  _orgContract(
    'SQL Connect (fake)',
    () => SqlConnectOrganizationDashboardRepository(
      remote: _OrgRemote(),
      attendanceCounter: counter(),
    ),
  );

  _branchContract(
    'mock',
    () => MockBranchDashboardRepository(delay: Duration.zero),
  );
  _branchContract(
    'SQL Connect (fake)',
    () => SqlConnectBranchDashboardRepository(
      remote: _BranchRemote(),
      attendanceCounter: counter(),
    ),
  );
}
