import 'package:workaxis/core/errors/app_exceptions.dart';
import 'package:workaxis/features/access/data/mock_access_data_source.dart';
import 'package:workaxis/features/access/domain/models/branch_summary.dart';
import 'package:workaxis/features/branches/data/branches_remote_data_source.dart';
import 'package:workaxis/features/branches/domain/models/branch_record.dart';

/// In-memory [BranchesRemoteDataSource] seeded like the mock repository:
/// the Acme branches br-01..br-04 with their geofence settings. Enforces what
/// the database does: server-assigned ids and unique codes per organization.
class FakeBranchesDataSource implements BranchesRemoteDataSource {
  FakeBranchesDataSource() {
    const settings = {
      'br-01': (125, 40.7128, -74.0060, true),
      'br-02': (180, 40.7359, -74.0036, false),
      'br-03': (250, 40.7580, -73.9855, false),
      'br-04': (150, 40.7306, -73.9352, true),
    };
    final facts = MockAccessDataSource();
    for (final summary in facts.getBranchesForOrganization('org-acme')) {
      final s = settings[summary.id]!;
      _rows[summary.id] = BranchRecord(
        summary: summary,
        geofenceRadiusMeters: s.$1,
        latitude: s.$2,
        longitude: s.$3,
        managerIds: const [],
        kioskStatus: s.$4
            ? KioskPairingStatus.paired
            : KioskPairingStatus.notPaired,
      );
    }
  }

  final Map<String, BranchRecord> _rows = {};
  int _next = 1;
  final List<BranchRecord> added = [];
  final List<BranchRecord> updated = [];

  @override
  Future<List<BranchRecord>> listByOrganization(String organizationId) async =>
      _rows.values.where((b) => b.organizationId == organizationId).toList();

  @override
  Future<BranchRecord?> getById(String id) async => _rows[id];

  @override
  Future<String> add(
    BranchRecord branch, {
    required String organizationId,
  }) async {
    _assertCodeFree(organizationId, branch.code, null);
    final id = 'srv-br-${_next++}';
    final record = BranchRecord(
      summary: _summary(branch, id: id, organizationId: organizationId),
      geofenceRadiusMeters: branch.geofenceRadiusMeters,
      latitude: branch.latitude,
      longitude: branch.longitude,
      isMainBranch: branch.isMainBranch,
      managerIds: const [],
      kioskStatus: KioskPairingStatus.notPaired,
    );
    _rows[id] = record;
    added.add(record);
    return id;
  }

  @override
  Future<void> update(BranchRecord branch) async {
    final existing = _rows[branch.id]!;
    _assertCodeFree(existing.organizationId, branch.code, branch.id);
    final record = BranchRecord(
      summary: _summary(
        branch,
        id: branch.id,
        organizationId: existing.organizationId,
      ),
      geofenceRadiusMeters: branch.geofenceRadiusMeters,
      // Optional values that are omitted keep their stored value.
      latitude: branch.latitude ?? existing.latitude,
      longitude: branch.longitude ?? existing.longitude,
      isMainBranch: branch.isMainBranch,
      managerIds: const [],
      kioskStatus: existing.kioskStatus,
    );
    _rows[branch.id] = record;
    updated.add(record);
  }

  void _assertCodeFree(String orgId, String code, String? exceptId) {
    final clash = _rows.values.any(
      (b) =>
          b.id != exceptId &&
          b.organizationId == orgId &&
          b.code.toLowerCase() == code.trim().toLowerCase(),
    );
    if (clash) {
      throw const DatabaseException(
        'unique violation',
        userMessage: 'That branch code is already in use.',
      );
    }
  }

  BranchSummary _summary(
    BranchRecord branch, {
    required String id,
    required String organizationId,
  }) => branch.summary.copyWith(id: id, organizationId: organizationId);
}
