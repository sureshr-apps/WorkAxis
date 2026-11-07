import 'package:workaxis/features/organization_dashboard/domain/models/attendance_summary.dart';
import 'package:workaxis/features/organization_dashboard/domain/models/attention_item.dart';
import 'package:workaxis/features/organization_dashboard/domain/models/organization_dashboard_summary.dart';

/// In-memory mock data source for Organization Admin Overview.
/// Grounded strictly in the approved Stitch specification.
class MockOrganizationDashboardDataSource {
  AttendanceSummary getAttendanceSummary() {
    return const AttendanceSummary(
      present: 389,
      late: 15,
      absent: 24,
      onLeave: 15,
      totalScheduled: 428,
    );
  }

  List<AttentionItem> getAttentionItems() {
    return const [
      AttentionItem(
        id: 'att-1',
        kind: AttentionKind.pendingReturns,
        severity: AttentionSeverity.pending,
        title: 'Return Requests Pending Sign-off',
        subtitle: 'Central Depot & South Bay',
        details: 'High-value freight returns waiting for manager sign-off from Central Depot & South Bay.',
        statusLabel: '7 Items',
        timestamp: '3 hrs ago',
        badgeText: '7 Items',
        actionLabel: 'Review Returns',
      ),
      AttentionItem(
        id: 'att-2',
        kind: AttentionKind.missingCheckOut,
        severity: AttentionSeverity.urgent,
        title: 'Missing Check-Out Records',
        subtitle: "Yesterday's night shift",
        details: "Staff from yesterday's night shift finished shift without punch-out terminal verification.",
        statusLabel: '4 Staff',
        timestamp: '4 hrs ago',
        badgeText: '4 Staff',
        actionLabel: 'Resolve Pings',
      ),
      AttentionItem(
        id: 'att-3',
        kind: AttentionKind.branchOffline,
        severity: AttentionSeverity.neutral,
        title: 'North Gate Unit Offline',
        subtitle: 'Scheduled dock maintenance',
        details: 'Distribution hub marked Offline for scheduled dock maintenance. Terminal sync paused.',
        statusLabel: 'Inactive',
        timestamp: 'Today',
        badgeText: 'Inactive',
        actionLabel: 'Inspect Unit',
      ),
      AttentionItem(
        id: 'att-4',
        kind: AttentionKind.shiftTransfers,
        severity: AttentionSeverity.info,
        title: 'Unassigned Shift Transfers',
        subtitle: 'East Depot & South Bay',
        details: 'Peer exchange requests between East Depot and South Bay pending org confirmation.',
        statusLabel: '3 Swaps',
        timestamp: 'Ongoing',
        badgeText: '3 Swaps',
        actionLabel: 'Review',
      ),
    ];
  }

  List<BranchAdherenceSnapshot> getBranchSnapshots() {
    return const [
      BranchAdherenceSnapshot(
        code: 'CH',
        name: 'Central Distribution Hub',
        details: '182 of 185 present • Zone 1',
        adherenceRate: 0.984,
        adherencePercentage: '98.4%',
      ),
      BranchAdherenceSnapshot(
        code: 'ED',
        name: 'East River Cargo Depot',
        details: '122 of 134 present • Zone 2',
        adherenceRate: 0.910,
        adherencePercentage: '91.0%',
      ),
      BranchAdherenceSnapshot(
        code: 'SB',
        name: 'South Bay Logistics Yard',
        details: '85 of 109 present • Zone 3',
        adherenceRate: 0.780,
        adherencePercentage: '78.0%',
      ),
    ];
  }

  OrganizationDashboardSummary getDashboardSummary() {
    return OrganizationDashboardSummary(
      attendance: getAttendanceSummary(),
      pendingReturns: 15,
      totalEmployees: 428,
      totalBranches: 14,
      activeBranches: 13,
      maintenanceBranches: 1,
      attentionItems: getAttentionItems(),
      branchSnapshots: getBranchSnapshots(),
    );
  }
}
