import 'dart:async';
import 'package:workaxis/core/errors/app_exceptions.dart';
import 'package:workaxis/features/access_control/domain/entities/app_user.dart';
import 'package:workaxis/features/access_control/domain/entities/invitation.dart';
import 'package:workaxis/features/access_control/domain/entities/organization.dart';
import 'package:workaxis/features/access_control/domain/entities/organization_membership.dart';
import 'package:workaxis/features/access_control/domain/entities/user_role.dart';

abstract interface class AccessRemoteDataSource {
  Future<AppUser?> resolveUser({
    String? phoneNumber,
    String? email,
    String? uid,
  });
  Future<AppUser?> resolveUserByPhone(String phoneNumber);
  Future<List<OrganizationMembership>> getMemberships(String userId);
  Future<Invitation?> getPendingInvitationByPhone(String phoneNumber);
  Future<Invitation?> getInvitationById(String invitationId);
  Future<OrganizationMembership> acceptInvitation({
    required String invitationId,
    required String userId,
  });
  Future<void> declineInvitation(String invitationId);
  Future<void> recordLastAccessedOrganization({
    required String userId,
    required String organizationId,
  });
  Future<Organization?> getOrganization(String organizationId);
}

/// InMemoryAccessDataSource simulates enterprise organization access resolution
/// with realistic roles, permissions, branches, and invitations.
class InMemoryAccessDataSource implements AccessRemoteDataSource {
  InMemoryAccessDataSource() {
    _seedData();
  }

  final Map<String, AppUser> _usersByPhone = {};
  final Map<String, AppUser> _usersByEmail = {};
  final Map<String, List<OrganizationMembership>> _membershipsByUserId = {};
  final Map<String, Invitation> _invitationsById = {};
  final Map<String, String> _invitationsByPhone = {};
  final Map<String, Organization> _organizationsById = {};

  void _seedData() {
    // Organizations
    const org1 = Organization(
      id: 'org_central_valley',
      name: 'Central Valley Produce',
      code: 'CVP-01',
      status: OrgStatus.active,
      address: 'Fresno, CA',
    );
    const org2 = Organization(
      id: 'org_green_harvest',
      name: 'GreenHarvest Distribution',
      code: 'GHD-02',
      status: OrgStatus.active,
      address: 'Salinas, CA',
    );
    const org3 = Organization(
      id: 'org_metro_logistics',
      name: 'Metro Logistics Hub',
      code: 'MLH-03',
      status: OrgStatus.active,
      address: 'Sacramento, CA',
    );
    const orgSuspended = Organization(
      id: 'org_suspended_express',
      name: 'Fruit Express Corp',
      code: 'FEC-99',
      status: OrgStatus.suspended,
      address: 'Bakersfield, CA',
    );

    _organizationsById[org1.id] = org1;
    _organizationsById[org2.id] = org2;
    _organizationsById[org3.id] = org3;
    _organizationsById[orgSuspended.id] = orgSuspended;

    // 1. Multi-organization Admin/Manager User (+15551234567)
    const user1 = AppUser(
      id: 'usr_alex_001',
      phoneNumber: '+15551234567',
      name: 'Alex Morgan',
      email: 'alex.morgan@workaxis.io',
      status: AccountStatus.active,
    );
    _usersByPhone[user1.phoneNumber] = user1;
    if (user1.email != null) _usersByEmail[user1.email!.toLowerCase()] = user1;
    _membershipsByUserId[user1.id] = [
      OrganizationMembership(
        id: 'mem_001',
        userId: user1.id,
        organizationId: org1.id,
        organization: org1,
        role: UserRole.orgAdmin,
        lastAccessedAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      OrganizationMembership(
        id: 'mem_002',
        userId: user1.id,
        organizationId: org2.id,
        organization: org2,
        role: UserRole.branchManager,
        branchId: 'br_salinas_main',
        branchName: 'Downtown Hub #102',
        lastAccessedAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      OrganizationMembership(
        id: 'mem_003',
        userId: user1.id,
        organizationId: org3.id,
        organization: org3,
        role: UserRole.employee,
        branchId: 'br_metro_south',
        branchName: 'South Warehouse #404',
        lastAccessedAt: DateTime.now().subtract(const Duration(days: 5)),
      ),
    ];

    // 2. Single-organization Employee (+15552345678) -> Should Auto Skip Selection
    const user2 = AppUser(
      id: 'usr_jordan_002',
      phoneNumber: '+15552345678',
      name: 'Jordan Lee',
      email: 'jordan.lee@workaxis.io',
      status: AccountStatus.active,
    );
    _usersByPhone[user2.phoneNumber] = user2;
    if (user2.email != null) _usersByEmail[user2.email!.toLowerCase()] = user2;
    _membershipsByUserId[user2.id] = [
      OrganizationMembership(
        id: 'mem_004',
        userId: user2.id,
        organizationId: org1.id,
        organization: org1,
        role: UserRole.employee,
        branchId: 'br_fresno_north',
        branchName: 'North Packhouse #12',
        lastAccessedAt: DateTime.now(),
      ),
    ];

    // 3. Employee without assigned branch (+15553456789) -> Routes to Branch Required
    const user3 = AppUser(
      id: 'usr_sam_003',
      phoneNumber: '+15553456789',
      name: 'Sam Rivera',
      status: AccountStatus.active,
    );
    _usersByPhone[user3.phoneNumber] = user3;
    _membershipsByUserId[user3.id] = [
      OrganizationMembership(
        id: 'mem_005',
        userId: user3.id,
        organizationId: org1.id,
        organization: org1,
        role: UserRole.employee,
        branchId: null,
        branchName: null,
        lastAccessedAt: DateTime.now(),
      ),
    ];

    // 4. Disabled User (+15554567890) -> Routes to Account Disabled
    const user4 = AppUser(
      id: 'usr_disabled_004',
      phoneNumber: '+15554567890',
      name: 'Disabled User',
      status: AccountStatus.disabled,
    );
    _usersByPhone[user4.phoneNumber] = user4;
    _membershipsByUserId[user4.id] = [];

    // 5. User with Suspended Org (+15558901234) -> Routes to Org Unavailable
    const user5 = AppUser(
      id: 'usr_pat_005',
      phoneNumber: '+15558901234',
      name: 'Pat Riley',
      status: AccountStatus.active,
    );
    _usersByPhone[user5.phoneNumber] = user5;
    _membershipsByUserId[user5.id] = [
      OrganizationMembership(
        id: 'mem_006',
        userId: user5.id,
        organizationId: orgSuspended.id,
        organization: orgSuspended,
        role: UserRole.employee,
        branchId: 'br_suspended_main',
        branchName: 'Bakersfield Dock #01',
        lastAccessedAt: DateTime.now(),
      ),
    ];

    // 6. Invitations:
    // Valid Pending Invite
    final invite1 = Invitation(
      id: 'inv_valid_001',
      organizationId: org1.id,
      organizationName: org1.name,
      invitedPhone: '+15556789012',
      invitedRole: UserRole.branchManager,
      branchId: 'br_fresno_west',
      branchName: 'West Gate Facility #08',
      invitedBy: 'Alex Morgan (Org Admin)',
      expiresAt: DateTime.now().add(const Duration(days: 7)),
      status: InvitationStatus.pending,
    );
    _invitationsById[invite1.id] = invite1;
    _invitationsByPhone[invite1.invitedPhone] = invite1.id;

    // Expired Invite
    final inviteExpired = Invitation(
      id: 'inv_expired_002',
      organizationId: org2.id,
      organizationName: org2.name,
      invitedPhone: '+15557890123',
      invitedRole: UserRole.employee,
      branchId: 'br_salinas_main',
      branchName: 'Downtown Hub #102',
      invitedBy: 'HR Operations',
      expiresAt: DateTime.now().subtract(const Duration(days: 1)),
      status: InvitationStatus.expired,
    );
    _invitationsById[inviteExpired.id] = inviteExpired;
    _invitationsByPhone[inviteExpired.invitedPhone] = inviteExpired.id;
  }

  @override
  Future<AppUser?> resolveUser({
    String? phoneNumber,
    String? email,
    String? uid,
  }) async {
    if (phoneNumber != null && phoneNumber.isNotEmpty) {
      final user = await resolveUserByPhone(phoneNumber);
      if (user != null) return user;
    }
    if (email != null && email.isNotEmpty) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
      final user = _usersByEmail[email.toLowerCase()];
      if (user != null) return user;
    }
    if (uid != null && uid.isNotEmpty) {
      for (final user in _usersByPhone.values) {
        if (user.id == uid) return user;
      }
    }
    return null;
  }

  @override
  Future<AppUser?> resolveUserByPhone(String phoneNumber) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final cleanDigits = phoneNumber.replaceAll(RegExp(r'\D'), '');

    for (final entry in _usersByPhone.entries) {
      final entryDigits = entry.key.replaceAll(RegExp(r'\D'), '');
      if (entryDigits == cleanDigits ||
          (cleanDigits.length >= 10 &&
              entryDigits.length >= 10 &&
              cleanDigits.substring(cleanDigits.length - 10) ==
                  entryDigits.substring(entryDigits.length - 10))) {
        return entry.value;
      }
    }
    return null;
  }

  @override
  Future<List<OrganizationMembership>> getMemberships(String userId) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return _membershipsByUserId[userId] ?? [];
  }

  @override
  Future<Invitation?> getPendingInvitationByPhone(String phoneNumber) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    final cleanDigits = phoneNumber.replaceAll(RegExp(r'\D'), '');

    for (final entry in _invitationsById.entries) {
      final entryDigits =
          entry.value.invitedPhone.replaceAll(RegExp(r'\D'), '');
      if (entryDigits == cleanDigits ||
          (cleanDigits.length >= 10 &&
              entryDigits.length >= 10 &&
              cleanDigits.substring(cleanDigits.length - 10) ==
                  entryDigits.substring(entryDigits.length - 10))) {
        return entry.value;
      }
    }
    return null;
  }

  @override
  Future<Invitation?> getInvitationById(String invitationId) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    return _invitationsById[invitationId];
  }

  @override
  Future<OrganizationMembership> acceptInvitation({
    required String invitationId,
    required String userId,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    final invite = _invitationsById[invitationId];
    if (invite == null || invite.isExpired) {
      throw AccessResolutionException.invitationExpired();
    }

    final org = _organizationsById[invite.organizationId] ??
        Organization(
          id: invite.organizationId,
          name: invite.organizationName,
          status: OrgStatus.active,
        );

    final newMembership = OrganizationMembership(
      id: 'mem_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      organizationId: org.id,
      organization: org,
      role: invite.invitedRole,
      branchId: invite.branchId,
      branchName: invite.branchName,
      status: MembershipStatus.active,
      lastAccessedAt: DateTime.now(),
    );

    final currentMemberships = _membershipsByUserId[userId] ?? [];
    _membershipsByUserId[userId] = [...currentMemberships, newMembership];
    _invitationsById.remove(invitationId);

    return newMembership;
  }

  @override
  Future<void> declineInvitation(String invitationId) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    _invitationsById.remove(invitationId);
  }

  @override
  Future<void> recordLastAccessedOrganization({
    required String userId,
    required String organizationId,
  }) async {
    final memberships = _membershipsByUserId[userId];
    if (memberships != null) {
      _membershipsByUserId[userId] = memberships.map((m) {
        if (m.organizationId == organizationId) {
          return m.copyWith(lastAccessedAt: DateTime.now());
        }
        return m;
      }).toList();
    }
  }

  @override
  Future<Organization?> getOrganization(String organizationId) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    return _organizationsById[organizationId];
  }
}
