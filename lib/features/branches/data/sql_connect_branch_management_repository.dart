import 'package:workaxis/core/backend/callable_functions.dart';
import 'package:workaxis/core/ids/request_ids.dart';
import 'package:workaxis/core/errors/app_exceptions.dart';
import 'package:workaxis/core/errors/backend_error_mapper.dart';
import 'package:workaxis/core/errors/validation_exception.dart';
import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';
import 'package:workaxis/features/branches/data/branches_remote_data_source.dart';
import 'package:workaxis/features/branches/domain/models/branch_record.dart';
import 'package:workaxis/features/branches/domain/policies/branch_management_policy.dart';
import 'package:workaxis/features/branches/domain/repositories/branch_management_repository.dart';
import 'package:workaxis/features/employees/data/organization_members_remote_data_source.dart';

/// Production [BranchManagementRepository].
///
/// Branch fields use SQL Connect (`AddBranch`, `UpdateBranch`,
/// `GetBranchById`). Branch Manager assignments are identity data, so they go
/// through `updateUserAccount`; kiosk pairing tokens come from the
/// `createKioskPairingToken` callable (random, expiring, stored hashed).
class SqlConnectBranchManagementRepository
    implements BranchManagementRepository {
  SqlConnectBranchManagementRepository({
    required this._branches,
    required this._members,
    required this._functions,
  });

  static const int _managerPageSize = 100;
  final Expando<String> _createRequests = Expando<String>();

  final BranchesRemoteDataSource _branches;
  final OrganizationMembersRemoteDataSource _members;
  final CallableFunctions _functions;

  @override
  Future<List<BranchRecord>> getBranches(UserAccessContext access) => _guard(
    () async {
      final orgId = BranchManagementPolicy.requireOrgAdminOrganization(access);
      return _branches.listByOrganization(orgId);
    },
  );

  @override
  Future<BranchRecord?> getBranch(UserAccessContext access, String id) =>
      _guard(() async {
        final orgId = BranchManagementPolicy.requireOrgAdminOrganization(
          access,
        );
        final branch = await _branches.getById(id);
        if (branch == null || branch.organizationId != orgId) return null;
        return branch.copyWith(
          managerIds: (await _currentManagerIds(branch)).toList(),
        );
      });

  @override
  Future<List<BranchManagerOption>> getBranchManagers(
    UserAccessContext access,
  ) => _guard(() async {
    final orgId = BranchManagementPolicy.requireOrgAdminOrganization(access);
    final options = <BranchManagerOption>[];
    var offset = 0;
    while (true) {
      final page = await _members.listByOrganization(
        organizationId: orgId,
        limit: _managerPageSize,
        offset: offset,
        role: UserRole.branchManager,
      );
      options.addAll(
        page.items.map((m) => BranchManagerOption(id: m.id, name: m.fullName)),
      );
      if (!page.hasMore) return options;
      offset = page.nextOffset;
    }
  });

  @override
  Future<BranchRecord> saveBranch({
    required UserAccessContext access,
    required BranchRecord branch,
  }) => _guard(() async {
    final orgId = BranchManagementPolicy.requireOrgAdminOrganization(access);
    if (branch.organizationId != orgId) {
      throw ValidationException(
        'A branch cannot be moved to another organization.',
      );
    }
    BranchManagementPolicy.validate(branch);

    final response = await _functions.call('saveBranch', {
      if (branch.id.isEmpty)
        'requestId':
            branch.requestId ??
            (_createRequests[branch] ??= RequestIds.uuidV4()),
      if (branch.id.isNotEmpty) 'id': branch.id,
      'name': branch.name.trim(),
      'code': branch.code.trim(),
      'location': branch.location.trim(),
      'status': branch.isActive ? 'active' : 'suspended',
      'isMainBranch': branch.isMainBranch,
      'geofenceRadiusMeters': branch.geofenceRadiusMeters,
      'latitude': branch.latitude,
      'longitude': branch.longitude,
      'managerIds': branch.managerIds,
    });
    final id = response['id'];
    if (id is! String || id.isEmpty) {
      throw const DatabaseException('saveBranch returned no id.');
    }
    // The callable committed the business change. Use its known values rather
    // than turning a subsequent read/projection outage into a false save failure.
    return BranchRecord(
      summary: branch.summary.copyWith(
        id: id,
        code: branch.code.isEmpty
            ? (response['code'] as String? ?? '')
            : branch.code,
      ),
      geofenceRadiusMeters: branch.geofenceRadiusMeters,
      latitude: branch.latitude,
      longitude: branch.longitude,
      isMainBranch: branch.isMainBranch,
      managerIds: List.unmodifiable(branch.managerIds),
      kioskStatus: branch.kioskStatus,
    );
  });

  @override
  Future<KioskPairingToken> createKioskPairingToken({
    required UserAccessContext access,
    required String branchId,
  }) => _guard(() async {
    BranchManagementPolicy.assertCanPairKiosk(access, branchId);
    final response = await _functions.call('createKioskPairingToken', {
      'branchId': branchId,
    });
    final token = response['token'];
    if (token is! String || token.isEmpty) {
      throw const DatabaseException(
        'createKioskPairingToken returned no token',
      );
    }
    final expires = response['expiresAt'];
    return KioskPairingToken(
      branchId: branchId,
      value: token,
      expiresAt: expires is String ? DateTime.tryParse(expires) : null,
    );
  });

  @override
  Future<void> completeKioskPairing({
    required UserAccessContext access,
    required String branchId,
  }) => _guard(() async {
    // Redemption happens on the kiosk device (not implemented server-side).
    throw ValidationException(
      'Pairing finishes when the code is entered on the kiosk device.',
    );
  });

  Future<Set<String>> _currentManagerIds(BranchRecord branch) async {
    final ids = <String>{};
    var offset = 0;
    while (true) {
      final page = await _members.listByBranch(
        organizationId: branch.organizationId,
        branchId: branch.id,
        limit: _managerPageSize,
        offset: offset,
      );
      ids.addAll(
        page.items
            .where((m) => m.role == UserRole.branchManager)
            .map((m) => m.id),
      );
      if (!page.hasMore) return ids;
      offset = page.nextOffset;
    }
  }

  Future<T> _guard<T>(Future<T> Function() body) async {
    try {
      return await body();
    } catch (e, st) {
      throw mapBackendError(e, st);
    }
  }
}
