import 'package:flutter/material.dart';
import 'package:workaxis/app/shell/nav_destination.dart';
import 'package:workaxis/app/shell/widgets/branch_context_card.dart';
import 'package:workaxis/app/shell/widgets/nav_tile.dart';
import 'package:workaxis/app/shell/widgets/org_scope_card.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/core/constants/app_breakpoints.dart';
import 'package:workaxis/features/access/domain/models/active_branch_context.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';

/// Persistent navigation sidebar of the expanded layout.
class ShellSidebar extends StatelessWidget {
  const ShellSidebar({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.role,
    this.organizationName,
    this.activeBranch,
    this.onChangeBranch,
  });

  final List<AppNavDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final UserRole? role;
  final String? organizationName;
  final ActiveBranchContext? activeBranch;

  /// Non-null only when the manager has more than one branch to switch to.
  final VoidCallback? onChangeBranch;

  @override
  Widget build(BuildContext context) {
    final branch = activeBranch;

    return Container(
      width: AppBreakpoints.sidebarWidth,
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        border: Border(right: BorderSide(color: AppColors.kpiBorder, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.sm),
          if (role == UserRole.orgAdmin) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: OrgScopeCard(organizationName: organizationName),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          if (role == UserRole.branchManager && branch != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: BranchContextCard(
                branch: branch,
                onChangeBranch: onChangeBranch,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              itemCount: destinations.length,
              itemBuilder: (context, index) => NavTile(
                destination: destinations[index],
                isSelected: index == selectedIndex,
                onTap: () => onDestinationSelected(index),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}
