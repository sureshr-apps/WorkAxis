import 'package:workaxis/features/access/data/access_remote_data_source.dart';
import 'package:workaxis/features/access/data/mock_access_data_source.dart';
import 'package:workaxis/features/access/domain/models/access_member_record.dart';
import 'package:workaxis/features/access/domain/models/branch_summary.dart';
import 'package:workaxis/features/authentication/domain/models/account_status.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';

/// [AccessRemoteDataSource] answering from [MockAccessDataSource] facts, as
/// the signed-in user [currentUserId]. Mirrors what the SQL queries return:
/// assignments are active-only and the member row comes from the profile.
class FakeAccessRemoteDataSource implements AccessRemoteDataSource {
  FakeAccessRemoteDataSource(
    this.facts, {
    required this.currentUserId,
    this.memberStatus = AccountStatus.active,
    this.roleOverride,
    this.noMember = false,
    this.failWith,
  });

  final MockAccessDataSource facts;
  final String currentUserId;
  AccountStatus? memberStatus;
  UserRole? roleOverride;
  bool noMember;
  Object? failWith;

  static const _platformRoles = {
    'user-po-01': UserRole.platformOwner,
    'user-pa-01': UserRole.platformAdmin,
  };

  void _maybeFail() {
    final f = failWith;
    if (f != null) throw f;
  }

  @override
  Future<AccessMemberRecord?> fetchMyMember() async {
    _maybeFail();
    if (noMember) return null;
    final platformRole = _platformRoles[currentUserId];
    if (platformRole != null) {
      return AccessMemberRecord(
        memberId: 'sql-$currentUserId',
        authUid: currentUserId,
        role: roleOverride ?? platformRole,
        status: memberStatus,
      );
    }
    final profile = facts.getUserProfile(currentUserId);
    if (profile == null) return null;
    return AccessMemberRecord(
      memberId: 'sql-$currentUserId',
      authUid: currentUserId,
      role: roleOverride ?? profile.role,
      status: memberStatus,
      organization: facts.getOrganization(profile.organizationId),
    );
  }

  @override
  Future<List<BranchSummary>> fetchMyAssignedBranches() async {
    _maybeFail();
    return facts
        .getAssignedBranchesForUser(currentUserId)
        .where((b) => b.isActive)
        .toList();
  }

  @override
  Future<List<BranchSummary>> fetchOrganizationBranches(
    String organizationId,
  ) async {
    _maybeFail();
    return facts.getBranchesForOrganization(organizationId);
  }
}
