import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:workaxis/app/routing/app_routes.dart';
import 'package:workaxis/app/routing/role_destinations.dart';
import 'package:workaxis/app/routing/route_error_screen.dart';
import 'package:workaxis/app/shell/adaptive_app_shell.dart';
import 'package:workaxis/app/startup/splash_screen.dart';
import 'package:workaxis/features/access/presentation/controllers/access_controller.dart';
import 'package:workaxis/features/access/presentation/controllers/branch_context_controller.dart';
import 'package:workaxis/features/access/presentation/screens/access_verification_screen.dart';
import 'package:workaxis/features/access/presentation/screens/branch_selection_screen.dart';
import 'package:workaxis/features/access/presentation/screens/no_branch_assigned_screen.dart';
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
    errorBuilder: (context, state) =>
        RouteErrorScreen(location: state.uri.toString()),
    redirect: (context, state) => resolveRedirect(
      matchedLocation: state.matchedLocation,
      authController: authController,
      accessController: accessController,
      branchController: branchController,
    ),
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
      GoRoute(
        path: AppRoutes.noBranchAssigned,
        builder: (context, state) => const NoBranchAssignedScreen(),
      ),
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),

      // -------------------------------------------------------------
      // Platform Owner / Platform Admin Shell & Routes
      // -------------------------------------------------------------
      ShellRoute(
        builder: (context, state, child) {
          final isOwner =
              accessController.accessContext?.user.role ==
              UserRole.platformOwner;
          final destinations = RoleDestinations.platform(isOwner: isOwner);

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
          const destinations = RoleDestinations.organizationAdmin;

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
          const destinations = RoleDestinations.branchManager;

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
          const destinations = RoleDestinations.employee;

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

/// Pure redirect decision for [matchedLocation]; `null` means "stay".
///
/// Order of guards: startup, authentication, access resolution, Branch Manager
/// branch context, then role-area protection.
String? resolveRedirect({
  required String matchedLocation,
  required AuthController authController,
  required AccessController accessController,
  required BranchContextController branchController,
}) {
  final matched = matchedLocation;

  // 0. While the previous session is being restored, show the splash.
  if (authController.isInitializing) {
    return matched == AppRoutes.splash ? null : AppRoutes.splash;
  }

  // 1. Unauthenticated users must always be directed to Sign In
  if (!authController.isAuthenticated) {
    return matched == AppRoutes.signIn ? null : AppRoutes.signIn;
  }

  // 2. Authenticated users never rest on Sign In or the splash.
  if (matched == AppRoutes.signIn || matched == AppRoutes.splash) {
    return AppRoutes.verifyAccess;
  }

  // 3. Access must be resolved before any other screen is reachable.
  final accessContext = accessController.accessContext;
  if (accessContext == null) {
    return matched == AppRoutes.verifyAccess ? null : AppRoutes.verifyAccess;
  }

  final role = accessContext.user.role;
  final isBranchManager = role == UserRole.branchManager;

  // 4. A Branch Manager is always gated until a branch context exists.
  if (isBranchManager && !branchController.hasActiveBranch) {
    if (accessContext.hasNoAssignedBranches) {
      return matched == AppRoutes.noBranchAssigned
          ? null
          : AppRoutes.noBranchAssigned;
    }
    return matched == AppRoutes.selectBranch ? null : AppRoutes.selectBranch;
  }

  // 5. Branch-specific utility screens are for Branch Managers only; resolved
  //    users have nothing to do on the verification screen.
  if (matched == AppRoutes.verifyAccess ||
      matched == AppRoutes.noBranchAssigned ||
      (matched == AppRoutes.selectBranch && !isBranchManager)) {
    return defaultRouteForRole(role);
  }

  // 6. Role-based Route Protection
  return redirectForRoleRoute(role: role, matchedLocation: matched);
}
