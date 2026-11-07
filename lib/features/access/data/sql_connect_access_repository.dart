import 'package:workaxis/core/errors/app_exceptions.dart';
import 'package:workaxis/dataconnect_generated/workaxis_connector.dart';
import 'package:workaxis/features/access/domain/models/active_branch_context.dart';
import 'package:workaxis/features/access/domain/models/branch_summary.dart';
import 'package:workaxis/features/access/domain/models/organization_summary.dart';
import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/access/domain/repositories/access_repository.dart';
import 'package:workaxis/features/authentication/domain/models/app_user.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';

/// Production implementation of [AccessRepository] powered by Firebase SQL Connect.
class SqlConnectAccessRepository implements AccessRepository {
  SqlConnectAccessRepository({WorkaxisConnectorConnector? connector})
      : _customConnector = connector;

  final WorkaxisConnectorConnector? _customConnector;
  WorkaxisConnectorConnector get _connector =>
      _customConnector ?? WorkaxisConnectorConnector.instance;

  @override
  Future<UserAccessContext> resolveCurrentUserAccess(AppUser user) async {
    // 1. Platform-level users do not belong to customer organizations.
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

    // 2. Customer users must belong to an organization.
    final orgId = user.organizationId;
    if (orgId == null || orgId.isEmpty) {
      throw const AccessResolutionException(
        'Customer user is missing organization membership.',
      );
    }

    try {
      final orgResult = await _connector.getOrganizationById(id: orgId).execute();
      final orgData = orgResult.data.organization;
      if (orgData == null) {
        throw AccessResolutionException('Organization "$orgId" could not be found.');
      }

      final organization = OrganizationSummary(
        id: orgData.id,
        name: orgData.name,
        code: orgData.code,
      );

      // Query branches for this organization
      final branchesResult = await _connector.listBranchesByOrg(orgId: orgId).execute();
      final allBranches = branchesResult.data.branches
          .map(
            (b) => BranchSummary(
              id: b.id,
              organizationId: orgId,
              name: b.name,
              code: b.code,
              location: b.location ?? '',
              isActive: b.status.toLowerCase() == 'active',
            ),
          )
          .toList();

      final List<BranchSummary> assignedBranches;
      ActiveBranchContext? activeBranch;
      final Set<String> permissions = <String>{};

      switch (user.role) {
        case UserRole.orgAdmin:
          assignedBranches = allBranches;
          permissions.addAll({
            'org.manage',
            'branch.manage',
            'branch.view',
            'attendance.manage',
            'attendance.review',
            'returns.manage',
          });
          if (assignedBranches.isNotEmpty) {
            final first = assignedBranches.first;
            activeBranch = ActiveBranchContext(
              branchId: first.id,
              branchName: first.name,
              branchCode: first.code,
              organizationId: orgId,
            );
          }
          break;

        case UserRole.branchManager:
          assignedBranches = allBranches;
          permissions.addAll({
            'branch.manage',
            'attendance.record',
            'attendance.review',
            'returns.manage',
          });
          if (assignedBranches.length == 1) {
            final b = assignedBranches.first;
            activeBranch = ActiveBranchContext(
              branchId: b.id,
              branchName: b.name,
              branchCode: b.code,
              organizationId: orgId,
            );
          }
          break;

        case UserRole.employee:
          assignedBranches = allBranches.isNotEmpty ? [allBranches.first] : const [];
          permissions.addAll({
            'attendance.self',
            'returns.submit',
          });
          if (assignedBranches.isNotEmpty) {
            final b = assignedBranches.first;
            activeBranch = ActiveBranchContext(
              branchId: b.id,
              branchName: b.name,
              branchCode: b.code,
              organizationId: orgId,
            );
          }
          break;

        default:
          assignedBranches = const [];
      }

      return UserAccessContext(
        user: user,
        organization: organization,
        assignedBranches: assignedBranches,
        activeBranch: activeBranch,
        permissions: permissions,
      );
    } catch (e) {
      if (e is AppException) rethrow;
      throw AccessResolutionException('Failed to resolve access context: ${e.toString()}');
    }
  }

  @override
  Future<List<BranchSummary>> getAssignedBranches(String userId) async {
    try {
      final result = await _connector.listBranchesByOrg(orgId: 'org-acme').execute();
      return result.data.branches
          .map(
            (b) => BranchSummary(
              id: b.id,
              organizationId: 'org-acme',
              name: b.name,
              code: b.code,
              location: b.location ?? '',
              isActive: b.status.toLowerCase() == 'active',
            ),
          )
          .toList();
    } catch (e) {
      throw DatabaseException('Failed to fetch assigned branches: ${e.toString()}');
    }
  }

  @override
  Future<bool> validateBranchAccess({
    required String userId,
    required String branchId,
  }) async {
    try {
      final branches = await getAssignedBranches(userId);
      return branches.any((b) => b.id == branchId);
    } catch (_) {
      return false;
    }
  }
}
