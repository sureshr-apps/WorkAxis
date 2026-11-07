import 'package:workaxis/core/errors/app_exceptions.dart';
import 'package:workaxis/core/errors/backend_error_mapper.dart';
import 'package:workaxis/dataconnect_generated/workaxis_connector.dart';
import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/attendance/data/attendance_day_counter.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';
import 'package:workaxis/features/organization_dashboard/data/organization_dashboard_remote.dart';
import 'package:workaxis/features/organization_dashboard/domain/models/attendance_summary.dart';
import 'package:workaxis/features/organization_dashboard/domain/models/attention_item.dart';
import 'package:workaxis/features/organization_dashboard/domain/models/organization_dashboard_summary.dart';
import 'package:workaxis/features/organization_dashboard/domain/repositories/organization_dashboard_repository.dart';

/// Production [OrganizationDashboardRepository].
///
/// Counts come from SQL Connect aggregate queries
/// (`GetOrganizationDashboardCounts`); today's attendance comes from Firestore
/// count queries scoped to the organization. Nothing is estimated: figures the
/// backend cannot provide (leave, per-branch headcount) are left out.
class SqlConnectOrganizationDashboardRepository
    implements OrganizationDashboardRepository {
  SqlConnectOrganizationDashboardRepository({
    WorkaxisConnectorConnector? connector,
    OrganizationDashboardRemote? remote,
    AttendanceDayCounter? attendanceCounter,
  }) : _remote =
           remote ??
           DataConnectOrganizationDashboardRemote(connector: connector),
       _attendance = attendanceCounter ?? AttendanceDayCounter();

  final OrganizationDashboardRemote _remote;
  final AttendanceDayCounter _attendance;

  @override
  Future<OrganizationDashboardSummary> getOrganizationDashboardSummary({
    required UserAccessContext access,
  }) async {
    try {
      final orgId = _requireOrgAdminScope(access);
      final results = await Future.wait<Object>([
        _remote.loadCounts(orgId),
        _attendance.forOrganization(orgId),
      ]);
      final counts = results[0] as OrganizationCounts;
      final checkIns = results[1] as DailyCheckInCounts;

      return OrganizationDashboardSummary(
        attendance: AttendanceSummary.fromCheckIns(
          checkedIn: checkIns.checkedIn,
          late: checkIns.late,
          expectedHeadcount: counts.activeEmployees,
        ),
        pendingReturns: counts.returns('pending'),
        totalEmployees: counts.activeEmployees,
        totalBranches: counts.totalBranches,
        activeBranches: counts.branches('active'),
        maintenanceBranches: counts.branches('maintenance'),
        attentionItems: _attentionItems(counts, checkIns),
      );
    } catch (e, st) {
      throw mapBackendError(e, st);
    }
  }

  String _requireOrgAdminScope(UserAccessContext access) {
    final orgId = access.organization?.id;
    if (access.user.role != UserRole.orgAdmin ||
        orgId == null ||
        orgId.isEmpty) {
      throw const AccessDeniedException(
        'Organization dashboard requires an Organization Admin session.',
      );
    }
    return orgId;
  }

  List<AttentionItem> _attentionItems(
    OrganizationCounts counts,
    DailyCheckInCounts checkIns,
  ) {
    final pending = counts.returns('pending');
    final offline = counts.totalBranches - counts.branches('active');
    return [
      if (pending > 0)
        AttentionItem(
          id: 'pending-returns',
          kind: AttentionKind.pendingReturns,
          severity: AttentionSeverity.pending,
          title: 'Return requests awaiting review',
          subtitle: 'Across the organization',
          details: '$pending return request(s) are waiting for a decision.',
          statusLabel: '$pending Pending',
          timestamp: 'Now',
          actionLabel: 'Review Returns',
        ),
      if (checkIns.late > 0)
        AttentionItem(
          id: 'late-arrivals',
          kind: AttentionKind.lateArrivals,
          severity: AttentionSeverity.urgent,
          title: 'Late arrivals today',
          subtitle: 'Across the organization',
          details: '${checkIns.late} employee(s) checked in late today.',
          statusLabel: '${checkIns.late} Late',
          timestamp: 'Today',
        ),
      if (offline > 0)
        AttentionItem(
          id: 'branches-not-active',
          kind: AttentionKind.branchOffline,
          severity: AttentionSeverity.neutral,
          title: 'Branches not active',
          subtitle: 'Maintenance or inactive',
          details: '$offline branch(es) are not currently active.',
          statusLabel: '$offline Inactive',
          timestamp: 'Now',
        ),
    ];
  }
}
