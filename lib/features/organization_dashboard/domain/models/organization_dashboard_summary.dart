import 'package:workaxis/features/organization_dashboard/domain/models/attendance_summary.dart';
import 'package:workaxis/features/organization_dashboard/domain/models/attention_item.dart';

/// Typed quick-glance branch adherence snapshot.
class BranchAdherenceSnapshot {
  final String code;
  final String name;
  final String details;
  final double adherenceRate;
  final String adherencePercentage;

  const BranchAdherenceSnapshot({
    required this.code,
    required this.name,
    required this.details,
    required this.adherenceRate,
    required this.adherencePercentage,
  });
}

/// Typed dashboard metrics for Organization Admin Overview.
class OrganizationDashboardSummary {
  final AttendanceSummary attendance;
  final int pendingReturns;
  final int totalEmployees;
  final int totalBranches;
  final int activeBranches;
  final int maintenanceBranches;
  final List<AttentionItem> attentionItems;
  final List<BranchAdherenceSnapshot> branchSnapshots;

  const OrganizationDashboardSummary({
    required this.attendance,
    required this.pendingReturns,
    required this.totalEmployees,
    required this.totalBranches,
    required this.activeBranches,
    required this.maintenanceBranches,
    required this.attentionItems,
    this.branchSnapshots = const [],
  });

  int get totalStaff => totalEmployees;
}
