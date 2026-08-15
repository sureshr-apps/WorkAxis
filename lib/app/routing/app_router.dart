import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:workaxis/features/access_control/domain/entities/user_role.dart';
import 'package:workaxis/features/access_control/presentation/pages/access_denied_page.dart';
import 'package:workaxis/features/access_control/presentation/pages/account_disabled_page.dart';
import 'package:workaxis/features/access_control/presentation/pages/branch_assignment_required_page.dart';
import 'package:workaxis/features/access_control/presentation/pages/invitation_acceptance_page.dart';
import 'package:workaxis/features/access_control/presentation/pages/invitation_expired_page.dart';
import 'package:workaxis/features/access_control/presentation/pages/invitation_identity_mismatch_page.dart';
import 'package:workaxis/features/access_control/presentation/pages/organization_unavailable_page.dart';
import 'package:workaxis/features/access_control/presentation/pages/verifying_access_page.dart';
import 'package:workaxis/features/authentication/presentation/controllers/auth_controller.dart';
import 'package:workaxis/features/authentication/presentation/pages/otp_verification_page.dart';
import 'package:workaxis/features/authentication/presentation/pages/phone_sign_in_page.dart';
import 'package:workaxis/features/authentication/presentation/pages/welcome_page.dart';
import 'package:workaxis/features/dashboard/presentation/pages/admin_dashboard_placeholder.dart';
import 'package:workaxis/features/dashboard/presentation/pages/employee_dashboard_placeholder.dart';
import 'package:workaxis/features/dashboard/presentation/pages/manager_dashboard_placeholder.dart';
import 'package:workaxis/features/organization/presentation/controllers/organization_context_controller.dart';
import 'package:workaxis/features/organization/presentation/pages/organization_selection_page.dart';

class AppRouter {
  static GoRouter createRouter({
    required AuthController authController,
    required OrganizationContextController orgController,
  }) {
    return GoRouter(
      initialLocation: '/welcome',
      refreshListenable: Listenable.merge([authController, orgController]),
      redirect: (context, state) {
        final location = state.uri.path;
        final isAuthenticated = authController.isAuthenticated;
        final accessState = orgController.state;

        final isPublicAuthRoute = location == '/welcome' ||
            location == '/signin/phone' ||
            location == '/signin/otp';

        // 1. Unauthenticated users must stay on public auth routes
        if (!isAuthenticated) {
          if (!isPublicAuthRoute) {
            return '/welcome';
          }
          return null;
        }

        // 2. Authenticated user trying to access public auth routes
        if (isPublicAuthRoute) {
          if (accessState is AccessInitial) {
            return '/verifying-access';
          }
        }

        // 3. Verifying access destination resolution
        if (location == '/verifying-access') {
          if (accessState is AccessDeniedState) {
            return '/access-denied';
          } else if (accessState is AccountDisabledState) {
            return '/account-disabled';
          } else if (accessState is OrganizationSelectionRequiredState) {
            return '/organizations';
          } else if (accessState is OrganizationUnavailableState) {
            return '/organization-unavailable';
          } else if (accessState is BranchAssignmentRequiredState) {
            return '/branch-required';
          } else if (accessState is PendingInvitationState) {
            return '/invite';
          } else if (accessState is InvitationExpiredState) {
            return '/invite/expired';
          } else if (accessState is InvitationMismatchState) {
            return '/invite/mismatch';
          } else if (accessState is AccessGrantedState) {
            final role = accessState.activeMembership.role;
            switch (role) {
              case UserRole.orgAdmin:
                return '/admin/dashboard';
              case UserRole.branchManager:
                return '/manager/dashboard';
              case UserRole.employee:
                return '/employee/dashboard';
            }
          }
        }

        // 4. Protected Dashboard route guards
        final isDashboardRoute = location.startsWith('/admin') ||
            location.startsWith('/manager') ||
            location.startsWith('/employee');

        if (isDashboardRoute) {
          if (accessState is AccessInitial || accessState is AccessResolving) {
            return '/verifying-access';
          } else if (accessState is AccessDeniedState) {
            return '/access-denied';
          } else if (accessState is AccountDisabledState) {
            return '/account-disabled';
          } else if (accessState is OrganizationSelectionRequiredState) {
            return '/organizations';
          } else if (accessState is OrganizationUnavailableState) {
            return '/organization-unavailable';
          } else if (accessState is BranchAssignmentRequiredState) {
            return '/branch-required';
          } else if (accessState is PendingInvitationState) {
            return '/invite';
          } else if (accessState is AccessGrantedState) {
            // Verify correct role dashboard
            final role = accessState.activeMembership.role;
            if (role == UserRole.orgAdmin && !location.startsWith('/admin')) {
              return '/admin/dashboard';
            } else if (role == UserRole.branchManager &&
                !location.startsWith('/manager')) {
              return '/manager/dashboard';
            } else if (role == UserRole.employee &&
                !location.startsWith('/employee')) {
              return '/employee/dashboard';
            }
          }
        }

        return null;
      },
      routes: [
        GoRoute(
          path: '/welcome',
          builder: (context, state) => const WelcomePage(),
        ),
        GoRoute(
          path: '/signin/phone',
          builder: (context, state) => const PhoneSignInPage(),
        ),
        GoRoute(
          path: '/signin/otp',
          builder: (context, state) => const OtpVerificationPage(),
        ),
        GoRoute(
          path: '/verifying-access',
          builder: (context, state) => const VerifyingAccessPage(),
        ),
        GoRoute(
          path: '/organizations',
          builder: (context, state) => const OrganizationSelectionPage(),
        ),
        GoRoute(
          path: '/invite',
          builder: (context, state) => const InvitationAcceptancePage(),
        ),
        GoRoute(
          path: '/invite/expired',
          builder: (context, state) => const InvitationExpiredPage(),
        ),
        GoRoute(
          path: '/invite/mismatch',
          builder: (context, state) => const InvitationIdentityMismatchPage(),
        ),
        GoRoute(
          path: '/access-denied',
          builder: (context, state) => const AccessDeniedPage(),
        ),
        GoRoute(
          path: '/account-disabled',
          builder: (context, state) => const AccountDisabledPage(),
        ),
        GoRoute(
          path: '/organization-unavailable',
          builder: (context, state) => const OrganizationUnavailablePage(),
        ),
        GoRoute(
          path: '/branch-required',
          builder: (context, state) => const BranchAssignmentRequiredPage(),
        ),
        GoRoute(
          path: '/admin/dashboard',
          builder: (context, state) => const AdminDashboardPlaceholder(),
        ),
        GoRoute(
          path: '/manager/dashboard',
          builder: (context, state) => const ManagerDashboardPlaceholder(),
        ),
        GoRoute(
          path: '/employee/dashboard',
          builder: (context, state) => const EmployeeDashboardPlaceholder(),
        ),
      ],
    );
  }
}
