import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/employees/domain/models/organization_member.dart';

/// Names of branches [member] is assigned to. Manager employee listings carry
/// these assignment names so staff with shared branch access can see the full
/// employee assignment list without receiving access to those other branches.
List<String> memberBranchNames(
  OrganizationMember member,
  UserAccessContext? access,
) {
  if (member.branchNamesById.isNotEmpty) {
    return [
      for (final name
          in member.branchIds
              .map((branchId) => member.branchNamesById[branchId])
              .whereType<String>())
        name,
    ];
  }
  return access?.assignedBranches
          .where((branch) => member.branchIds.contains(branch.id))
          .map((branch) => branch.name)
          .toList(growable: false) ??
      const [];
}
