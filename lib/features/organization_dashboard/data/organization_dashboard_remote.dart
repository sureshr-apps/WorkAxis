import 'package:workaxis/dataconnect_generated/workaxis_connector.dart';

/// Aggregate counts for one organization (from `GetOrganizationDashboardCounts`).
class OrganizationCounts {
  const OrganizationCounts({
    required this.branchesByStatus,
    required this.activeEmployees,
    required this.returnsByStatus,
  });

  /// Branch count per lower-cased status (`active`, `maintenance`, ...).
  final Map<String, int> branchesByStatus;

  /// Members with role `employee` and status `active`.
  final int activeEmployees;

  /// Return count per lower-cased status (`pending`, `approved`, ...).
  final Map<String, int> returnsByStatus;

  int get totalBranches => branchesByStatus.values.fold(0, (a, b) => a + b);
  int branches(String status) => branchesByStatus[status] ?? 0;
  int returns(String status) => returnsByStatus[status] ?? 0;
}

/// Thin seam over SQL Connect so the repository can be tested with a fake.
abstract interface class OrganizationDashboardRemote {
  Future<OrganizationCounts> loadCounts(String organizationId);
}

/// [OrganizationDashboardRemote] backed by the generated connector.
class DataConnectOrganizationDashboardRemote
    implements OrganizationDashboardRemote {
  DataConnectOrganizationDashboardRemote({this._connector});

  final WorkaxisConnectorConnector? _connector;

  WorkaxisConnectorConnector get _c =>
      _connector ?? WorkaxisConnectorConnector.instance;

  @override
  Future<OrganizationCounts> loadCounts(String organizationId) async {
    final data =
        (await _c
                .getOrganizationDashboardCounts(orgId: organizationId)
                .execute())
            .data;

    Map<String, int> byStatus(Iterable<(String, int)> rows) {
      final out = <String, int>{};
      for (final (status, count) in rows) {
        final key = status.toLowerCase();
        out[key] = (out[key] ?? 0) + count;
      }
      return out;
    }

    final activeEmployees = data.membersByRole
        .where(
          (m) =>
              m.role.toLowerCase() == 'employee' &&
              m.status.toLowerCase() == 'active',
        )
        .fold<int>(0, (sum, m) => sum + m.count_);

    return OrganizationCounts(
      branchesByStatus: byStatus(
        data.branchesByStatus.map((b) => (b.status, b.count_)),
      ),
      activeEmployees: activeEmployees,
      returnsByStatus: byStatus(
        data.returnsByStatus.map((r) => (r.status, r.count_)),
      ),
    );
  }
}
