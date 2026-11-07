import 'package:workaxis/features/access/domain/models/active_branch_context.dart';
import 'package:workaxis/features/access/domain/models/branch_summary.dart';
import 'package:workaxis/features/access/domain/models/organization_summary.dart';
import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/authentication/domain/models/app_user.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';

/// Organization and branches shared with the mock backend fixtures.
const acmeOrg = OrganizationSummary(
  id: 'org-acme',
  name: 'Apex Logistics & Freight',
  code: 'HQ-001',
);

const otherOrg = OrganizationSummary(
  id: 'org-other',
  name: 'Other Org',
  code: 'OTH-001',
);

BranchSummary acmeBranch(String id, {bool isActive = true}) => BranchSummary(
  id: id,
  organizationId: acmeOrg.id,
  name: switch (id) {
    'br-01' => 'Downtown Flagship',
    'br-02' => 'Westside Hub',
    'br-04' => 'East Bay Outlet',
    _ => 'Branch $id',
  },
  code: id.toUpperCase(),
  location: 'City',
  isActive: isActive,
);

AppUser fixtureUser(
  UserRole role, {
  required String id,
  String name = 'Fixture User',
  String? organizationId = 'org-acme',
}) => AppUser(
  id: id,
  name: name,
  username: id,
  role: role,
  organizationId: role.isPlatformLevel ? null : organizationId,
);

/// Org Admin of [org] who sees every branch in [branchIds].
UserAccessContext orgAdminAccess({
  String id = 'user-oa-01',
  OrganizationSummary org = acmeOrg,
  List<String> branchIds = const ['br-01', 'br-02', 'br-04'],
}) => UserAccessContext(
  user: fixtureUser(
    UserRole.orgAdmin,
    id: id,
    name: 'Jordan Lee',
    organizationId: org.id,
  ),
  organization: org,
  assignedBranches: [for (final b in branchIds) acmeBranch(b)],
);

/// Branch Manager assigned to [branchIds] with [activeBranchId] selected.
UserAccessContext branchManagerAccess({
  String id = 'user-bm-01',
  List<String> branchIds = const ['br-01', 'br-02'],
  String? activeBranchId = 'br-01',
}) {
  final branches = [for (final b in branchIds) acmeBranch(b)];
  return UserAccessContext(
    user: fixtureUser(UserRole.branchManager, id: id, name: 'Marcus Chen'),
    organization: acmeOrg,
    assignedBranches: branches,
    activeBranch: activeBranchId == null
        ? null
        : ActiveBranchContext.fromBranch(
            branches.firstWhere((b) => b.id == activeBranchId),
          ),
  );
}

/// Employee of the Acme organization assigned to [branchId].
UserAccessContext employeeAccess({
  String id = 'user-emp-01',
  String name = 'Sarah Connor',
  String branchId = 'br-01',
}) {
  final branch = acmeBranch(branchId);
  return UserAccessContext(
    user: fixtureUser(UserRole.employee, id: id, name: name),
    organization: acmeOrg,
    assignedBranches: [branch],
    activeBranch: ActiveBranchContext.fromBranch(branch),
  );
}

UserAccessContext platformAccess({
  UserRole role = UserRole.platformOwner,
  String id = 'user-po-01',
}) => UserAccessContext(
  user: fixtureUser(role, id: id, name: 'Platform User'),
);
