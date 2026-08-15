import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:workaxis/core/constants/app_radius.dart';
import 'package:workaxis/core/constants/app_spacing.dart';
import 'package:workaxis/core/theme/app_colors.dart';
import 'package:workaxis/core/widgets/status_chip.dart';
import 'package:workaxis/features/access_control/domain/entities/organization_membership.dart';
import 'package:workaxis/features/access_control/domain/entities/user_role.dart';
import 'package:workaxis/features/authentication/presentation/controllers/auth_controller.dart';
import 'package:workaxis/features/organization/presentation/controllers/organization_context_controller.dart';
import 'package:workaxis/features/organization/presentation/widgets/organization_switcher_sheet.dart';

class ManagerDashboardPlaceholder extends StatelessWidget {
  const ManagerDashboardPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final orgController = context.watch<OrganizationContextController>();
    final activeMembership = orgController.activeMembership;
    final state = orgController.state;

    final allMemberships = state is AccessGrantedState
        ? state.allMemberships
        : <OrganizationMembership>[];

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: InkWell(
          borderRadius: AppRadius.borderDefault,
          onTap: allMemberships.length > 1
              ? () {
                  OrganizationSwitcherSheet.show(
                    context: context,
                    memberships: allMemberships,
                    activeMembership: activeMembership!,
                    onSelect: (m) async {
                      await orgController.switchOrganization(m);
                      if (context.mounted) {
                        final newState = orgController.state;
                        if (newState is AccessGrantedState) {
                          switch (newState.activeMembership.role) {
                            case UserRole.orgAdmin:
                              context.go('/admin/dashboard');
                            case UserRole.branchManager:
                              context.go('/manager/dashboard');
                            case UserRole.employee:
                              context.go('/employee/dashboard');
                          }
                        } else if (newState is BranchAssignmentRequiredState) {
                          context.go('/branch-required');
                        }
                      }
                    },
                  );
                }
              : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xs, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  activeMembership?.organization.name ?? 'Branch Manager',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (allMemberships.length > 1) ...[
                  const SizedBox(width: AppSpacing.xs),
                  const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
                ],
              ],
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Sign Out',
            onPressed: () async {
              await context.read<AuthController>().signOut();
              if (context.mounted) {
                orgController.clear();
                context.go('/welcome');
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.marginMedium),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: const BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: AppRadius.borderLg,
                    ),
                    child: const Icon(
                      Icons.storefront_rounded,
                      color: AppColors.onPrimaryContainer,
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Branch Manager Dashboard',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Managing branch: ${activeMembership?.branchName ?? "Assigned Branch"} at ${activeMembership?.organization.name ?? "Organization"}.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const StatusChip(
                    type: StatusChipType.active,
                    label: 'Manager Session Active',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
