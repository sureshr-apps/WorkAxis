import 'package:workaxis/features/access/domain/models/branch_summary.dart';
import 'package:workaxis/features/access/domain/models/organization_summary.dart';
import 'package:workaxis/features/access/domain/models/access_user_summary.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';

/// In-memory mock data source for organizations and branch assignments.
class MockAccessDataSource {
  MockAccessDataSource() {
    _initData();
  }

  final Map<String, OrganizationSummary> _orgs = {};
  final Map<String, BranchSummary> _branches = {};
  final Map<String, List<String>> _userBranchAssignments = {};
  final Map<String, AccessUserSummary> _users = {};

  void _initData() {
    // Organizations
    const acmeOrg = OrganizationSummary(
      id: 'org-acme',
      name: 'Apex Logistics & Freight',
      code: 'HQ-001',
    );
    _orgs[acmeOrg.id] = acmeOrg;

    // Branches for Acme Retail Ltd
    final branches = <BranchSummary>[
      const BranchSummary(
        id: 'br-01',
        organizationId: 'org-acme',
        name: 'Downtown Flagship',
        code: 'BR-101',
        location: 'Metro Central',
        activeEmployeeCount: 28,
        isActive: true,
      ),
      const BranchSummary(
        id: 'br-02',
        organizationId: 'org-acme',
        name: 'Westside Hub',
        code: 'BR-102',
        location: 'West District',
        activeEmployeeCount: 14,
        isActive: true,
      ),
      const BranchSummary(
        id: 'br-03',
        organizationId: 'org-acme',
        name: 'North Logistics Center',
        code: 'BR-103',
        location: 'Industrial Park',
        activeEmployeeCount: 0,
        isActive: false, // Inactive / under maintenance
      ),
      const BranchSummary(
        id: 'br-04',
        organizationId: 'org-acme',
        name: 'East Bay Outlet',
        code: 'BR-104',
        location: 'East District',
        activeEmployeeCount: 19,
        isActive: true,
      ),
    ];

    for (final b in branches) {
      _branches[b.id] = b;
    }

    // Branch assignments:
    // Marcus Chen (manager_multi): assigned to 3 branches (2 active, 1 inactive)
    _userBranchAssignments['user-bm-multi-01'] = ['br-01', 'br-02', 'br-03'];
    _users['user-bm-multi-01'] = const AccessUserSummary(
      id: 'user-bm-multi-01',
      organizationId: 'org-acme',
      fullName: 'Marcus Chen',
      role: UserRole.branchManager,
    );

    // Sophia Patel (manager_single): assigned to 1 branch
    _userBranchAssignments['user-bm-single-01'] = ['br-04'];
    _users['user-bm-single-01'] = const AccessUserSummary(
      id: 'user-bm-single-01',
      organizationId: 'org-acme',
      fullName: 'Sophia Patel',
      role: UserRole.branchManager,
    );

    // Sarah Connor (employee): assigned to 1 branch
    _userBranchAssignments['user-emp-01'] = ['br-01'];
    _users['user-emp-01'] = const AccessUserSummary(
      id: 'user-emp-01',
      organizationId: 'org-acme',
      fullName: 'Sarah Connor',
      role: UserRole.employee,
    );

    // Organization Admin has visibility over all branches in the org
    _userBranchAssignments['user-oa-01'] = ['br-01', 'br-02', 'br-03', 'br-04'];
    _users['user-oa-01'] = const AccessUserSummary(
      id: 'user-oa-01',
      organizationId: 'org-acme',
      fullName: 'Jordan Lee',
      role: UserRole.orgAdmin,
    );
  }

  OrganizationSummary? getOrganization(String orgId) => _orgs[orgId];

  BranchSummary? getBranch(String branchId) => _branches[branchId];

  List<BranchSummary> getBranchesForOrganization(String organizationId) =>
      _branches.values
          .where((branch) => branch.organizationId == organizationId)
          .toList(growable: false);

  List<BranchSummary> getAllBranches() => _branches.values.toList();

  void saveBranch(BranchSummary branch) => _branches[branch.id] = branch;

  List<String> getAssignedBranchIds(String userId) =>
      List.unmodifiable(_userBranchAssignments[userId] ?? const []);

  void setAssignedBranchIds(String userId, List<String> branchIds) {
    _userBranchAssignments[userId] = List.of(branchIds);
  }

  Set<String> get knownUserIds => {
    ..._userBranchAssignments.keys,
    ..._users.keys,
  };

  List<AccessUserSummary> getUsersWithRole(
    UserRole role,
    String organizationId,
  ) => _users.values
      .where(
        (user) => user.role == role && user.organizationId == organizationId,
      )
      .toList(growable: false);

  void saveUserAccessProfile(AccessUserSummary user) => _users[user.id] = user;

  List<BranchSummary> getAssignedBranchesForUser(String userId) {
    final branchIds = _userBranchAssignments[userId] ?? const [];
    return branchIds
        .map((id) => _branches[id])
        .whereType<BranchSummary>()
        .toList();
  }
}
