import 'package:workaxis/features/access_control/data/datasources/access_remote_data_source.dart';
import 'package:workaxis/features/access_control/domain/entities/app_user.dart';
import 'package:workaxis/features/access_control/domain/entities/invitation.dart';
import 'package:workaxis/features/access_control/domain/entities/organization_membership.dart';
import 'package:workaxis/features/access_control/domain/repositories/access_repository.dart';

class AccessRepositoryImpl implements AccessRepository {
  AccessRepositoryImpl({required AccessRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  final AccessRemoteDataSource _remoteDataSource;

  @override
  Future<AppUser?> resolveUser({
    String? phoneNumber,
    String? email,
    String? uid,
  }) {
    return _remoteDataSource.resolveUser(
      phoneNumber: phoneNumber,
      email: email,
      uid: uid,
    );
  }

  @override
  Future<AppUser?> resolveUserByPhone(String phoneNumber) {
    return _remoteDataSource.resolveUserByPhone(phoneNumber);
  }

  @override
  Future<List<OrganizationMembership>> getMemberships(String userId) {
    return _remoteDataSource.getMemberships(userId);
  }

  @override
  Future<Invitation?> getPendingInvitationByPhone(String phoneNumber) {
    return _remoteDataSource.getPendingInvitationByPhone(phoneNumber);
  }

  @override
  Future<Invitation?> getInvitationById(String invitationId) {
    return _remoteDataSource.getInvitationById(invitationId);
  }

  @override
  Future<OrganizationMembership> acceptInvitation({
    required String invitationId,
    required String userId,
  }) {
    return _remoteDataSource.acceptInvitation(
      invitationId: invitationId,
      userId: userId,
    );
  }

  @override
  Future<void> declineInvitation(String invitationId) {
    return _remoteDataSource.declineInvitation(invitationId);
  }

  @override
  Future<void> recordLastAccessedOrganization({
    required String userId,
    required String organizationId,
  }) {
    return _remoteDataSource.recordLastAccessedOrganization(
      userId: userId,
      organizationId: organizationId,
    );
  }
}
