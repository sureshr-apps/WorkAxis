import 'package:workaxis/core/pagination/page_result.dart';
import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/authentication/domain/models/account_status.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';
import 'package:workaxis/features/employees/domain/models/organization_member.dart';

/// Account management for customer-organization members.
///
/// Reads are scoped server-side (organization-wide for Organization Admins,
/// active-branch for Branch Managers) and paginated. Writes go through
/// trusted callables; the repository never trusts the UI to restrict roles
/// or branches (see `OrganizationMemberPolicy`).
abstract interface class OrganizationMembersRepository {
  Future<PageResult<OrganizationMember>> getMembersPage({
    required UserAccessContext access,
    String? activeBranchId,
    String? query,
    AccountStatus? status,
    UserRole? role,
    int offset = 0,
    int limit = defaultPageSize,
  });

  Future<OrganizationMember?> getMember({
    required UserAccessContext access,
    required String memberId,
    String? activeBranchId,
  });

  /// Creates (empty `member.id`) or updates an account and returns what the
  /// server saved. [initialPassword] is used on create only.
  Future<OrganizationMember> saveMember({
    required UserAccessContext access,
    required OrganizationMember member,
    required String initialPassword,
    String? activeBranchId,
  });

  /// Suspends or restores an account.
  Future<OrganizationMember> setMemberStatus({
    required UserAccessContext access,
    required OrganizationMember member,
    required AccountStatus status,
    String? activeBranchId,
  });

  /// Sets a new password for an account the caller may manage.
  Future<void> resetMemberPassword({
    required UserAccessContext access,
    required OrganizationMember member,
    required String newPassword,
    String? activeBranchId,
  });
}

/// Convenience for flows that need every account of a scope (for example
/// picking employees for a group check-in). Pages through the server results,
/// capped at [maxItems] so a huge organization cannot be downloaded wholesale.
extension OrganizationMembersRepositoryAll on OrganizationMembersRepository {
  Future<List<OrganizationMember>> getMembers({
    required UserAccessContext access,
    String? activeBranchId,
    String? query,
    int maxItems = 500,
  }) async {
    final all = <OrganizationMember>[];
    var offset = 0;
    while (all.length < maxItems) {
      final page = await getMembersPage(
        access: access,
        activeBranchId: activeBranchId,
        query: query,
        offset: offset,
        limit: 100,
      );
      all.addAll(page.items);
      if (!page.hasMore) break;
      offset = page.nextOffset;
    }
    return all;
  }
}
