import 'package:workaxis/core/errors/app_exceptions.dart';
import 'package:workaxis/features/access/data/mock_access_data_source.dart';
import 'package:workaxis/features/access/domain/models/active_branch_context.dart';
import 'package:workaxis/features/access/domain/models/branch_summary.dart';
import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/access/domain/repositories/access_repository.dart';
import 'package:workaxis/features/authentication/domain/models/app_user.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';

/// Mock implementation of [AccessRepository] resolving organizational context and branches.
class MockAccessRepository implements AccessRepository {
  MockAccessRepository({
    MockAccessDataSource? dataSource,
    this.delay = const Duration(milliseconds: 350),
    this.shouldSimulateFailure = false,
  }) : _dataSource = dataSource ?? MockAccessDataSource();

  final MockAccessDataSource _dataSource;
  MockAccessDataSource get dataSource => _dataSource;
  final Duration delay;
  bool shouldSimulateFailure;

  @override
  Future<UserAccessContext> resolveCurrentUserAccess(AppUser user) async {
    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }

    if (shouldSimulateFailure) {
      throw const AccessResolutionException(
        'Unable to reach access authorization service.',
      );
    }

    // Platform-level users do not belong to customer organizations.
    if (user.isPlatformLevel) {
      return UserAccessContext(
        user: user,
        organization: null,
        assignedBranches: const [],
        activeBranch: null,
        permissions: {
          'platform.manage',
          if (user.role == UserRole.platformOwner) 'platform.owner',
        },
      );
    }

    // Customer-level users must belong to exactly one customer organization.
    final orgId = user.organizationId;
    if (orgId == null) {
      throw const AccessResolutionException(
        'Customer user is missing organization membership.',
      );
    }

    final org = _dataSource.getOrganization(orgId);
    if (org == null) {
      throw AccessResolutionException(
        'Organization $orgId could not be found.',
      );
    }

    final assignedBranches = _dataSource.getAssignedBranchesForUser(user.id);

    ActiveBranchContext? initialActiveBranch;

    // Branch Manager single-branch auto-selection rule:
    // If exactly one ACTIVE branch is assigned, set it automatically.
    if (user.role == UserRole.branchManager) {
      final activeBranches = assignedBranches.where((b) => b.isActive).toList();
      if (activeBranches.length == 1) {
        initialActiveBranch = ActiveBranchContext.fromBranch(
          activeBranches.first,
        );
      }
    } else if (user.role == UserRole.employee && assignedBranches.isNotEmpty) {
      initialActiveBranch = ActiveBranchContext.fromBranch(
        assignedBranches.first,
      );
    }

    return UserAccessContext(
      user: user,
      organization: org,
      assignedBranches: assignedBranches,
      activeBranch: initialActiveBranch,
      permissions: {
        'org.access',
        if (user.role == UserRole.orgAdmin) 'org.admin',
        if (user.role == UserRole.branchManager) 'branch.manage',
        if (user.role == UserRole.employee) 'employee.self_service',
      },
    );
  }

  @override
  Future<List<BranchSummary>> getAssignedBranches(String userId) async {
    if (delay > Duration.zero) {
      await Future<void>.delayed(const Duration(milliseconds: 150));
    }
    return _dataSource.getAssignedBranchesForUser(userId);
  }

  @override
  Future<bool> validateBranchAccess({
    required String userId,
    required String branchId,
  }) async {
    final assigned = _dataSource.getAssignedBranchesForUser(userId);
    return assigned.any((b) => b.id == branchId && b.isActive);
  }
}
