import 'package:workaxis/core/errors/app_exceptions.dart';
import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';

/// Who may see and decide attendance exceptions. The server enforces the
/// same rules; this fails fast with a clear message before a request.
abstract final class AttendanceExceptionsScope {
  /// Employees, and Branch Managers for their own attendance.
  static String requester(UserAccessContext access) {
    final role = access.user.role;
    if (role != UserRole.employee && role != UserRole.branchManager) {
      throw const AccessDeniedException(
        'Only employees can request attendance corrections.',
      );
    }
    return access.user.id;
  }

  /// The organization a reviewer acts in; a Branch Manager must also name an
  /// active branch from their assignments, which is returned.
  static ({String organizationId, String? branchId}) reviewer(
    UserAccessContext access,
    String? activeBranchId,
  ) {
    final role = access.user.role;
    if (role != UserRole.orgAdmin && role != UserRole.branchManager) {
      throw const AccessDeniedException(
        'Only managers can review attendance exceptions.',
      );
    }
    final organizationId = access.organization?.id;
    if (organizationId == null || organizationId.isEmpty) {
      throw const AccessDeniedException(
        'No organization context associated with current session.',
      );
    }
    if (role == UserRole.orgAdmin) {
      return (organizationId: organizationId, branchId: null);
    }
    final branch = access.assignedBranches
        .where((b) => b.id == activeBranchId && b.isActive)
        .firstOrNull;
    if (branch == null) {
      throw const AccessDeniedException(
        'Select an active branch assigned to you.',
      );
    }
    return (organizationId: organizationId, branchId: branch.id);
  }
}
