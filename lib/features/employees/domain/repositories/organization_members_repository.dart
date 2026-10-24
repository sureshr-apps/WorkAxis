import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/employees/domain/models/organization_member.dart';

abstract interface class OrganizationMembersRepository {
  Future<List<OrganizationMember>> getMembers({
    required UserAccessContext access,
    String? activeBranchId,
    String? query,
  });
  Future<OrganizationMember?> getMember({
    required UserAccessContext access,
    required String memberId,
    String? activeBranchId,
  });
  Future<OrganizationMember> saveMember({
    required UserAccessContext access,
    required OrganizationMember member,
    required String initialPassword,
    String? activeBranchId,
  });
}
