import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:workaxis/features/access_control/data/datasources/access_remote_data_source.dart';
import 'package:workaxis/features/access_control/domain/entities/app_user.dart';
import 'package:workaxis/features/access_control/domain/entities/invitation.dart';
import 'package:workaxis/features/access_control/domain/entities/organization.dart';
import 'package:workaxis/features/access_control/domain/entities/organization_membership.dart';
import 'package:workaxis/features/access_control/domain/entities/user_role.dart';

/// Production implementation of [AccessRemoteDataSource] backed by Cloud Firestore.
/// Validates users against the `users` collection and resolves organization roles/memberships.
class FirestoreAccessDataSource implements AccessRemoteDataSource {
  FirestoreAccessDataSource({FirebaseFirestore? firestore})
      : _customFirestore = firestore;

  final FirebaseFirestore? _customFirestore;
  FirebaseFirestore get _firestore =>
      _customFirestore ?? FirebaseFirestore.instance;

  @override
  Future<AppUser?> resolveUser({
    String? phoneNumber,
    String? email,
    String? uid,
  }) async {
    try {
      DocumentSnapshot<Map<String, dynamic>>? userDoc;

      // 1. Try finding by phone number
      if (phoneNumber != null && phoneNumber.trim().isNotEmpty) {
        final cleanPhone = phoneNumber.replaceAll(RegExp(r'\D'), '');

        // Query by standard phoneNumber field
        var snapshot = await _firestore
            .collection('users')
            .where('phoneNumber', isEqualTo: phoneNumber)
            .limit(1)
            .get();

        if (snapshot.docs.isEmpty && cleanPhone.isNotEmpty) {
          snapshot = await _firestore
              .collection('users')
              .where('phoneNumber', isEqualTo: cleanPhone)
              .limit(1)
              .get();
        }

        if (snapshot.docs.isEmpty && cleanPhone.isNotEmpty) {
          snapshot = await _firestore
              .collection('users')
              .where('phoneNumber', isEqualTo: '+$cleanPhone')
              .limit(1)
              .get();
        }

        if (snapshot.docs.isEmpty && cleanPhone.isNotEmpty) {
          snapshot = await _firestore
              .collection('users')
              .where('mobile', isEqualTo: cleanPhone)
              .limit(1)
              .get();
        }

        // Direct document ID lookup by phone
        if (snapshot.docs.isEmpty) {
          final doc =
              await _firestore.collection('users').doc(cleanPhone).get();
          if (doc.exists) userDoc = doc;
        } else {
          userDoc = snapshot.docs.first;
        }
      }

      // 2. Try finding by email (if not found by phone)
      if (userDoc == null && email != null && email.trim().isNotEmpty) {
        final cleanEmail = email.trim().toLowerCase();
        final snapshot = await _firestore
            .collection('users')
            .where('email', isEqualTo: cleanEmail)
            .limit(1)
            .get();

        if (snapshot.docs.isNotEmpty) {
          userDoc = snapshot.docs.first;
        }
      }

      // 3. Try finding by document UID
      if (userDoc == null && uid != null && uid.trim().isNotEmpty) {
        final doc = await _firestore.collection('users').doc(uid).get();
        if (doc.exists) {
          userDoc = doc;
        }
      }

      if (userDoc == null || !userDoc.exists) {
        return null;
      }

      final data = userDoc.data() ?? {};
      final statusStr = (data['status'] as String? ?? 'active').toLowerCase();
      final status = statusStr == 'disabled'
          ? AccountStatus.disabled
          : (statusStr == 'pending'
              ? AccountStatus.pending
              : AccountStatus.active);

      return AppUser(
        id: userDoc.id,
        phoneNumber: data['phoneNumber'] as String? ??
            data['mobile'] as String? ??
            (phoneNumber ?? ''),
        name: data['name'] as String? ?? data['displayName'] as String?,
        email: data['email'] as String? ?? email,
        status: status,
        createdAt: (data['createdAt'] is Timestamp)
            ? (data['createdAt'] as Timestamp).toDate()
            : null,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<AppUser?> resolveUserByPhone(String phoneNumber) {
    return resolveUser(phoneNumber: phoneNumber);
  }

  @override
  Future<List<OrganizationMembership>> getMemberships(String userId) async {
    try {
      final memberships = <OrganizationMembership>[];

      // 1. Check memberships collection
      final memSnapshot = await _firestore
          .collection('memberships')
          .where('userId', isEqualTo: userId)
          .get();

      for (final doc in memSnapshot.docs) {
        final data = doc.data();
        final orgId = data['organizationId'] as String? ?? '';
        if (orgId.isEmpty) continue;

        final org = await getOrganization(orgId) ??
            Organization(
              id: orgId,
              name: data['organizationName'] as String? ?? 'Organization',
              code: data['organizationCode'] as String? ?? 'ORG',
              status: OrgStatus.active,
            );

        memberships.add(
          OrganizationMembership(
            id: doc.id,
            userId: userId,
            organizationId: orgId,
            organization: org,
            role: UserRole.fromString(data['role'] as String? ?? 'employee'),
            branchId: data['branchId'] as String?,
            branchName: data['branchName'] as String?,
            status: data['status'] == 'suspended'
                ? MembershipStatus.suspended
                : MembershipStatus.active,
          ),
        );
      }

      if (memberships.isNotEmpty) return memberships;

      // 2. Fallback: Check if user doc itself contains organization & role info
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        final data = userDoc.data() ?? {};
        final roleStr = data['role'] as String? ?? 'employee';
        final orgId = data['organizationId'] as String? ??
            data['orgId'] as String? ??
            'default_org';
        final orgName = data['organizationName'] as String? ??
            data['orgName'] as String? ??
            'WorkAxis Organization';

        final org = await getOrganization(orgId) ??
            Organization(
              id: orgId,
              name: orgName,
              code: 'WAX',
              status: OrgStatus.active,
            );

        memberships.add(
          OrganizationMembership(
            id: 'mem_$userId',
            userId: userId,
            organizationId: orgId,
            organization: org,
            role: UserRole.fromString(roleStr),
            branchId: data['branchId'] as String? ??
                data['assignedBranchId'] as String?,
            branchName: data['branchName'] as String?,
            status: MembershipStatus.active,
          ),
        );
      }

      return memberships;
    } catch (_) {
      return [];
    }
  }

  @override
  Future<Invitation?> getPendingInvitationByPhone(String phoneNumber) async {
    try {
      final cleanPhone = phoneNumber.replaceAll(RegExp(r'\D'), '');
      var snapshot = await _firestore
          .collection('invitations')
          .where('invitedPhone', isEqualTo: phoneNumber)
          .where('status', isEqualTo: 'pending')
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty && cleanPhone.isNotEmpty) {
        snapshot = await _firestore
            .collection('invitations')
            .where('invitedPhone', isEqualTo: cleanPhone)
            .where('status', isEqualTo: 'pending')
            .limit(1)
            .get();
      }

      if (snapshot.docs.isEmpty) return null;

      final doc = snapshot.docs.first;
      final data = doc.data();
      final orgId = data['organizationId'] as String? ?? '';
      final orgName = data['organizationName'] as String? ?? 'Organization';

      return Invitation(
        id: doc.id,
        organizationId: orgId,
        organizationName: orgName,
        invitedPhone: data['invitedPhone'] as String? ?? phoneNumber,
        invitedRole:
            UserRole.fromString(data['invitedRole'] as String? ?? 'employee'),
        branchId: data['branchId'] as String?,
        branchName: data['branchName'] as String?,
        invitedBy: data['inviterName'] as String? ?? 'Administrator',
        expiresAt: (data['expiresAt'] is Timestamp)
            ? (data['expiresAt'] as Timestamp).toDate()
            : DateTime.now().add(const Duration(days: 7)),
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Invitation?> getInvitationById(String invitationId) async {
    try {
      final doc =
          await _firestore.collection('invitations').doc(invitationId).get();
      if (!doc.exists) return null;
      final data = doc.data() ?? {};
      final orgId = data['organizationId'] as String? ?? '';
      final orgName = data['organizationName'] as String? ?? 'Organization';

      return Invitation(
        id: doc.id,
        organizationId: orgId,
        organizationName: orgName,
        invitedPhone: data['invitedPhone'] as String? ?? '',
        invitedRole:
            UserRole.fromString(data['invitedRole'] as String? ?? 'employee'),
        branchId: data['branchId'] as String?,
        branchName: data['branchName'] as String?,
        invitedBy: data['inviterName'] as String? ?? 'Administrator',
        expiresAt: (data['expiresAt'] is Timestamp)
            ? (data['expiresAt'] as Timestamp).toDate()
            : DateTime.now().add(const Duration(days: 7)),
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<OrganizationMembership> acceptInvitation({
    required String invitationId,
    required String userId,
  }) async {
    final invite = await getInvitationById(invitationId);
    if (invite == null) {
      throw Exception('Invitation not found');
    }

    final org = await getOrganization(invite.organizationId) ??
        Organization(
          id: invite.organizationId,
          name: invite.organizationName,
          code: 'INV',
          status: OrgStatus.active,
        );

    final memRef = _firestore.collection('memberships').doc();
    final mem = OrganizationMembership(
      id: memRef.id,
      userId: userId,
      organizationId: invite.organizationId,
      organization: org,
      role: invite.invitedRole,
      branchId: invite.branchId,
      branchName: invite.branchName,
      status: MembershipStatus.active,
      lastAccessedAt: DateTime.now(),
    );

    await memRef.set({
      'userId': userId,
      'organizationId': invite.organizationId,
      'organizationName': invite.organizationName,
      'role': invite.invitedRole.name,
      'branchId': invite.branchId,
      'branchName': invite.branchName,
      'status': 'active',
      'createdAt': FieldValue.serverTimestamp(),
    });

    await _firestore.collection('invitations').doc(invitationId).update({
      'status': 'accepted',
      'acceptedAt': FieldValue.serverTimestamp(),
      'acceptedBy': userId,
    });

    return mem;
  }

  @override
  Future<void> declineInvitation(String invitationId) async {
    await _firestore.collection('invitations').doc(invitationId).update({
      'status': 'declined',
      'declinedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> recordLastAccessedOrganization({
    required String userId,
    required String organizationId,
  }) async {
    try {
      await _firestore.collection('users').doc(userId).set({
        'lastAccessedOrganizationId': organizationId,
        'lastActiveAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  @override
  Future<Organization?> getOrganization(String organizationId) async {
    try {
      final doc = await _firestore
          .collection('organizations')
          .doc(organizationId)
          .get();
      if (!doc.exists) return null;
      final data = doc.data() ?? {};
      final statusStr = (data['status'] as String? ?? 'active').toLowerCase();

      return Organization(
        id: doc.id,
        name: data['name'] as String? ?? 'Organization',
        code: data['code'] as String? ?? 'ORG',
        status:
            statusStr == 'suspended' ? OrgStatus.suspended : OrgStatus.active,
        address: data['address'] as String?,
      );
    } catch (_) {
      return null;
    }
  }
}
