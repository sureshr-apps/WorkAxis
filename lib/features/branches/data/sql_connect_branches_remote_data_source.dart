import 'package:workaxis/dataconnect_generated/workaxis_connector.dart';
import 'package:workaxis/features/access/domain/models/branch_summary.dart';
import 'package:workaxis/features/branches/data/branches_remote_data_source.dart';
import 'package:workaxis/features/branches/domain/branch_geofence_validator.dart';
import 'package:workaxis/features/branches/domain/models/branch_record.dart';

/// [BranchesRemoteDataSource] backed by Firebase SQL Connect.
class SqlConnectBranchesRemoteDataSource implements BranchesRemoteDataSource {
  SqlConnectBranchesRemoteDataSource({WorkaxisConnectorConnector? connector})
    : _customConnector = connector;

  final WorkaxisConnectorConnector? _customConnector;
  WorkaxisConnectorConnector get _connector =>
      _customConnector ?? WorkaxisConnectorConnector.instance;

  @override
  Future<List<BranchRecord>> listByOrganization(String organizationId) async {
    final data =
        (await _connector.listBranchesByOrg(orgId: organizationId).execute())
            .data;
    return [
      for (final b in data.branches)
        _record(
          id: b.id,
          organizationId: organizationId,
          name: b.name,
          code: b.code,
          location: b.location,
          status: b.status,
          isMain: b.isMainBranch,
          radius: b.geofenceRadiusMeters,
          latitude: b.latitude,
          longitude: b.longitude,
          kioskEnabled: b.kioskEnabled,
        ),
    ];
  }

  @override
  Future<BranchRecord?> getById(String id) async {
    final b = (await _connector.getBranchById(id: id).execute()).data.branch;
    if (b == null) return null;
    return _record(
      id: b.id,
      organizationId: b.organization.id,
      name: b.name,
      code: b.code,
      location: b.location,
      status: b.status,
      isMain: b.isMainBranch,
      radius: b.geofenceRadiusMeters,
      latitude: b.latitude,
      longitude: b.longitude,
      kioskEnabled: b.kioskEnabled,
    );
  }

  @override
  Future<String> add(
    BranchRecord branch, {
    required String organizationId,
  }) async {
    final builder = _connector
        .addBranch(
          orgId: organizationId,
          name: branch.name.trim(),
          code: branch.code.trim(),
        )
        .location(branch.location.trim())
        .isMainBranch(branch.isMainBranch)
        .geofenceRadiusMeters(branch.geofenceRadiusMeters);
    // Unset optional variables are omitted, never sent as null.
    if (branch.latitude != null) builder.latitude(branch.latitude);
    if (branch.longitude != null) builder.longitude(branch.longitude);
    final result = await builder.execute();
    return result.data.branch_insert.id;
  }

  @override
  Future<void> update(BranchRecord branch) async {
    final builder = _connector
        .updateBranch(id: branch.id)
        .name(branch.name.trim())
        .code(branch.code.trim())
        .location(branch.location.trim())
        .status(branch.isActive ? 'active' : 'suspended')
        .isMainBranch(branch.isMainBranch)
        .geofenceRadiusMeters(branch.geofenceRadiusMeters);
    if (branch.latitude != null) builder.latitude(branch.latitude);
    if (branch.longitude != null) builder.longitude(branch.longitude);
    await builder.execute();
  }

  BranchRecord _record({
    required String id,
    required String organizationId,
    required String name,
    required String code,
    required String? location,
    required String status,
    required bool isMain,
    required int? radius,
    required double? latitude,
    required double? longitude,
    required bool? kioskEnabled,
  }) {
    return BranchRecord(
      summary: BranchSummary(
        id: id,
        organizationId: organizationId,
        name: name,
        code: code,
        location: location ?? '',
        isActive: status == 'active',
      ),
      geofenceRadiusMeters:
          radius ?? BranchGeofenceValidator.defaultRadiusMeters,
      latitude: latitude,
      longitude: longitude,
      isMainBranch: isMain,
      managerIds: const [],
      kioskStatus: kioskEnabled == true
          ? KioskPairingStatus.paired
          : KioskPairingStatus.notPaired,
    );
  }
}
