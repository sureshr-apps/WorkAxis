import 'package:workaxis/features/organization_dashboard/domain/models/attendance_summary.dart';
import 'package:workaxis/features/organization_dashboard/domain/models/attention_item.dart';
import 'package:workaxis/features/organization_dashboard/domain/models/organization_dashboard_summary.dart';

/// Stable repository contract for Organization Admin Overview.
abstract interface class OrganizationDashboardRepository {
  /// Fetches comprehensive organization dashboard metrics.
  Future<OrganizationDashboardSummary> getOrganizationDashboardSummary();

  /// Fetches attendance breakdown for the organization.
  Future<AttendanceSummary> getOrganizationAttendanceSummary();

  /// Fetches urgent or pending attention items for the organization.
  Future<List<AttentionItem>> getOrganizationAttentionItems();
}
