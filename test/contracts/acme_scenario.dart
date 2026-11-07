import 'package:workaxis/features/access/domain/models/active_branch_context.dart';
import 'package:workaxis/features/access/domain/models/branch_summary.dart';
import 'package:workaxis/features/access/domain/models/organization_summary.dart';
import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/authentication/domain/models/account_status.dart';
import 'package:workaxis/features/authentication/domain/models/app_user.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';
import 'package:workaxis/features/employees/domain/models/organization_member.dart';

/// Shared scenario for the contract suites. It mirrors the mock fixtures
/// (`MockAccessDataSource`, `MockOrganizationMembersRepository`) so that mock
/// and production implementations can be exercised with identical facts.
const acmeOrganization = OrganizationSummary(
  id: 'org-acme',
  name: 'Apex Logistics & Freight',
  code: 'HQ-001',
);

BranchSummary acmeBranch(String id, {bool isActive = true}) => BranchSummary(
  id: id,
  organizationId: 'org-acme',
  name: 'Branch $id',
  code: id.toUpperCase(),
  location: 'Somewhere',
  isActive: isActive,
);

AppUser acmeUser(String id, UserRole role, {AccountStatus? status}) => AppUser(
  id: id,
  name: id,
  username: id,
  role: role,
  organizationId: role.isPlatformLevel ? null : 'org-acme',
  status: status ?? AccountStatus.active,
);

/// Organization Admin with every active Acme branch in scope.
UserAccessContext orgAdminAccess() => UserAccessContext(
  user: acmeUser('user-oa-01', UserRole.orgAdmin),
  organization: acmeOrganization,
  assignedBranches: [
    acmeBranch('br-01'),
    acmeBranch('br-02'),
    acmeBranch('br-04'),
  ],
);

/// Branch Manager assigned to [branchIds] working in [activeBranchId].
UserAccessContext branchManagerAccess({
  String userId = 'user-bm-multi-01',
  List<String> branchIds = const ['br-01', 'br-02'],
  String? activeBranchId = 'br-01',
}) {
  final branches = branchIds.map(acmeBranch).toList();
  return UserAccessContext(
    user: acmeUser(userId, UserRole.branchManager),
    organization: acmeOrganization,
    assignedBranches: branches,
    activeBranch: activeBranchId == null
        ? null
        : ActiveBranchContext.fromBranch(acmeBranch(activeBranchId)),
  );
}

UserAccessContext employeeAccess() => UserAccessContext(
  user: acmeUser('user-emp-01', UserRole.employee),
  organization: acmeOrganization,
  assignedBranches: [acmeBranch('br-01')],
  activeBranch: ActiveBranchContext.fromBranch(acmeBranch('br-01')),
);

UserAccessContext platformOwnerAccess() =>
    UserAccessContext(user: acmeUser('user-po-01', UserRole.platformOwner));

OrganizationMember _member(
  String id,
  String name,
  UserRole role,
  List<String> branches, {
  AccountStatus status = AccountStatus.active,
  String? phone,
}) => OrganizationMember(
  id: id,
  authUid: id,
  organizationId: 'org-acme',
  fullName: name,
  username: name.toLowerCase().replaceAll(' ', '.'),
  email: '${name.toLowerCase().replaceAll(' ', '.')}@example.com',
  phone: phone,
  role: role,
  branchIds: branches,
  status: status,
);

/// The six Acme members seeded by `MockOrganizationMembersRepository`.
List<OrganizationMember> acmeMemberSeed() => [
  _member('user-bm-multi-01', 'Marcus Chen', UserRole.branchManager, [
    'br-01',
    'br-02',
    'br-03',
  ]),
  _member('user-bm-single-01', 'Sophia Patel', UserRole.branchManager, [
    'br-04',
  ]),
  _member('user-emp-01', 'Sarah Connor', UserRole.employee, [
    'br-01',
  ], phone: '+12125550114'),
  _member('user-emp-02', 'Alex Chen', UserRole.employee, [
    'br-01',
  ], phone: '+12125550182'),
  _member('user-emp-03', 'Priya Shah', UserRole.employee, [
    'br-02',
  ], phone: '+12125550148'),
  _member(
    'user-emp-04',
    'Daniel Kim',
    UserRole.employee,
    ['br-04'],
    status: AccountStatus.suspended,
    phone: '+12125550193',
  ),
];

/// A new-account draft for [role] in [branches].
OrganizationMember memberDraft({
  String username = 'new.person',
  String fullName = 'New Person',
  String email = '',
  String? phone,
  UserRole role = UserRole.employee,
  List<String> branches = const ['br-02'],
}) => OrganizationMember(
  id: '',
  organizationId: 'org-acme',
  fullName: fullName,
  username: username,
  email: email,
  phone: phone,
  role: role,
  branchIds: branches,
  status: AccountStatus.active,
);
