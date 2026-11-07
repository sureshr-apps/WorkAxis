import 'package:workaxis/features/access/domain/models/organization_summary.dart';
import 'package:workaxis/features/authentication/domain/models/account_status.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';

/// The caller's own authoritative membership row (SQL `OrganizationMember`).
class AccessMemberRecord {
  const AccessMemberRecord({
    required this.memberId,
    required this.authUid,
    required this.role,
    required this.status,
    this.organization,
  });

  final String memberId;
  final String? authUid;

  /// Null when the stored role is unknown (treated as denied).
  final UserRole? role;

  /// Null when the stored status is unknown (treated as denied).
  final AccountStatus? status;
  final OrganizationSummary? organization;
}
