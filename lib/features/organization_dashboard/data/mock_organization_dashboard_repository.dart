import 'package:workaxis/features/organization_dashboard/data/mock_organization_dashboard_data_source.dart';
import 'package:workaxis/features/organization_dashboard/domain/models/attendance_summary.dart';
import 'package:workaxis/features/organization_dashboard/domain/models/attention_item.dart';
import 'package:workaxis/features/organization_dashboard/domain/models/organization_dashboard_summary.dart';
import 'package:workaxis/features/organization_dashboard/domain/repositories/organization_dashboard_repository.dart';

/// Mock repository implementation for Organization Admin Overview.
class MockOrganizationDashboardRepository
    implements OrganizationDashboardRepository {
  final MockOrganizationDashboardDataSource dataSource;
  final Duration delay;

  MockOrganizationDashboardRepository({
    MockOrganizationDashboardDataSource? dataSource,
    this.delay = const Duration(milliseconds: 300),
  }) : dataSource = dataSource ?? MockOrganizationDashboardDataSource();

  @override
  Future<OrganizationDashboardSummary> getOrganizationDashboardSummary() async {
    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }
    return dataSource.getDashboardSummary();
  }

  @override
  Future<AttendanceSummary> getOrganizationAttendanceSummary() async {
    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }
    return dataSource.getAttendanceSummary();
  }

  @override
  Future<List<AttentionItem>> getOrganizationAttentionItems() async {
    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }
    return dataSource.getAttentionItems();
  }
}
