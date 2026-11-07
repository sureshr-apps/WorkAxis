import 'package:workaxis/core/backend/account_callables.dart';
import 'package:workaxis/core/backend/callable_functions.dart';
import 'package:workaxis/core/errors/app_exceptions.dart';
import 'package:workaxis/core/errors/backend_error_mapper.dart';
import 'package:workaxis/core/errors/validation_exception.dart';
import 'package:workaxis/core/ids/request_ids.dart';
import 'package:workaxis/features/access/domain/models/branch_summary.dart';
import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';
import 'package:workaxis/features/branches/data/branches_remote_data_source.dart';
import 'package:workaxis/features/branches/domain/models/branch_record.dart';
import 'package:workaxis/features/branches/domain/policies/branch_management_policy.dart';
import 'package:workaxis/features/branches/domain/repositories/branch_management_repository.dart';
import 'package:workaxis/features/employees/data/organization_members_remote_data_source.dart';
import 'package:workaxis/features/employees/domain/models/organization_member.dart';

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
    required this._accounts,
    required this._functions,
  });

  static const int _managerPageSize = 100;

  final BranchesRemoteDataSource _branches;
  final OrganizationMembersRemoteDataSource _members;
  final AccountCallables _accounts;
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

    final String id;
    if (branch.id.isEmpty) {
      final code = branch.code.trim().isEmpty
          ? 'BR-${RequestIds.shortCode(5)}'
          : branch.code.trim();
      id = await _branches.add(
        branch.copyWith(
          summary: BranchSummary(
            id: branch.id,
            organizationId: branch.organizationId,
            name: branch.name,
            code: code,
            location: branch.location,
            isActive: branch.isActive,
          ),
        ),
        organizationId: orgId,
      );
    } else {
      final existing = await _branches.getById(branch.id);
      if (existing == null || existing.organizationId != orgId) {
        throw const NotFoundException(
          'Branch not found in caller organization',
        );
      }
      await _branches.update(branch);
      id = branch.id;
    }

    final saved = await _branches.getById(id);
    if (saved == null) throw const NotFoundException('Branch not found');
    await _syncManagers(saved, branch.managerIds);
    return saved.copyWith(
      managerIds: (await _currentManagerIds(saved)).toList(),
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

  /// Aligns the branch's managers with [desired] by editing each manager's
  /// branch assignments (the server preserves their other branches).
  Future<void> _syncManagers(BranchRecord branch, List<String> desired) async {
    final current = await _currentManagerIds(branch);
    final wanted = desired.toSet();
    for (final id in wanted.difference(current)) {
      final manager = await _requireManager(id, branch.organizationId);
      await _accounts.update(
        targetUid: _uid(manager),
        branchIds: {...manager.branchIds, branch.id}.toList(),
      );
    }
    for (final id in current.difference(wanted)) {
      final manager = await _requireManager(id, branch.organizationId);
      final remaining = manager.branchIds.where((b) => b != branch.id).toList();
      if (remaining.isEmpty) {
        throw ValidationException(
          '${manager.fullName} must keep at least one branch. '
          'Assign another branch first.',
        );
      }
      await _accounts.update(targetUid: _uid(manager), branchIds: remaining);
    }
  }

  Future<OrganizationMember> _requireManager(String id, String orgId) async {
    final member = await _members.getById(id);
    if (member == null ||
        member.organizationId != orgId ||
        member.role != UserRole.branchManager) {
      throw ValidationException(
        'A selected branch manager is outside your organization.',
      );
    }
    return member;
  }

  String _uid(OrganizationMember member) {
    final uid = member.authUid;
    if (uid == null || uid.isEmpty) {
      throw ValidationException(
        '${member.fullName} has no sign-in identity yet.',
      );
    }
    return uid;
  }

  Future<T> _guard<T>(Future<T> Function() body) async {
    try {
      return await body();
    } catch (e, st) {
      throw mapBackendError(e, st);
    }
  }
}
