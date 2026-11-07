import 'package:workaxis/features/access/domain/models/branch_summary.dart';
import 'package:workaxis/features/branch_dashboard/domain/models/branch_dashboard_summary.dart';
import 'package:workaxis/features/organization_dashboard/domain/models/attendance_summary.dart';
import 'package:workaxis/features/organization_dashboard/domain/models/attention_item.dart';

/// In-memory mock data source for branch-scoped dashboard metrics.
///
/// Identity (id, name, code) always comes from the branch the caller is
/// authorized for; only the metrics are canned.
class MockBranchDashboardDataSource {
  BranchDashboardSummary getBranchSummary(BranchSummary branch) {
    final attendance = switch (branch.id) {
      'br-02' => const AttendanceSummary(
        present: 12,
        late: 2,
        absent: 1,
        onLeave: 0,
        totalScheduled: 15,
      ),
      'br-04' => const AttendanceSummary(
        present: 17,
        late: 1,
        absent: 1,
        onLeave: 0,
        totalScheduled: 19,
      ),
      _ => const AttendanceSummary(
        present: 26,
        late: 2,
        absent: 2,
        onLeave: 1,
        totalScheduled: 30,
      ),
    };

    return BranchDashboardSummary(
      branchId: branch.id,
      branchName: branch.name,
      branchCode: branch.code,
      attendance: attendance,
      pendingReturns: 3,
      totalEmployees: attendance.totalScheduled,
      attentionItems: [
        AttentionItem(
          id: 'att-${branch.id}-geofence',
          kind: AttentionKind.geofenceException,
          severity: AttentionSeverity.urgent,
          title: 'Unverified Check-in Outside Geofence',
          subtitle: branch.name,
          details: 'Check-in recorded outside the designated branch perimeter.',
          statusLabel: 'Review',
          timestamp: '08:12 AM',
        ),
        AttentionItem(
          id: 'att-${branch.id}-returns',
          kind: AttentionKind.pendingReturns,
          severity: AttentionSeverity.pending,
          title: 'Return Awaiting Review',
          subtitle: branch.name,
          details: 'A submitted return is waiting for a decision.',
          statusLabel: 'Pending',
          timestamp: '09:30 AM',
        ),
      ],
    );
  }
}
