import 'package:workaxis/features/authentication/domain/models/user_role.dart';

/// Minimal access projection needed for role and branch authorization.
class AccessUserSummary {
  const AccessUserSummary({
    required this.id,
    required this.organizationId,
    required this.fullName,
    required this.role,
  });

  final String id;
  final String organizationId;
  final String fullName;
  final UserRole role;
}
