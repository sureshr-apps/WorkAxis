import 'dart:math';
import 'package:workaxis/core/errors/app_exceptions.dart';
import 'package:workaxis/dataconnect_generated/workaxis_connector.dart';
import 'package:workaxis/features/access/domain/models/branch_summary.dart';
import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';
import 'package:workaxis/features/branches/domain/models/branch_record.dart';
import 'package:workaxis/features/branches/domain/repositories/branch_management_repository.dart';

/// Production implementation of [BranchManagementRepository] using Firebase SQL Connect.
class SqlConnectBranchManagementRepository implements BranchManagementRepository {
  SqlConnectBranchManagementRepository({
    WorkaxisConnectorConnector? connector,
  }) : _customConnector = connector;

  final WorkaxisConnectorConnector? _customConnector;
  WorkaxisConnectorConnector get _connector =>
      _customConnector ?? WorkaxisConnectorConnector.instance;

  final Map<String, KioskPairingStatus> _kioskStatuses = {};
  final Random _random = Random();

  String _getOrgId(UserAccessContext access) {
    final orgId = access.organization?.id;
    if (orgId == null || orgId.isEmpty) {
      throw const AccessDeniedException('No organization context available.');
    }
    return orgId;
  }

  @override
  Future<List<BranchRecord>> getBranches(UserAccessContext access) async {
    final orgId = _getOrgId(access);
    try {
      final response = await _connector.listBranchesByOrg(orgId: orgId).execute();
      return response.data.branches.map((b) => _toRecord(orgId, b)).toList();
    } catch (e) {
      if (e is AppException) rethrow;
      throw DatabaseException('Failed to retrieve branches: ${e.toString()}');
    }
  }

  @override
  Future<BranchRecord?> getBranch(UserAccessContext access, String id) async {
    final orgId = _getOrgId(access);
    try {
      final response = await _connector.listBranchesByOrg(orgId: orgId).execute();
      final branch = response.data.branches
          .where((b) => b.id == id)
          .firstOrNull;
      if (branch == null) return null;
      return _toRecord(orgId, branch);
    } catch (e) {
      if (e is AppException) rethrow;
      throw DatabaseException('Failed to fetch branch "$id": ${e.toString()}');
    }
  }

  @override
  Future<List<BranchManagerOption>> getBranchManagers(UserAccessContext access) async {
    final orgId = _getOrgId(access);
    try {
      final response = await _connector.listMembersByOrg(orgId: orgId).execute();
      return response.data.organizationMembers
          .where((m) => m.role.toLowerCase() == UserRole.branchManager.name.toLowerCase())
          .map((m) => BranchManagerOption(id: m.id, name: m.fullName))
          .toList();
    } catch (e) {
      if (e is AppException) rethrow;
      throw DatabaseException('Failed to retrieve branch managers: ${e.toString()}');
    }
  }

  @override
  Future<BranchRecord> saveBranch({
    required UserAccessContext access,
    required BranchRecord branch,
  }) async {
    final orgId = _getOrgId(access);
    final id = branch.id.isEmpty ? 'br-${_random.nextInt(9000) + 1000}' : branch.id;

    try {
      await _connector
          .createBranch(
            id: id,
            orgId: orgId,
            name: branch.name,
            code: branch.code,
          )
          .location(branch.location)
          .geofenceRadiusMeters(branch.geofenceRadiusMeters)
          .latitude(branch.latitude)
          .longitude(branch.longitude)
          .kioskEnabled(branch.kioskStatus == KioskPairingStatus.paired)
          .execute();

      return BranchRecord(
        summary: BranchSummary(
          id: id,
          organizationId: orgId,
          name: branch.name,
          code: branch.code,
          location: branch.location,
          isActive: branch.isActive,
        ),
        geofenceRadiusMeters: branch.geofenceRadiusMeters,
        latitude: branch.latitude,
        longitude: branch.longitude,
        managerIds: branch.managerIds,
        kioskStatus: branch.kioskStatus,
      );
    } catch (e) {
      if (e is AppException) rethrow;
      throw DatabaseException('Failed to save branch: ${e.toString()}');
    }
  }

  @override
  Future<KioskPairingToken> createKioskPairingToken({
    required UserAccessContext access,
    required String branchId,
  }) async {
    final token = (_random.nextInt(900000) + 100000).toString();
    _kioskStatuses[branchId] = KioskPairingStatus.pairingPending;
    return KioskPairingToken(branchId: branchId, value: token);
  }

  @override
  Future<void> completeKioskPairing({
    required UserAccessContext access,
    required String branchId,
  }) async {
    _kioskStatuses[branchId] = KioskPairingStatus.paired;
  }

  BranchRecord _toRecord(String orgId, ListBranchesByOrgBranches b) {
    return BranchRecord(
      summary: BranchSummary(
        id: b.id,
        organizationId: orgId,
        name: b.name,
        code: b.code,
        location: b.location ?? 'Main',
        isActive: b.status.toLowerCase() == 'active',
      ),
      geofenceRadiusMeters: b.geofenceRadiusMeters ?? 100,
      latitude: b.latitude ?? 12.9716,
      longitude: b.longitude ?? 77.5946,
      managerIds: const [],
      kioskStatus: _kioskStatuses[b.id] ??
          (b.kioskEnabled == true
              ? KioskPairingStatus.paired
              : KioskPairingStatus.notPaired),
    );
  }
}
