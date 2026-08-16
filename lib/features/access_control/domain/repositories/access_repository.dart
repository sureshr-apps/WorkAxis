import 'package:workaxis/features/access_control/domain/entities/app_user.dart';
import 'package:workaxis/features/access_control/domain/entities/invitation.dart';
import 'package:workaxis/features/access_control/domain/entities/organization_membership.dart';

/// Abstract contract for access control, organization memberships, and invitations.
abstract interface class AccessRepository {
  /// Resolves the application user profile by phone number, email, or auth UID.
  Future<AppUser?> resolveUser({
    String? phoneNumber,
    String? email,
    String? uid,
  });

  /// Resolves the application user profile for an authenticated phone number.
  Future<AppUser?> resolveUserByPhone(String phoneNumber);

  /// Retrieves all organization memberships for a user.
  Future<List<OrganizationMembership>> getMemberships(String userId);

  /// Retrieves any active pending invitation sent to a specific phone number.
  Future<Invitation?> getPendingInvitationByPhone(String phoneNumber);

  /// Retrieves a specific invitation by its unique identifier.
  Future<Invitation?> getInvitationById(String invitationId);

  /// Accepts an invitation, activates membership, and returns the active membership.
  Future<OrganizationMembership> acceptInvitation({
    required String invitationId,
    required String userId,
  });

  /// Declines a pending invitation.
  Future<void> declineInvitation(String invitationId);

  /// Records the last accessed organization for session preference.
  Future<void> recordLastAccessedOrganization({
    required String userId,
    required String organizationId,
  });
}
