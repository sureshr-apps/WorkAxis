import 'package:flutter/material.dart';
import 'package:workaxis/app/routing/app_routes.dart';
import 'package:workaxis/app/shell/nav_destination.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';

/// Navigation destinations shown by the shell for each role area.
///
/// Kept out of the router so route wiring and navigation content change
/// independently.
abstract final class RoleDestinations {
  static List<AppNavDestination> platform({required bool isOwner}) => [
    const AppNavDestination(
      label: 'Home',
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard,
      route: AppRoutes.platformWorkspace,
    ),
    const AppNavDestination(
      label: 'Organizations',
      icon: Icons.business_outlined,
      selectedIcon: Icons.business,
      route: AppRoutes.platformOrganizations,
    ),
    if (isOwner)
      const AppNavDestination(
        label: 'Platform Users',
        icon: Icons.admin_panel_settings_outlined,
        selectedIcon: Icons.admin_panel_settings,
        route: AppRoutes.platformUsers,
      ),
    const AppNavDestination(
      label: 'Settings',
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings,
      route: AppRoutes.platformSettings,
    ),
  ];

  static const List<AppNavDestination> organizationAdmin = [
    AppNavDestination(
      label: 'Home',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home,
      route: AppRoutes.orgAdminWorkspace,
    ),
    AppNavDestination(
      label: 'Branches',
      icon: Icons.store_outlined,
      selectedIcon: Icons.store,
      route: AppRoutes.orgAdminBranches,
    ),
    AppNavDestination(
      label: 'Employees',
      icon: Icons.badge_outlined,
      selectedIcon: Icons.badge,
      route: AppRoutes.orgAdminEmployees,
    ),
    AppNavDestination(
      label: 'Attendance',
      icon: Icons.event_available_outlined,
      selectedIcon: Icons.event_available,
      route: AppRoutes.orgAdminAttendance,
    ),
    AppNavDestination(
      label: 'Returns',
      icon: Icons.assignment_return_outlined,
      selectedIcon: Icons.assignment_return,
      route: AppRoutes.orgAdminReturns,
    ),
    AppNavDestination(
      label: 'Reports',
      icon: Icons.analytics_outlined,
      selectedIcon: Icons.analytics,
      route: AppRoutes.orgAdminReports,
    ),
    AppNavDestination(
      label: 'Settings',
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings,
      route: AppRoutes.orgAdminSettings,
    ),
  ];

  static const List<AppNavDestination> branchManager = [
    AppNavDestination(
      label: 'Home',
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard,
      route: AppRoutes.branchManagerWorkspace,
    ),
    AppNavDestination(
      label: 'Employees',
      icon: Icons.badge_outlined,
      selectedIcon: Icons.badge,
      route: AppRoutes.branchManagerEmployees,
    ),
    AppNavDestination(
      label: 'Attendance',
      icon: Icons.access_time_outlined,
      selectedIcon: Icons.access_time_filled,
      route: AppRoutes.branchManagerAttendance,
    ),
    AppNavDestination(
      label: 'Returns',
      icon: Icons.assignment_return_outlined,
      selectedIcon: Icons.assignment_return,
      route: AppRoutes.branchManagerReturns,
    ),
    AppNavDestination(
      label: 'Reports',
      icon: Icons.assessment_outlined,
      selectedIcon: Icons.assessment,
      route: AppRoutes.branchManagerReports,
    ),
  ];

  static const List<AppNavDestination> employee = [
    AppNavDestination(
      label: 'Home',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home,
      route: AppRoutes.employeeWorkspace,
    ),
    AppNavDestination(
      label: 'Attendance',
      icon: Icons.access_time_outlined,
      selectedIcon: Icons.access_time_filled,
      route: AppRoutes.employeeAttendance,
    ),
    AppNavDestination(
      label: 'Returns',
      icon: Icons.assignment_return_outlined,
      selectedIcon: Icons.assignment_return,
      route: AppRoutes.employeeReturns,
    ),
    AppNavDestination(
      label: 'Profile',
      icon: Icons.person_outline,
      selectedIcon: Icons.person,
      route: AppRoutes.employeeProfile,
    ),
  ];
}

/// The landing route for [role].
String defaultRouteForRole(UserRole role) {
  switch (role) {
    case UserRole.platformOwner:
    case UserRole.platformAdmin:
      return AppRoutes.platformWorkspace;
    case UserRole.orgAdmin:
      return AppRoutes.orgAdminWorkspace;
    case UserRole.branchManager:
      return AppRoutes.branchManagerWorkspace;
    case UserRole.employee:
      return AppRoutes.employeeWorkspace;
  }
}

/// Returns the safe landing route when a role cannot open [matchedLocation].
///
/// Kept separate from router rendering so route authorization can be tested
/// without building the destination screen.
String? redirectForRoleRoute({
  required UserRole role,
  required String matchedLocation,
}) {
  if (matchedLocation.startsWith('/platform')) {
    if (role != UserRole.platformOwner && role != UserRole.platformAdmin) {
      return defaultRouteForRole(role);
    }
    if (matchedLocation.startsWith(AppRoutes.platformUsers) &&
        role != UserRole.platformOwner) {
      return defaultRouteForRole(role);
    }
  } else if (matchedLocation.startsWith('/organization')) {
    if (role != UserRole.orgAdmin) return defaultRouteForRole(role);
  } else if (matchedLocation.startsWith('/branch-manager')) {
    if (role != UserRole.branchManager) return defaultRouteForRole(role);
  } else if (matchedLocation.startsWith('/employee')) {
    if (role != UserRole.employee) return defaultRouteForRole(role);
  }
  return null;
}
