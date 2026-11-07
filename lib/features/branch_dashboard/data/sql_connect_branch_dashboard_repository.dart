import 'package:workaxis/core/errors/app_exceptions.dart';
import 'package:workaxis/core/errors/backend_error_mapper.dart';
import 'package:workaxis/dataconnect_generated/workaxis_connector.dart';
import 'package:workaxis/features/access/domain/models/branch_summary.dart';
import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/attendance/data/attendance_day_counter.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';
import 'package:workaxis/features/branch_dashboard/data/branch_dashboard_remote.dart';
import 'package:workaxis/features/branch_dashboard/domain/models/branch_dashboard_summary.dart';
import 'package:workaxis/features/branch_dashboard/domain/repositories/branch_dashboard_repository.dart';
import 'package:workaxis/features/organization_dashboard/domain/models/attendance_summary.dart';
import 'package:workaxis/features/organization_dashboard/domain/models/attention_item.dart';

/// Production [BranchDashboardRepository].
///
/// Branch identity comes from the authorized branch in [UserAccessContext]
/// (never another branch), counts from `GetBranchStats`, and today's
/// attendance from Firestore count queries scoped to organization + branch.
class SqlConnectBranchDashboardRepository implements BranchDashboardRepository {
  SqlConnectBranchDashboardRepository({
    WorkaxisConnectorConnector? connector,
    BranchDashboardRemote? remote,
    AttendanceDayCounter? attendanceCounter,
  }) : _remote =
           remote ?? DataConnectBranchDashboardRemote(connector: connector),
       _attendance = attendanceCounter ?? AttendanceDayCounter();

  final BranchDashboardRemote _remote;
  final AttendanceDayCounter _attendance;

  @override
  Future<BranchDashboardSummary> getBranchDashboardSummary({
    required UserAccessContext access,
    required String branchId,
  }) async {
    try {
      final role = access.user.role;
      final orgId = access.organization?.id;
      if ((role != UserRole.branchManager && role != UserRole.orgAdmin) ||
          orgId == null ||
          orgId.isEmpty) {
        throw const AccessDeniedException(
          'Branch dashboard requires a Branch Manager or Organization Admin.',
        );
      }
      final BranchSummary? branch = access.assignedBranches
          .where((b) => b.id == branchId)
          .firstOrNull;
      if (branch == null) {
        throw const NotFoundException('Branch not found.');
      }

      final results = await Future.wait<Object>([
        _remote.loadCounts(branch.id),
        _attendance.forBranch(organizationId: orgId, branchId: branch.id),
      ]);
      final counts = results[0] as BranchCounts;
      final checkIns = results[1] as DailyCheckInCounts;
      final pending = counts.returns('pending');

      return BranchDashboardSummary(
        branchId: branch.id,
        branchName: branch.name,
        branchCode: branch.code,
        attendance: AttendanceSummary.fromCheckIns(
          checkedIn: checkIns.checkedIn,
          late: checkIns.late,
          expectedHeadcount: counts.memberCount,
        ),
        pendingReturns: pending,
        totalEmployees: counts.memberCount,
        attentionItems: [
          if (pending > 0)
            AttentionItem(
              id: 'pending-returns-${branch.id}',
              kind: AttentionKind.pendingReturns,
              severity: AttentionSeverity.pending,
              title: 'Return requests awaiting review',
              subtitle: branch.name,
              details: '$pending return request(s) are waiting for a decision.',
              statusLabel: '$pending Pending',
              timestamp: 'Now',
              actionLabel: 'Review Returns',
            ),
          if (checkIns.late > 0)
            AttentionItem(
              id: 'late-arrivals-${branch.id}',
              kind: AttentionKind.lateArrivals,
              severity: AttentionSeverity.urgent,
              title: 'Late arrivals today',
              subtitle: branch.name,
              details: '${checkIns.late} employee(s) checked in late today.',
              statusLabel: '${checkIns.late} Late',
              timestamp: 'Today',
            ),
        ],
      );
    } catch (e, st) {
      throw mapBackendError(e, st);
    }
  }
}
