import 'package:workaxis/core/pagination/page_result.dart';
import 'package:workaxis/features/authentication/domain/models/account_status.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';
import 'package:workaxis/features/employees/domain/models/organization_member.dart';

/// Remote member reads. Thin seam over SQL Connect so the repository can be
/// unit-tested with a fake. Filters are applied server-side.
abstract interface class OrganizationMembersRemoteDataSource {
  Future<PageResult<OrganizationMember>> listByOrganization({
    required String organizationId,
    required int limit,
    required int offset,
    String? nameContains,
    AccountStatus? status,
    UserRole? role,
  });

  Future<PageResult<OrganizationMember>> listByBranch({
    required String organizationId,
    required String branchId,
    required int limit,
    required int offset,
    String? nameContains,
    AccountStatus? status,
  });

  Future<OrganizationMember?> getById(String memberId);
}
