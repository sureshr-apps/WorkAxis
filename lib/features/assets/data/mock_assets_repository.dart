import 'package:workaxis/core/errors/app_exceptions.dart';
import 'package:workaxis/core/errors/validation_exception.dart';
import 'package:workaxis/core/pagination/page_result.dart';
import 'package:workaxis/core/time/clock.dart';
import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/assets/domain/models/asset_queue.dart';
import 'package:workaxis/features/assets/domain/models/employee_asset.dart';
import 'package:workaxis/features/assets/domain/policies/asset_listing_policy.dart';
import 'package:workaxis/features/assets/domain/repositories/assets_repository.dart';
import 'package:workaxis/features/authentication/domain/models/account_status.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';
import 'package:workaxis/features/employees/domain/repositories/organization_members_repository.dart';

class MockAssetsRepository implements AssetsRepository {
  MockAssetsRepository({
    required this.members,
    this.isAcknowledgementRequired = _acknowledgementDisabled,
    Now? now,
  }) : now = now ?? systemNow;

  final OrganizationMembersRepository members;
  final bool Function(String organizationId) isAcknowledgementRequired;
  final Now now;

  static bool _acknowledgementDisabled(String _) => false;

  final List<EmployeeAsset> _assets = [
    EmployeeAsset(
      id: 'asset-001',
      organizationId: 'org-acme',
      branchId: 'br-01',
      branchName: 'Downtown Flagship',
      employeeId: 'user-emp-01',
      employeeName: 'Sarah Connor',
      name: 'Android handheld',
      category: 'Mobile device',
      assetTag: 'WA-DEV-001',
      assignedByUid: 'mock-manager-01',
      assignedByName: 'Jordan Lee',
      assignedAt: DateTime.utc(2026, 11, 2, 8, 30),
      serialNumber: 'SN-1042-A',
      status: AssetStatus.assigned,
      notes: 'Issued for daily outlet operations.',
    ),
    const EmployeeAsset(
      id: 'asset-002',
      organizationId: 'org-acme',
      branchId: 'br-01',
      branchName: 'Downtown Flagship',
      employeeId: 'user-emp-01',
      employeeName: 'Sarah Connor',
      name: 'Staff access card',
      category: 'Access card',
      assetTag: 'WA-CARD-018',
      status: AssetStatus.assigned,
    ),
    const EmployeeAsset(
      id: 'asset-003',
      organizationId: 'org-acme',
      branchId: 'br-01',
      branchName: 'Downtown Flagship',
      employeeId: 'user-emp-02',
      employeeName: 'Alex Chen',
      name: 'Barcode scanner',
      category: 'Store equipment',
      assetTag: 'WA-SCN-007',
      serialNumber: 'SC-77312',
      status: AssetStatus.maintenance,
    ),
    const EmployeeAsset(
      id: 'asset-004',
      organizationId: 'org-acme',
      branchId: 'br-02',
      branchName: 'Westside Hub',
      employeeId: 'user-emp-03',
      employeeName: 'Priya Shah',
      name: 'Work laptop',
      category: 'Computer',
      assetTag: 'WA-LAP-014',
      serialNumber: 'LT-39011',
      status: AssetStatus.assigned,
    ),
    const EmployeeAsset(
      id: 'asset-005',
      organizationId: 'org-acme',
      branchId: 'br-04',
      branchName: 'East Bay Outlet',
      employeeId: 'user-emp-04',
      employeeName: 'Daniel Kim',
      name: 'Store keys',
      category: 'Keys',
      assetTag: 'WA-KEY-004',
      status: AssetStatus.returned,
    ),
  ];

  int _nextId = 6;

  @override
  Future<PageResult<EmployeeAsset>> getAssetsPage({
    required UserAccessContext access,
    required AssetQueue queue,
    String? activeBranchId,
    String? query,
    int offset = 0,
    int limit = defaultPageSize,
  }) async {
    final role = access.user.role;
    if (!AssetQueue.allowedFor(role).contains(queue)) {
      throw const AccessDeniedException();
    }
    final orgId = _requireOrganization(access);
    final scoped = await _assetsInQueue(access, queue, orgId, activeBranchId);
    final matching =
        scoped
            .where((asset) => AssetListingPolicy.matchesQuery(asset, query))
            .toList()
          ..sort(AssetListingPolicy.compare);
    return PageResult(
      items: List.unmodifiable(matching.skip(offset).take(limit)),
      total: matching.length,
      offset: offset,
    );
  }

  /// Mirrors the scope of the server listing behind each [queue].
  Future<Iterable<EmployeeAsset>> _assetsInQueue(
    UserAccessContext access,
    AssetQueue queue,
    String orgId,
    String? activeBranchId,
  ) async {
    bool isOwn(EmployeeAsset asset) =>
        asset.employeeUid == access.user.id ||
        asset.employeeId == access.user.id;
    final inOrganization = _assets.where(
      (asset) => asset.organizationId == orgId,
    );
    switch (queue) {
      case AssetQueue.organization:
        return inOrganization;
      case AssetQueue.mine:
        if (access.user.role != UserRole.branchManager) {
          return inOrganization.where(isOwn);
        }
        final branchId = _requireManagedBranch(access, activeBranchId);
        return inOrganization.where(
          (asset) => isOwn(asset) && asset.branchId == branchId,
        );
      case AssetQueue.branchEmployees:
        final branchId = _requireManagedBranch(access, activeBranchId);
        final assignedEmployees = await members.getMembers(
          access: access,
          activeBranchId: branchId,
        );
        final employeesById = {
          for (final member in assignedEmployees)
            if (member.role == UserRole.employee) member.id: member,
        };
        return inOrganization.where((asset) {
          final employee = employeesById[asset.employeeId];
          return employee != null &&
              employee.branchIds.contains(asset.branchId);
        });
    }
  }

  @override
  Future<EmployeeAsset> saveAsset({
    required UserAccessContext access,
    required EmployeeAsset asset,
    String? activeBranchId,
  }) async {
    final orgId = _requireEditor(access);
    final branchId = asset.branchId;
    _requireAssetBranch(access, branchId, activeBranchId);
    if (asset.organizationId != orgId) throw const AccessDeniedException();

    final employee = await members.getMember(
      access: access,
      memberId: asset.employeeId,
      activeBranchId: access.user.role == UserRole.branchManager
          ? activeBranchId
          : null,
    );
    final canAssignToMember =
        employee != null &&
        (employee.role == UserRole.employee ||
            (access.user.role == UserRole.orgAdmin &&
                employee.role == UserRole.branchManager));
    if (!canAssignToMember ||
        !employee.branchIds.contains(branchId) ||
        (access.user.role == UserRole.branchManager &&
            employee.role != UserRole.employee)) {
      throw const AccessDeniedException(
        'The selected employee is not assigned to this branch.',
        'Choose an employee who belongs to the selected outlet.',
      );
    }

    final normalizedTag = asset.assetTag.trim().toLowerCase();
    final duplicate = _assets.any(
      (existing) =>
          existing.organizationId == orgId &&
          existing.id != asset.id &&
          existing.assetTag.trim().toLowerCase() == normalizedTag,
    );
    if (duplicate) {
      throw ValidationException(
        'That asset tag is already used in this organization.',
      );
    }

    final branch = access.assignedBranches.where((item) => item.id == branchId);
    final existingIndex = _assets.indexWhere((item) => item.id == asset.id);
    final EmployeeAsset? existing = existingIndex == -1
        ? null
        : _assets[existingIndex];
    final assignmentChanged =
        existing == null ||
        existing.employeeId != employee.id ||
        existing.branchId != branchId ||
        (existing.status == AssetStatus.returned &&
            asset.status == AssetStatus.assigned);
    // Inactive members keep (and may return) what they hold, but cannot be
    // handed an asset. Mirrors `SaveEmployeeAsset` on the server.
    if (assignmentChanged &&
        asset.status != AssetStatus.returned &&
        employee.status != AccountStatus.active) {
      throw ValidationException(
        'Assets can only be assigned to active members.',
      );
    }
    final clearPendingAcknowledgement =
        asset.status == AssetStatus.returned &&
        existing?.acknowledgementStatus == AssetAcknowledgementStatus.pending;
    final resetAcknowledgement =
        assignmentChanged || clearPendingAcknowledgement;
    final acknowledgementRequired = resetAcknowledgement
        ? asset.status != AssetStatus.returned &&
              employee.role == UserRole.employee &&
              isAcknowledgementRequired(orgId)
        : existing.acknowledgementRequired;
    final saved = EmployeeAsset(
      id: asset.id.isEmpty ? 'asset-${_nextId++}' : asset.id,
      organizationId: orgId,
      branchId: branchId,
      branchName: branch.isEmpty ? asset.branchName : branch.first.name,
      employeeId: employee.id,
      employeeName: employee.fullName,
      employeeUid: employee.authUid,
      name: asset.name.trim(),
      category: asset.category.trim(),
      assetTag: asset.assetTag.trim(),
      serialNumber: _optional(asset.serialNumber),
      status: asset.status,
      acknowledgementRequired: acknowledgementRequired,
      acknowledgementStatus: resetAcknowledgement
          ? (acknowledgementRequired
                ? AssetAcknowledgementStatus.pending
                : AssetAcknowledgementStatus.notRequired)
          : existing.acknowledgementStatus,
      assignedByUid: assignmentChanged
          ? access.user.id
          : existing.assignedByUid,
      assignedByName: assignmentChanged
          ? access.user.name
          : existing.assignedByName,
      assignedAt: assignmentChanged ? now() : existing.assignedAt,
      acknowledgedByUid: resetAcknowledgement
          ? null
          : existing.acknowledgedByUid,
      acknowledgedByName: resetAcknowledgement
          ? null
          : existing.acknowledgedByName,
      acknowledgedAt: resetAcknowledgement ? null : existing.acknowledgedAt,
      notes: _optional(asset.notes),
    );
    if (existingIndex == -1) {
      _assets.add(saved);
    } else {
      final existing = _assets[existingIndex];
      _ensureCanManageExisting(access, existing, activeBranchId);
      await _ensureEmployeeBranch(access, existing, activeBranchId);
      _assets[existingIndex] = saved;
    }
    return saved;
  }

  @override
  Future<EmployeeAsset> acknowledgeAsset({
    required UserAccessContext access,
    required String assetId,
  }) async {
    if (access.user.role != UserRole.employee) {
      throw const AccessDeniedException();
    }
    final orgId = _requireOrganization(access);
    final index = _assets.indexWhere(
      (asset) =>
          asset.id == assetId &&
          asset.organizationId == orgId &&
          asset.employeeId == access.user.id,
    );
    if (index == -1) throw const AccessDeniedException();
    final asset = _assets[index];
    if (asset.acknowledgementStatus ==
        AssetAcknowledgementStatus.acknowledged) {
      return asset;
    }
    if (!asset.acknowledgementRequired ||
        asset.acknowledgementStatus != AssetAcknowledgementStatus.pending) {
      throw ValidationException('This asset does not need acknowledgment.');
    }
    final acknowledged = asset.copyWith(
      acknowledgementStatus: AssetAcknowledgementStatus.acknowledged,
      acknowledgedByUid: access.user.id,
      acknowledgedByName: access.user.name,
      acknowledgedAt: now(),
    );
    _assets[index] = acknowledged;
    return acknowledged;
  }

  @override
  Future<void> deleteAsset({
    required UserAccessContext access,
    required String assetId,
    String? activeBranchId,
  }) async {
    _requireEditor(access);
    final index = _assets.indexWhere((asset) => asset.id == assetId);
    if (index == -1) throw const NotFoundException('Asset not found.');
    _ensureCanManageExisting(access, _assets[index], activeBranchId);
    await _ensureEmployeeBranch(access, _assets[index], activeBranchId);
    _assets.removeAt(index);
  }

  String _requireOrganization(UserAccessContext access) {
    final orgId = access.organization?.id;
    if (orgId == null || orgId.isEmpty) {
      throw const AccessDeniedException();
    }
    return orgId;
  }

  String _requireEditor(UserAccessContext access) {
    if (access.user.role != UserRole.orgAdmin &&
        access.user.role != UserRole.branchManager) {
      throw const AccessDeniedException();
    }
    return _requireOrganization(access);
  }

  String _requireManagedBranch(UserAccessContext access, String? branchId) {
    final selected = branchId ?? access.activeBranch?.branchId;
    if (selected == null ||
        !access.activeAssignedBranches.any((branch) => branch.id == selected)) {
      throw const BranchAuthorizationException(
        'An active branch managed by this user is required.',
      );
    }
    return selected;
  }

  void _requireAssetBranch(
    UserAccessContext access,
    String branchId,
    String? activeBranchId,
  ) {
    final orgId = _requireOrganization(access);
    if (access.user.role == UserRole.branchManager) {
      if (_requireManagedBranch(access, activeBranchId) != branchId) {
        throw const AccessDeniedException();
      }
      return;
    }
    if (!access.assignedBranches.any(
      (branch) => branch.id == branchId && branch.organizationId == orgId,
    )) {
      throw const AccessDeniedException();
    }
  }

  void _ensureCanManageExisting(
    UserAccessContext access,
    EmployeeAsset existing,
    String? activeBranchId,
  ) {
    final orgId = _requireEditor(access);
    if (existing.organizationId != orgId) throw const AccessDeniedException();
    if (access.user.role == UserRole.branchManager &&
        _requireManagedBranch(access, activeBranchId) != existing.branchId) {
      throw const AccessDeniedException();
    }
  }

  Future<void> _ensureEmployeeBranch(
    UserAccessContext access,
    EmployeeAsset asset,
    String? activeBranchId,
  ) async {
    if (access.user.role != UserRole.branchManager) return;
    final employee = await members.getMember(
      access: access,
      memberId: asset.employeeId,
      activeBranchId: activeBranchId,
    );
    if (employee == null ||
        employee.role != UserRole.employee ||
        !employee.branchIds.contains(asset.branchId)) {
      throw const AccessDeniedException();
    }
  }

  String? _optional(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}
