import 'package:workaxis/core/errors/app_exceptions.dart';
import 'package:workaxis/core/errors/validation_exception.dart';
import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';
import 'package:workaxis/features/branches/domain/branch_geofence_validator.dart';
import 'package:workaxis/features/branches/domain/models/branch_record.dart';

/// Authorization and validation for branch management, shared by the mock and
/// production repositories.
class BranchManagementPolicy {
  BranchManagementPolicy._();

  /// Only Organization Admins manage branches; Branch Managers cannot create
  /// or edit them. Returns the caller's organization id.
  static String requireOrgAdminOrganization(UserAccessContext access) {
    final orgId = access.organization?.id;
    if (access.user.role != UserRole.orgAdmin || orgId == null) {
      throw const AccessDeniedException(
        'Only an organization administrator can manage branches',
        'Only an organization administrator can manage branches.',
      );
    }
    return orgId;
  }

  /// Org Admins may pair a kiosk for any organization branch; Branch Managers
  /// only for an active branch they are assigned to.
  static void assertCanPairKiosk(UserAccessContext access, String branchId) {
    final role = access.user.role;
    if (role == UserRole.orgAdmin && access.organization != null) return;
    if (role == UserRole.branchManager &&
        access.assignedBranches.any((b) => b.id == branchId && b.isActive)) {
      return;
    }
    throw const AccessDeniedException(
      'Role cannot pair a kiosk for this branch',
      'You cannot pair a kiosk for this branch.',
    );
  }

  /// Validates a branch draft (name, location and geofence).
  static void validate(BranchRecord branch) {
    if (branch.name.trim().isEmpty) {
      throw ValidationException('Enter the branch name.');
    }
    if (branch.location.trim().isEmpty) {
      throw ValidationException('Enter the branch location.');
    }
    BranchGeofenceValidator.validate(
      latitude: branch.latitude,
      longitude: branch.longitude,
      radiusMeters: branch.geofenceRadiusMeters,
    );
  }
}
