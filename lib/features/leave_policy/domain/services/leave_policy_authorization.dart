import 'package:workaxis/core/errors/app_exceptions.dart';
import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';

/// Access rule shared by every `LeavePolicyRepository` implementation. The
/// backend enforces the same rule.
abstract final class LeavePolicyAuthorization {
  /// Organization id of [access]; only Organization Admins manage the
  /// leave policy.
  static String organizationId(UserAccessContext access) {
    final orgId = access.organization?.id;
    if (access.user.role != UserRole.orgAdmin ||
        orgId == null ||
        orgId.isEmpty) {
      throw const AccessDeniedException(
        'Leave policy requires an Organization Admin session.',
      );
    }
    return orgId;
  }
}
