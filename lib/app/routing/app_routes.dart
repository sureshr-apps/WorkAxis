/// Centralized route constants for WorkAxis.
abstract final class AppRoutes {
  static const String signIn = '/signin';
  static const String verifyAccess = '/verify-access';
  static const String selectBranch = '/select-branch';
  static const String noBranchAssigned = '/no-branch-assigned';
  static const String splash = '/initializing';

  // Platform destinations
  static const String platformWorkspace = '/platform';
  static const String platformOrganizations = '/platform/organizations';
  static const String platformOrganizationsAdd = '/platform/organizations/add';
  static const String platformOrganizationDetails =
      '/platform/organizations/:id';
  static const String platformOrganizationEdit =
      '/platform/organizations/:id/edit';

  static String platformOrganizationDetailsPath(String id) =>
      '/platform/organizations/$id';
  static String platformOrganizationEditPath(String id) =>
      '/platform/organizations/$id/edit';

  static const String platformPlans = '/platform/plans';
  static const String platformPlansAdd = '/platform/plans/add';
  static const String platformPlanEdit = '/platform/plans/:id/edit';

  static String platformPlanEditPath(String id) => '/platform/plans/$id/edit';

  static const String platformUsers = '/platform/users';
  static const String platformUsersAdd = '/platform/users/add';
  static const String platformUserDetails = '/platform/users/:id';
  static const String platformUserEdit = '/platform/users/:id/edit';

  static String platformUserDetailsPath(String id) => '/platform/users/$id';
  static String platformUserEditPath(String id) => '/platform/users/$id/edit';
  static const String platformSettings = '/platform/settings';

  // Organization Admin destinations
  static const String orgAdminWorkspace = '/organization';
  static const String orgAdminBranches = '/organization/branches';
  static const String orgAdminEmployees = '/organization/employees';
  static const String orgAdminAttendance = '/organization/attendance';
  static const String orgAdminReturns = '/organization/returns';
  static const String orgAdminReports = '/organization/reports';
  static const String orgAdminSettings = '/organization/settings';

  static String orgAdminBranchDetailsPath(String id) =>
      '/organization/branches/$id';
  static const String orgAdminBranchAddPath = '/organization/branches/add';
  static String orgAdminBranchEditPath(String id) =>
      '/organization/branches/$id/edit';
  static String orgAdminEmployeeDetailsPath(String id) =>
      '/organization/employees/$id';
  static const String orgAdminEmployeeAddPath = '/organization/employees/add';
  static String orgAdminEmployeeEditPath(String id) =>
      '/organization/employees/$id/edit';

  // Branch Manager destinations
  static const String branchManagerWorkspace = '/branch-manager';
  static const String branchManagerEmployees = '/branch-manager/employees';
  static const String branchManagerAttendance = '/branch-manager/attendance';
  static const String branchManagerReturns = '/branch-manager/returns';
  static const String branchManagerReports = '/branch-manager/reports';

  static String branchManagerEmployeeDetailsPath(String id) =>
      '/branch-manager/employees/$id';
  static const String branchManagerEmployeeAddPath =
      '/branch-manager/employees/add';
  static String branchManagerEmployeeEditPath(String id) =>
      '/branch-manager/employees/$id/edit';

  // Employee destinations
  static const String employeeWorkspace = '/employee';
  static const String employeeAttendance = '/employee/attendance';
  static const String employeeReturns = '/employee/returns';
  static const String employeeProfile = '/employee/profile';
}
