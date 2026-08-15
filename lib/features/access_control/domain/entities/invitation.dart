import 'package:equatable/equatable.dart';
import 'package:workaxis/features/access_control/domain/entities/user_role.dart';

enum InvitationStatus { pending, accepted, declined, expired }

/// Invitation entity for onboarding new employees or managers to an organization.
class Invitation extends Equatable {
  const Invitation({
    required this.id,
    required this.organizationId,
    required this.organizationName,
    this.organizationLogoUrl,
    required this.invitedPhone,
    required this.invitedRole,
    this.branchId,
    this.branchName,
    this.invitedBy,
    required this.expiresAt,
    this.status = InvitationStatus.pending,
  });

  final String id;
  final String organizationId;
  final String organizationName;
  final String? organizationLogoUrl;
  final String invitedPhone;
  final UserRole invitedRole;
  final String? branchId;
  final String? branchName;
  final String? invitedBy;
  final DateTime expiresAt;
  final InvitationStatus status;

  bool get isExpired =>
      status == InvitationStatus.expired || DateTime.now().isAfter(expiresAt);

  @override
  List<Object?> get props => [
        id,
        organizationId,
        organizationName,
        organizationLogoUrl,
        invitedPhone,
        invitedRole,
        branchId,
        branchName,
        invitedBy,
        expiresAt,
        status,
      ];
}
