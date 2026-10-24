import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:workaxis/app/routing/app_routes.dart';
import 'package:workaxis/app/shell/adaptive_app_shell.dart';
import 'package:workaxis/app/shell/nav_destination.dart';
import 'package:workaxis/features/access/presentation/controllers/access_controller.dart';
import 'package:workaxis/features/access/presentation/controllers/branch_context_controller.dart';
import 'package:workaxis/features/access/presentation/screens/access_verification_screen.dart';
import 'package:workaxis/features/access/presentation/screens/branch_selection_screen.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';
import 'package:workaxis/features/authentication/presentation/controllers/auth_controller.dart';
import 'package:workaxis/features/authentication/presentation/screens/sign_in_screen.dart';
import 'package:workaxis/features/branch_dashboard/presentation/screens/branch_home_screen.dart';
import 'package:workaxis/features/branches/presentation/screens/branch_management_screen.dart';
import 'package:workaxis/features/employees/presentation/screens/employee_directory_screen.dart';
import 'package:workaxis/features/attendance/presentation/screens/attendance_operations_screen.dart';
import 'package:workaxis/features/employee_home/presentation/screens/employee_home_screen.dart';
import 'package:workaxis/features/organization_dashboard/presentation/screens/organization_home_screen.dart';
import 'package:workaxis/features/platform_dashboard/presentation/screens/platform_home_screen.dart';
import 'package:workaxis/features/platform_organizations/presentation/screens/add_organization_screen.dart';
import 'package:workaxis/features/platform_organizations/presentation/screens/edit_organization_screen.dart';
import 'package:workaxis/features/platform_organizations/presentation/screens/organization_details_screen.dart';
import 'package:workaxis/features/platform_organizations/presentation/screens/organizations_list_screen.dart';
import 'package:workaxis/features/platform_users/presentation/screens/platform_administrator_details_screen.dart';
import 'package:workaxis/features/platform_users/presentation/screens/platform_administrator_form_screen.dart';
import 'package:workaxis/features/platform_users/presentation/screens/platform_users_list_screen.dart';
import 'package:workaxis/features/profile/presentation/screens/employee_profile_screen.dart';
import 'package:workaxis/features/reports/presentation/screens/operational_reports_screen.dart';
import 'package:workaxis/features/returns/presentation/screens/employee_returns_screen.dart';
import 'package:workaxis/features/returns/presentation/screens/returns_operations_screen.dart';
import 'package:workaxis/features/settings/presentation/screens/organization_settings_screen.dart';
import 'package:workaxis/features/settings/presentation/screens/platform_settings_screen.dart';

/// Creates the centralized [GoRouter] configured with role-based routing, adaptive shells, and access guards.
GoRouter createAppRouter({
  required AuthController authController,
  required AccessController accessController,
  required BranchContextController branchController,
  String initialLocation = AppRoutes.signIn,
}) {
  return GoRouter(
    initialLocation: initialLocation,
    refreshListenable: Listenable.merge([
      authController,
      accessController,
      branchController,
    ]),
    redirect: (context, state) {
      final isAuthenticated = authController.isAuthenticated;
      final isSignInLocation = state.matchedLocation == AppRoutes.signIn;
      final isVerifyLocation = state.matchedLocation == AppRoutes.verifyAccess;

      // 1. Unauthenticated users must always be directed to Sign In
      if (!isAuthenticated) {
        return isSignInLocation ? null : AppRoutes.signIn;
      }

      // 2. If authenticated and on Sign In, forward to Access Verification
      if (isSignInLocation) {
        return AppRoutes.verifyAccess;
      }

      final accessContext = accessController.accessContext;

      // 3. If access context is not yet resolved, keep user on verification screen
      if (accessContext == null) {
        return isVerifyLocation ? null : AppRoutes.verifyAccess;
      }

      final userRole = accessContext.user.role;
      final matched = state.matchedLocation;

      // 4. Branch Manager multi-branch context guard
      final isBranchManager = userRole == UserRole.branchManager;
      if (isBranchManager) {
        final hasActiveBranch = branchController.hasActiveBranch;
        final hasMultipleBranches = accessContext.hasMultipleAssignedBranches;

        if (!hasActiveBranch && hasMultipleBranches) {
          final isSelectingBranch = matched == AppRoutes.selectBranch;
          if (!isSelectingBranch && !isVerifyLocation) {
            return AppRoutes.selectBranch;
          }
        }
      }

      // 5. Role-based Route Protection
      return redirectForRoleRoute(role: userRole, matchedLocation: matched);
    },
    routes: [
      GoRoute(
        path: AppRoutes.signIn,
        builder: (context, state) => const SignInScreen(),
      ),
      GoRoute(
        path: AppRoutes.verifyAccess,
        builder: (context, state) => const AccessVerificationScreen(),
      ),
      GoRoute(
        path: AppRoutes.selectBranch,
        builder: (context, state) => const BranchSelectionScreen(),
      ),

      // -------------------------------------------------------------
      // Platform Owner / Platform Admin Shell & Routes
      // -------------------------------------------------------------
      ShellRoute(
        builder: (context, state, child) {
          final isOwner =
              accessController.accessContext?.user.role ==
              UserRole.platformOwner;
          final destinations = [
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

          return AdaptiveAppShell(
            currentRoute: state.matchedLocation,
            destinations: destinations,
            child: child,
          );
        },
        routes: [
          GoRoute(
            path: AppRoutes.platformWorkspace,
            builder: (context, state) => const PlatformHomeScreen(),
          ),
          GoRoute(
            path: AppRoutes.platformOrganizations,
            builder: (context, state) => const OrganizationsListScreen(),
            routes: [
              GoRoute(
                path: 'add',
                builder: (context, state) => const AddOrganizationScreen(),
              ),
              GoRoute(
                path: ':id',
                builder: (context, state) {
                  final id = state.pathParameters['id'] ?? '';
                  return OrganizationDetailsScreen(organizationId: id);
                },
                routes: [
                  GoRoute(
                    path: 'edit',
                    builder: (context, state) {
                      final id = state.pathParameters['id'] ?? '';
                      return EditOrganizationScreen(organizationId: id);
                    },
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.platformUsers,
            builder: (context, state) => const PlatformUsersListScreen(),
            routes: [
              GoRoute(
                path: 'add',
                builder: (context, state) =>
                    const PlatformAdministratorFormScreen(),
              ),
              GoRoute(
                path: ':id',
                builder: (context, state) {
                  final id = state.pathParameters['id'] ?? '';
                  return PlatformAdministratorDetailsScreen(
                    administratorId: id,
                  );
                },
                routes: [
                  GoRoute(
                    path: 'edit',
                    builder: (context, state) =>
                        PlatformAdministratorFormScreen(
                          administratorId: state.pathParameters['id'] ?? '',
                        ),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.platformSettings,
            builder: (context, state) => const PlatformSettingsScreen(),
          ),
        ],
      ),

      // -------------------------------------------------------------
      // Organization Admin Shell & Routes
      // -------------------------------------------------------------
      ShellRoute(
        builder: (context, state, child) {
          const destinations = [
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

          return AdaptiveAppShell(
            currentRoute: state.matchedLocation,
            destinations: destinations,
            child: child,
          );
        },
        routes: [
          GoRoute(
            path: AppRoutes.orgAdminWorkspace,
            builder: (context, state) => const OrganizationHomeScreen(),
          ),
          GoRoute(
            path: AppRoutes.orgAdminBranches,
            builder: (context, state) => const BranchManagementScreen(),
          ),
          GoRoute(
            path: AppRoutes.orgAdminEmployees,
            builder: (context, state) => const EmployeeDirectoryScreen(),
          ),
          GoRoute(
            path: AppRoutes.orgAdminAttendance,
            builder: (context, state) => const AttendanceOperationsScreen(),
          ),
          GoRoute(
            path: AppRoutes.orgAdminReturns,
            builder: (context, state) => const ReturnsOperationsScreen(),
          ),
          GoRoute(
            path: AppRoutes.orgAdminReports,
            builder: (context, state) => const OperationalReportsScreen(),
          ),
          GoRoute(
            path: AppRoutes.orgAdminSettings,
            builder: (context, state) => const OrganizationSettingsScreen(),
          ),
        ],
      ),

      // -------------------------------------------------------------
      // Branch Manager Shell & Routes
      // -------------------------------------------------------------
      ShellRoute(
        builder: (context, state, child) {
          const destinations = [
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

          return AdaptiveAppShell(
            currentRoute: state.matchedLocation,
            destinations: destinations,
            child: child,
          );
        },
        routes: [
          GoRoute(
            path: AppRoutes.branchManagerWorkspace,
            builder: (context, state) => const BranchHomeScreen(),
          ),
          GoRoute(
            path: AppRoutes.branchManagerEmployees,
            builder: (context, state) => const EmployeeDirectoryScreen(),
          ),
          GoRoute(
            path: AppRoutes.branchManagerAttendance,
            builder: (context, state) => const AttendanceOperationsScreen(),
          ),
          GoRoute(
            path: AppRoutes.branchManagerReturns,
            builder: (context, state) => const ReturnsOperationsScreen(),
          ),
          GoRoute(
            path: AppRoutes.branchManagerReports,
            builder: (context, state) => const OperationalReportsScreen(),
          ),
        ],
      ),

      // -------------------------------------------------------------
      // Employee Shell & Routes
      // -------------------------------------------------------------
      ShellRoute(
        builder: (context, state, child) {
          const destinations = [
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

          return AdaptiveAppShell(
            currentRoute: state.matchedLocation,
            destinations: destinations,
            child: child,
          );
        },
        routes: [
          GoRoute(
            path: AppRoutes.employeeWorkspace,
            builder: (context, state) => const EmployeeHomeScreen(),
          ),
          GoRoute(
            path: AppRoutes.employeeAttendance,
            builder: (context, state) => const AttendanceOperationsScreen(),
          ),
          GoRoute(
            path: AppRoutes.employeeReturns,
            builder: (context, state) => const EmployeeReturnsScreen(),
          ),
          GoRoute(
            path: AppRoutes.employeeProfile,
            builder: (context, state) => const EmployeeProfileScreen(),
          ),
        ],
      ),
    ],
  );
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
      return _defaultRouteForRole(role);
    }
    if (matchedLocation.startsWith(AppRoutes.platformUsers) &&
        role != UserRole.platformOwner) {
      return _defaultRouteForRole(role);
    }
  } else if (matchedLocation.startsWith('/organization')) {
    if (role != UserRole.orgAdmin) return _defaultRouteForRole(role);
  } else if (matchedLocation.startsWith('/branch-manager')) {
    if (role != UserRole.branchManager) return _defaultRouteForRole(role);
  } else if (matchedLocation.startsWith('/employee')) {
    if (role != UserRole.employee) return _defaultRouteForRole(role);
  }
  return null;
}

String _defaultRouteForRole(UserRole role) {
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
