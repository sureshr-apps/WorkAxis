import 'package:workaxis/core/backend/data_gateway.dart';
import 'package:workaxis/core/backend/json_reader.dart';

/// Aggregate counts for one organization (from `GetOrganizationDashboardCounts`).
class OrganizationCounts {
  const OrganizationCounts({
    required this.branchesByStatus,
    required this.activeEmployees,
    required this.scheduledEmployees,
    required this.returnsByStatus,
  });

  /// Branch count per lower-cased status (`active`, `maintenance`, ...).
  final Map<String, int> branchesByStatus;

  /// Members with role `employee` and status `active`.
  final int activeEmployees;

  /// Active employees scheduled to work on the current Asia/Kolkata date.
  final int scheduledEmployees;

  /// Return count per lower-cased status (`pending`, `approved`, ...).
  final Map<String, int> returnsByStatus;

  int get totalBranches => branchesByStatus.values.fold(0, (a, b) => a + b);
  int branches(String status) => branchesByStatus[status] ?? 0;
  int returns(String status) => returnsByStatus[status] ?? 0;
}

/// Thin seam over the data gateway so the repository can be tested with a fake.
abstract interface class OrganizationDashboardRemote {
  Future<OrganizationCounts> loadCounts(String organizationId);
}

/// [OrganizationDashboardRemote] backed by the data gateway
/// (`GetOrganizationDashboardCounts`).
class DataConnectOrganizationDashboardRemote
    implements OrganizationDashboardRemote {
  DataConnectOrganizationDashboardRemote({required this._gateway});

  final DataGateway _gateway;

  @override
  Future<OrganizationCounts> loadCounts(String organizationId) async {
    final data = await _gateway.call('GetOrganizationDashboardCounts', {
      'orgId': organizationId,
    });
    final activeEmployees = sumCounts([
      for (final m in data.objects('membersByRole'))
        if (m.string('role').toLowerCase() == 'employee' &&
            m.string('status').toLowerCase() == 'active')
          m,
    ]);
    return OrganizationCounts(
      branchesByStatus: groupedCounts(
        data.objects('branchesByStatus'),
        'status',
        lowerCaseKeys: true,
      ),
      activeEmployees: activeEmployees,
      scheduledEmployees: sumCounts(data.objects('scheduledEmployeeCount')),
      returnsByStatus: groupedCounts(
        data.objects('returnsByStatus'),
        'status',
        lowerCaseKeys: true,
      ),
    );
  }
}
