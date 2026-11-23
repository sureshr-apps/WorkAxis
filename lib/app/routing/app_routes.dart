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
  static String platformUserResetPasswordPath(String id) =>
      '/platform/users/$id/reset-password';

  static String platformOrganizationAdminAddPath(String orgId) =>
      '/platform/organizations/$orgId/administrators/add';
  static String platformOrganizationAdminEditPath(
    String orgId,
    String adminId,
  ) => '/platform/organizations/$orgId/administrators/$adminId/edit';
  static String platformOrganizationAdminPasswordPath(
    String orgId,
    String adminId,
  ) => '/platform/organizations/$orgId/administrators/$adminId/password';
  static String platformOrganizationLicensePath(String orgId, String action) =>
      '/platform/organizations/$orgId/license/$action';
  static const String platformSettings = '/platform/settings';

  // Organization Admin destinations
  static const String orgAdminWorkspace = '/organization';
  static const String orgAdminBranches = '/organization/branches';
  static const String orgAdminEmployees = '/organization/employees';
  static const String orgAdminAssets = '/organization/assets';
  static const String orgAdminAttendance = '/organization/attendance';
  static const String orgAdminReturns = '/organization/returns';
  static String orgAdminReturnDetailsPath(String id) =>
      '/organization/returns/$id';
  static const String orgAdminAttendanceGroupPath =
      '/organization/attendance/group';
  static String orgAdminAttendanceDetailsPath(String id) =>
      '/organization/attendance/$id';
  static const String orgAdminReports = '/organization/reports';
  static const String orgAdminPayslips = '/organization/payslips';
  static const String orgAdminLeaves = '/organization/leaves';
  static const String orgAdminOffSiteWork = '/organization/off-site-work';
  static String orgAdminOffSiteWorkDetailsPath(String id) =>
      '/organization/off-site-work/$id';
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
  static const String branchManagerAssets = '/branch-manager/assets';
  static const String branchManagerAttendance = '/branch-manager/attendance';
  static const String branchManagerReturns = '/branch-manager/returns';
  static const String branchManagerReports = '/branch-manager/reports';
  static const String branchManagerPayslips = '/branch-manager/payslips';
  static const String branchManagerLeaves = '/branch-manager/leaves';
  static const String branchManagerOffSiteWork =
      '/branch-manager/off-site-work';
  static String branchManagerOffSiteWorkDetailsPath(String id) =>
      '/branch-manager/off-site-work/$id';

  static String branchManagerEmployeeDetailsPath(String id) =>
      '/branch-manager/employees/$id';
  static const String branchManagerEmployeeAddPath =
      '/branch-manager/employees/add';
  static String branchManagerEmployeeEditPath(String id) =>
      '/branch-manager/employees/$id/edit';
  static const String branchManagerReturnAddPath =
      '/branch-manager/returns/add';
  static String branchManagerReturnDetailsPath(String id) =>
      '/branch-manager/returns/$id';
  static String branchManagerReturnEditPath(String id) =>
      '/branch-manager/returns/$id/edit';
  static const String branchManagerAttendanceGroupPath =
      '/branch-manager/attendance/group';
  static String branchManagerAttendanceDetailsPath(String id) =>
      '/branch-manager/attendance/$id';

  // Employee destinations
  static const String employeeWorkspace = '/employee';
  static const String employeeAttendance = '/employee/attendance';
  static const String employeePayslips = '/employee/payslips';
  static const String employeeReturns = '/employee/returns';
  static const String employeeProfile = '/employee/profile';
  static const String employeeAssets = '/employee/assets';
  static const String employeeLeaves = '/employee/leaves';
  static const String employeeOffSiteWork = '/employee/off-site-work';
  static String employeeOffSiteWorkDetailsPath(String id) =>
      '/employee/off-site-work/$id';
  static const String employeeReturnAddPath = '/employee/returns/add';
  static String employeeReturnDetailsPath(String id) => '/employee/returns/$id';
  static String employeeReturnEditPath(String id) =>
      '/employee/returns/$id/edit';
  static String employeeAttendanceDetailsPath(String id) =>
      '/employee/attendance/$id';
}
