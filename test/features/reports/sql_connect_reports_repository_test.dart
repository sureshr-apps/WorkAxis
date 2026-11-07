import 'package:flutter_test/flutter_test.dart';
import 'package:workaxis/features/access/domain/models/branch_summary.dart';
import 'package:workaxis/features/access/domain/models/organization_summary.dart';
import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/authentication/domain/models/account_status.dart';
import 'package:workaxis/features/authentication/domain/models/app_user.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';
import 'package:workaxis/features/reports/data/sql_connect_reports_repository.dart';

void main() {
  group('SqlConnectReportsRepository Tests', () {
    late SqlConnectReportsRepository repository;

    setUp(() {
      repository = SqlConnectReportsRepository();
    });

    test('getReportSummary provides complete metrics and daily trends fallback', () async {
      const access = UserAccessContext(
        user: AppUser(
          id: 'admin-1',
          name: 'David Warner',
          username: 'david.warner',
          role: UserRole.orgAdmin,
          status: AccountStatus.active,
        ),
        organization: OrganizationSummary(
          id: 'org-acme',
          name: 'Acme Corporation',
          code: 'ORG-ACM-01',
        ),
        assignedBranches: [
          BranchSummary(
            id: 'br-acme-01',
            organizationId: 'org-acme',
            name: 'Downtown Flagship',
            code: 'ACM-DT-01',
            location: 'Sector 8',
          ),
        ],
        activeBranch: null,
        permissions: {},
      );

      final summary = await repository.getReportSummary(access: access);
      expect(summary.period, equals('This Week'));
      expect(summary.attendanceRate, greaterThan(90));
      expect(summary.dailyTrends, hasLength(7));
      expect(summary.returnCategories, isNotEmpty);
    });
  });
}
