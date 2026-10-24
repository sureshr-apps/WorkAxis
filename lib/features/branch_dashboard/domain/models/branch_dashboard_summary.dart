import 'package:workaxis/features/organization_dashboard/domain/models/attendance_summary.dart';
import 'package:workaxis/features/organization_dashboard/domain/models/attention_item.dart';

/// Typed dashboard metrics scoped strictly to a single active branch.
class BranchDashboardSummary {
  final String branchId;
  final String branchName;
  final String branchCode;
  final AttendanceSummary attendance;
  final int pendingReturns;
  final int totalEmployees;
  final List<AttentionItem> attentionItems;

  const BranchDashboardSummary({
    required this.branchId,
    required this.branchName,
    required this.branchCode,
    required this.attendance,
    required this.pendingReturns,
    required this.totalEmployees,
    required this.attentionItems,
  });
}
