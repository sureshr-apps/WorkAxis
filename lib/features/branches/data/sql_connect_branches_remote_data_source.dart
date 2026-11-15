import 'package:workaxis/core/backend/data_gateway.dart';
import 'package:workaxis/core/backend/json_reader.dart';
import 'package:workaxis/features/access/domain/models/branch_summary.dart';
import 'package:workaxis/features/branches/data/branches_remote_data_source.dart';
import 'package:workaxis/features/branches/domain/branch_geofence_validator.dart';
import 'package:workaxis/features/branches/domain/models/branch_record.dart';

/// [BranchesRemoteDataSource] backed by the data gateway
/// (`ListBranchesByOrg`, `GetBranchById`).
class SqlConnectBranchesRemoteDataSource implements BranchesRemoteDataSource {
  SqlConnectBranchesRemoteDataSource({required this._gateway});

  final DataGateway _gateway;

  @override
  Future<List<BranchRecord>> listByOrganization(String organizationId) async {
    final data = await _gateway.call('ListBranchesByOrg', {
      'orgId': organizationId,
    });
    return [
      for (final b in data.objects('branches'))
        _record(b, organizationId: organizationId),
    ];
  }

  @override
  Future<BranchRecord?> getById(String id) async {
    final data = await _gateway.call('GetBranchById', {'id': id});
    final b = data.optObject('branch');
    if (b == null) return null;
    return _record(b, organizationId: b.object('organization').string('id'));
  }

  BranchRecord _record(
    Map<String, dynamic> b, {
    required String organizationId,
  }) {
    final radius = b.optInt('geofenceRadiusMeters');
    final latitude = b.optNumber('latitude');
    final longitude = b.optNumber('longitude');
    return BranchRecord(
      summary: BranchSummary(
        id: b.string('id'),
        organizationId: organizationId,
        name: b.string('name'),
        code: b.string('code'),
        location: b.optString('location') ?? '',
        latitude: latitude,
        longitude: longitude,
        geofenceRadiusMeters: radius,
        isActive: b.string('status') == 'active',
      ),
      geofenceRadiusMeters:
          radius ?? BranchGeofenceValidator.defaultRadiusMeters,
      latitude: latitude,
      longitude: longitude,
      isMainBranch: b.boolean('isMainBranch'),
      managerIds: const [],
      kioskStatus: b.optBool('kioskEnabled') == true
          ? KioskPairingStatus.paired
          : KioskPairingStatus.notPaired,
    );
  }
}
