import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:workaxis/app/routing/app_routes.dart';
import 'package:workaxis/app/shell/nav_destination.dart';
import 'package:workaxis/app/shell/widgets/branch_context_card.dart';
import 'package:workaxis/app/shell/widgets/nav_tile.dart';
import 'package:workaxis/app/shell/widgets/org_scope_card.dart';
import 'package:workaxis/app/shell/widgets/shell_labels.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/features/access/presentation/controllers/access_controller.dart';
import 'package:workaxis/features/access/presentation/controllers/branch_context_controller.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';

/// Collapsible side pane (Drawer) for smartphone and tablet viewports.
/// Contains all navigation destinations previously shown in bottom bars or rails.
class AppNavigationDrawer extends StatelessWidget {
  final List<AppNavDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final VoidCallback? onSignOut;

  const AppNavigationDrawer({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    final accessContext = context.watch<AccessController>().accessContext;
    final activeBranch = context.watch<BranchContextController>().activeBranch;
    final role = accessContext?.user.role;
    final hasMultipleBranches =
        accessContext?.hasMultipleAssignedBranches ?? false;

    return Drawer(
      backgroundColor: AppColors.surfaceContainerLowest,
      elevation: 3,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(AppSpacing.radiusLg),
          bottomRight: Radius.circular(AppSpacing.radiusLg),
        ),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DrawerHeader(role: role),
            if (role == UserRole.branchManager && activeBranch != null)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                child: BranchContextCard(
                  branch: activeBranch,
                  onChangeBranch: hasMultipleBranches
                      ? () {
                          Navigator.of(context).pop();
                          context.go(AppRoutes.selectBranch);
                        }
                      : null,
                ),
              ),
            if (role == UserRole.orgAdmin)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                child: OrgScopeCard(
                  organizationName: accessContext?.organization?.name,
                ),
              ),
            const SizedBox(height: AppSpacing.xs),
            const Divider(color: AppColors.outlineSubtle, height: 1),
            const SizedBox(height: AppSpacing.sm),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.xs,
              ),
              child: Text(
                'NAVIGATION',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                  color: AppColors.secondary,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                itemCount: destinations.length,
                itemBuilder: (context, index) => NavTile(
                  destination: destinations[index],
                  isSelected: index == selectedIndex,
                  density: NavTileDensity.drawer,
                  onTap: () {
                    Navigator.of(context).pop();
                    onDestinationSelected(index);
                  },
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }
}

class _DrawerHeader extends StatelessWidget {
  const _DrawerHeader({required this.role});

  final UserRole? role;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: AppSpacing.roundedSm,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.25),
                  offset: const Offset(0, 2),
                  blurRadius: 4,
                ),
              ],
            ),
            child: const Center(
              child: Icon(
                Icons.shield_outlined,
                color: AppColors.onPrimary,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'WorkAxis',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    letterSpacing: -0.2,
                    color: AppColors.onSurface,
                  ),
                ),
                Text(
                  consoleBadgeTextFor(role),
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                    letterSpacing: 0.8,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            tooltip: 'Close navigation',
            color: AppColors.onSurfaceVariant,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
