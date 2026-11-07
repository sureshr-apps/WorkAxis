import 'package:workaxis/core/errors/app_exceptions.dart';
import 'package:workaxis/features/access/data/mock_access_data_source.dart';
import 'package:workaxis/features/access/domain/models/branch_summary.dart';
import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/access/domain/repositories/access_repository.dart';
import 'package:workaxis/features/access/domain/services/access_resolver.dart';
import 'package:workaxis/features/authentication/domain/models/app_user.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';

/// Mock [AccessRepository]. Applies the same rules as the production
/// repository through [AccessResolver]; only the facts come from fixtures.
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

    final orgId = user.organizationId;
    return AccessResolver.resolve(
      user: user,
      organization: orgId == null ? null : _dataSource.getOrganization(orgId),
      branches: _branchesFor(user.id, user.role, orgId),
    );
  }

  @override
  Future<List<BranchSummary>> getAssignedBranches(String userId) async {
    if (delay > Duration.zero) {
      await Future<void>.delayed(const Duration(milliseconds: 150));
    }
    final profile = _dataSource.getUserProfile(userId);
    if (profile == null) return const [];
    return _branchesFor(userId, profile.role, profile.organizationId);
  }

  @override
  Future<bool> validateBranchAccess({
    required String userId,
    required String branchId,
  }) async {
    final branches = await getAssignedBranches(userId);
    return branches.any((b) => b.id == branchId && b.isActive);
  }

  /// Production returns active assignments only; the mock agrees.
  List<BranchSummary> _active(List<BranchSummary> branches) =>
      branches.where((b) => b.isActive).toList(growable: false);

  List<BranchSummary> _branchesFor(
    String userId,
    UserRole role,
    String? organizationId,
  ) {
    switch (role) {
      case UserRole.orgAdmin:
        if (organizationId == null) return const [];
        return _active(_dataSource.getBranchesForOrganization(organizationId));
      case UserRole.branchManager:
      case UserRole.employee:
        return _active(_dataSource.getAssignedBranchesForUser(userId));
      case UserRole.platformOwner:
      case UserRole.platformAdmin:
        return const [];
    }
  }
}
