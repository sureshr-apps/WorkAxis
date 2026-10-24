import 'package:workaxis/core/widgets/status_chip.dart';
import 'package:workaxis/features/branch_dashboard/domain/models/branch_dashboard_summary.dart';
import 'package:workaxis/features/organization_dashboard/domain/models/attendance_summary.dart';
import 'package:workaxis/features/organization_dashboard/domain/models/attention_item.dart';

/// In-memory mock data source for branch-scoped dashboard metrics.
class MockBranchDashboardDataSource {
  BranchDashboardSummary getBranchSummary(String branchId) {
    switch (branchId) {
      case 'br-01':
        return const BranchDashboardSummary(
          branchId: 'br-01',
          branchName: 'Downtown Flagship',
          branchCode: 'BR-101',
          attendance: AttendanceSummary(
            present: 42,
            late: 2,
            absent: 4,
            onLeave: 2,
            totalScheduled: 48,
          ),
          pendingReturns: 3,
          totalEmployees: 48,
          attentionItems: [
            AttentionItem(
              id: 'att-dt-1',
              title: 'Unverified Check-in Outside Geofence',
              subtitle: 'Downtown Flagship • John Doe (Tech ID #1042)',
              details:
                  'Check-in recorded 150m outside designated branch perimeter.',
              statusType: StatusType.urgent,
              statusLabel: 'Review',
              timestamp: '08:12 AM',
            ),
            AttentionItem(
              id: 'att-dt-2',
              title: 'Return Awaiting Physical Inspection',
              subtitle: 'Downtown Flagship • Tool #TL-881',
              details:
                  'Safety kit returned with cracked outer protective casing.',
              statusType: StatusType.pending,
              statusLabel: 'Inspection',
              timestamp: '09:30 AM',
            ),
          ],
        );

      case 'branch-ws':
        return const BranchDashboardSummary(
          branchId: 'branch-ws',
          branchName: 'Westside Station',
          branchCode: 'WS-02',
          attendance: AttendanceSummary(
            present: 34,
            late: 3,
            absent: 5,
            onLeave: 1,
            totalScheduled: 40,
          ),
          pendingReturns: 2,
          totalEmployees: 40,
          attentionItems: [
            AttentionItem(
              id: 'att-ws-1',
              title: 'Unexplained Absence Spike',
              subtitle: 'Westside Branch • 5 staff unaccounted',
              details: 'Morning shift started at 08:00 AM without check-ins.',
              statusType: StatusType.urgent,
              statusLabel: 'Urgent',
              timestamp: '4 hrs ago',
            ),
          ],
        );

      case 'branch-ss':
        return const BranchDashboardSummary(
          branchId: 'branch-ss',
          branchName: 'South Station',
          branchCode: 'SS-04',
          attendance: AttendanceSummary(
            present: 28,
            late: 1,
            absent: 2,
            onLeave: 1,
            totalScheduled: 31,
          ),
          pendingReturns: 4,
          totalEmployees: 31,
          attentionItems: [
            AttentionItem(
              id: 'att-ss-1',
              title: 'Pending Return Inspection',
              subtitle: 'South Station • Equipment #RT-4091',
              details: 'Diagnostic scanner returned with worn connector.',
              statusType: StatusType.urgent,
              statusLabel: 'Urgent',
              timestamp: '2 hrs ago',
            ),
          ],
        );

      case 'branch-dt':
      default:
        return const BranchDashboardSummary(
          branchId: 'branch-dt',
          branchName: 'Downtown (HQ)',
          branchCode: 'DT-01',
          attendance: AttendanceSummary(
            present: 42,
            late: 2,
            absent: 4,
            onLeave: 2,
            totalScheduled: 48,
          ),
          pendingReturns: 3,
          totalEmployees: 48,
          attentionItems: [
            AttentionItem(
              id: 'att-dt-1',
              title: 'Unverified Check-in Outside Geofence',
              subtitle: 'Downtown HQ • John Doe (Tech ID #1042)',
              details:
                  'Check-in recorded 150m outside designated branch perimeter.',
              statusType: StatusType.urgent,
              statusLabel: 'Review',
              timestamp: '08:12 AM',
            ),
            AttentionItem(
              id: 'att-dt-2',
              title: 'Return Awaiting Physical Inspection',
              subtitle: 'Downtown HQ • Tool #TL-881',
              details:
                  'Safety kit returned with cracked outer protective casing.',
              statusType: StatusType.pending,
              statusLabel: 'Inspection',
              timestamp: '09:30 AM',
            ),
          ],
        );
    }
  }
}
