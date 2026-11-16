import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/employees/domain/models/organization_member.dart';

/// Names of the branches [member] is assigned to, limited to the branches the
/// viewer can see. Shared by the directory tile and the employee details page.
List<String> memberBranchNames(
  OrganizationMember member,
  UserAccessContext? access,
) =>
    access?.assignedBranches
        .where((branch) => member.branchIds.contains(branch.id))
        .map((branch) => branch.name)
        .toList(growable: false) ??
    const [];
