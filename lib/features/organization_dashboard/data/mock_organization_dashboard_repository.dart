import 'package:workaxis/core/errors/app_exceptions.dart';
import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';
import 'package:workaxis/features/organization_dashboard/data/mock_organization_dashboard_data_source.dart';
import 'package:workaxis/features/organization_dashboard/domain/models/organization_dashboard_summary.dart';
import 'package:workaxis/features/organization_dashboard/domain/repositories/organization_dashboard_repository.dart';

/// Mock repository implementation for Organization Admin Overview.
///
/// Mirrors the real repository's scoping: Organization Admins with an
/// organization only.
class MockOrganizationDashboardRepository
    implements OrganizationDashboardRepository {
  final MockOrganizationDashboardDataSource dataSource;
  final Duration delay;

  MockOrganizationDashboardRepository({
    MockOrganizationDashboardDataSource? dataSource,
    this.delay = const Duration(milliseconds: 300),
  }) : dataSource = dataSource ?? MockOrganizationDashboardDataSource();

  @override
  Future<OrganizationDashboardSummary> getOrganizationDashboardSummary({
    required UserAccessContext access,
  }) async {
    if (access.user.role != UserRole.orgAdmin || access.organization == null) {
      throw const AccessDeniedException(
        'Organization dashboard requires an Organization Admin session.',
      );
    }
    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }
    return dataSource.getDashboardSummary();
  }
}
