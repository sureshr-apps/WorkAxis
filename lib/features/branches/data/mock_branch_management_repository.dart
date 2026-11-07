import 'package:workaxis/core/errors/app_exceptions.dart';
import 'package:workaxis/core/errors/validation_exception.dart';
import 'package:workaxis/core/ids/request_ids.dart';
import 'package:workaxis/features/access/data/mock_access_data_source.dart';
import 'package:workaxis/features/access/domain/models/branch_summary.dart';
import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';
import 'package:workaxis/features/branches/domain/branch_geofence_validator.dart';
import 'package:workaxis/features/branches/domain/models/branch_record.dart';
import 'package:workaxis/features/branches/domain/policies/branch_management_policy.dart';
import 'package:workaxis/features/branches/domain/repositories/branch_management_repository.dart';

/// Mock implementation. Branch identity and membership remain in the shared
/// access data source; this repository stores only branch-specific operations.
class MockBranchManagementRepository implements BranchManagementRepository {
  MockBranchManagementRepository({MockAccessDataSource? accessDataSource})
    : accessDataSource = accessDataSource ?? MockAccessDataSource() {
    _settings.addAll({
      'br-01': const _BranchSettings(125, 40.7128, -74.0060, true),
      'br-02': const _BranchSettings(180, 40.7359, -74.0036, false),
      'br-03': const _BranchSettings(250, 40.7580, -73.9855, false),
      'br-04': const _BranchSettings(150, 40.7306, -73.9352, true),
    });
  }

  final MockAccessDataSource accessDataSource;
  final Map<String, _BranchSettings> _settings = {};
  int _nextBranchNumber = 1;

  @override
  Future<List<BranchRecord>> getBranches(UserAccessContext access) async {
    final organizationId = _organizationIdForAdmin(access);
    return accessDataSource
        .getBranchesForOrganization(organizationId)
        .map(_toRecord)
        .toList(growable: false);
  }

  @override
  Future<BranchRecord?> getBranch(UserAccessContext access, String id) async {
    final organizationId = _organizationIdForAdmin(access);
    final summary = accessDataSource.getBranch(id);
    if (summary == null || summary.organizationId != organizationId) {
      return null;
    }
    return _toRecord(summary);
  }

  @override
  Future<List<BranchManagerOption>> getBranchManagers(
    UserAccessContext access,
  ) async {
    final organizationId = _organizationIdForAdmin(access);
    return accessDataSource
        .getUsersWithRole(UserRole.branchManager, organizationId)
        .map((user) => BranchManagerOption(id: user.id, name: user.fullName))
        .toList(growable: false);
  }

  @override
  Future<BranchRecord> saveBranch({
    required UserAccessContext access,
    required BranchRecord branch,
  }) async {
    final organizationId = _organizationIdForAdmin(access);
    if (branch.organizationId != organizationId) {
      throw ValidationException(
        'A branch cannot be moved to another organization.',
      );
    }
    final existing = branch.id.isEmpty
        ? null
        : accessDataSource.getBranch(branch.id);
    if (existing != null && existing.organizationId != organizationId) {
      throw const NotFoundException('Branch not found in caller organization');
    }
    final allowedManagerIds = accessDataSource
        .getUsersWithRole(UserRole.branchManager, organizationId)
        .map((user) => user.id)
        .toSet();
    if (branch.managerIds.any((id) => !allowedManagerIds.contains(id))) {
      throw ValidationException(
        'A selected branch manager is outside your organization.',
      );
    }
    BranchManagementPolicy.validate(branch);
    final normalizedCode = branch.code.trim().toLowerCase();
    if (normalizedCode.isNotEmpty &&
        accessDataSource.getAllBranches().any(
          (candidate) =>
              candidate.id != branch.id &&
              candidate.code.toLowerCase() == normalizedCode,
        )) {
      throw ValidationException('That branch code is already in use.');
    }

    final id = branch.id.isEmpty ? 'br-mock-${_nextBranchNumber++}' : branch.id;
    final summary = BranchSummary(
      id: id,
      organizationId: organizationId,
      name: branch.name.trim(),
      code: branch.code.trim().isEmpty
          ? existing?.code ?? _nextBranchCode()
          : branch.code.trim(),
      location: branch.location.trim(),
      activeEmployeeCount: existing?.activeEmployeeCount ?? 0,
      isActive: branch.isActive,
    );
    accessDataSource.saveBranch(summary);
    _settings[id] = _BranchSettings(
      branch.geofenceRadiusMeters,
      branch.latitude,
      branch.longitude,
      branch.kioskStatus == KioskPairingStatus.paired,
      isMainBranch: branch.isMainBranch,
      pairingPending: branch.kioskStatus == KioskPairingStatus.pairingPending,
    );
    _saveManagerAssignments(id, branch.managerIds);
    return _toRecord(summary);
  }

  @override
  Future<KioskPairingToken> createKioskPairingToken({
    required UserAccessContext access,
    required String branchId,
  }) async {
    BranchManagementPolicy.assertCanPairKiosk(access, branchId);
    final summary = accessDataSource.getBranch(branchId);
    if (summary == null || summary.organizationId != access.organization?.id) {
      throw const NotFoundException('Branch not found in caller organization');
    }
    final branch = _toRecord(summary);
    final token = 'WA-${RequestIds.shortCode(12)}';
    _settings[branchId] = _BranchSettings(
      branch.geofenceRadiusMeters,
      branch.latitude,
      branch.longitude,
      false,
      isMainBranch: branch.isMainBranch,
      pairingPending: true,
    );
    return KioskPairingToken(
      branchId: branchId,
      value: token,
      expiresAt: DateTime.now().add(const Duration(minutes: 10)),
    );
  }

  @override
  Future<void> completeKioskPairing({
    required UserAccessContext access,
    required String branchId,
  }) async {
    final branch = await getBranch(access, branchId);
    if (branch == null) {
      throw const NotFoundException('Branch not found in caller organization');
    }
    _settings[branchId] = _BranchSettings(
      branch.geofenceRadiusMeters,
      branch.latitude,
      branch.longitude,
      true,
      isMainBranch: branch.isMainBranch,
    );
  }

  String _organizationIdForAdmin(UserAccessContext access) =>
      BranchManagementPolicy.requireOrgAdminOrganization(access);

  BranchRecord _toRecord(BranchSummary summary) {
    final settings =
        _settings[summary.id] ??
        const _BranchSettings(
          BranchGeofenceValidator.defaultRadiusMeters,
          null,
          null,
          false,
        );
    final managers = accessDataSource.knownUserIds
        .where((userId) {
          return accessDataSource
                  .getAssignedBranchIds(userId)
                  .contains(summary.id) &&
              accessDataSource
                  .getUsersWithRole(
                    UserRole.branchManager,
                    summary.organizationId,
                  )
                  .any((user) => user.id == userId);
        })
        .toList(growable: false);
    return BranchRecord(
      summary: summary,
      geofenceRadiusMeters: settings.radius,
      latitude: settings.latitude,
      longitude: settings.longitude,
      isMainBranch: settings.isMainBranch,
      managerIds: managers,
      kioskStatus: settings.paired
          ? KioskPairingStatus.paired
          : settings.pairingPending
          ? KioskPairingStatus.pairingPending
          : KioskPairingStatus.notPaired,
    );
  }

  void _saveManagerAssignments(String branchId, List<String> managerIds) {
    final managers =
        accessDataSource
            .getUsersWithRole(
              UserRole.branchManager,
              accessDataSource.getBranch(branchId)?.organizationId ?? '',
            )
            .map((user) => user.id)
            .toSet()
          ..addAll(managerIds);
    for (final managerId in managers) {
      final branchIds = accessDataSource
          .getAssignedBranchIds(managerId)
          .toSet();
      if (managerIds.contains(managerId)) {
        branchIds.add(branchId);
      } else {
        branchIds.remove(branchId);
      }
      if (branchIds.isEmpty) {
        throw ValidationException(
          'A branch manager must keep at least one branch. '
          'Assign another branch first.',
        );
      }
      accessDataSource.setAssignedBranchIds(managerId, branchIds.toList());
    }
  }

  String _nextBranchCode() {
    final existingCodes = accessDataSource.getAllBranches().map((b) => b.code);
    var maxNumber = 100;
    for (final code in existingCodes) {
      final match = RegExp(r'BR-(\d+)').firstMatch(code);
      if (match != null) {
        final number = int.parse(match.group(1)!);
        if (number > maxNumber) maxNumber = number;
      }
    }
    return 'BR-${maxNumber + 1}';
  }
}

class _BranchSettings {
  const _BranchSettings(
    this.radius,
    this.latitude,
    this.longitude,
    this.paired, {
    this.isMainBranch = false,
    this.pairingPending = false,
  });

  final int radius;
  final double? latitude;
  final double? longitude;
  final bool paired;
  final bool isMainBranch;
  final bool pairingPending;
}
