import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:workaxis/app/routing/app_routes.dart';
import 'package:workaxis/app/session/session_controller.dart';
import 'package:workaxis/app/shell/nav_destination.dart';
import 'package:workaxis/app/shell/widgets/app_navigation_drawer.dart';
import 'package:workaxis/app/shell/widgets/user_profile_menu.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/features/access/presentation/controllers/access_controller.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';

/// Compact (< 600dp) and medium (600-839dp) layout: app bar plus a navigation
/// drawer opened from the hamburger button.
class CompactShell extends StatelessWidget {
  const CompactShell({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.child,
  });

  final List<AppNavDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final accessContext = context.watch<AccessController>().accessContext;
    final user = accessContext?.user;
    final canChangeBranch =
        user?.role == UserRole.branchManager &&
        (accessContext?.hasMultipleAssignedBranches ?? false);

    return Scaffold(
      backgroundColor: AppColors.surface,
      drawer: AppNavigationDrawer(
        destinations: destinations,
        selectedIndex: selectedIndex,
        onDestinationSelected: onDestinationSelected,
      ),
      appBar: AppBar(
        backgroundColor: AppColors.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: Builder(
          builder: (scaffoldContext) => IconButton(
            tooltip: 'Open navigation menu',
            icon: const Icon(Icons.menu, size: 24, color: AppColors.onSurface),
            onPressed: () => Scaffold.of(scaffoldContext).openDrawer(),
          ),
        ),
        centerTitle: true,
        title: const _BrandTitle(),
        actions: [
          if (canChangeBranch)
            IconButton(
              tooltip: 'Change Branch',
              icon: const Icon(
                Icons.swap_horiz,
                size: 22,
                color: AppColors.primary,
              ),
              onPressed: () => context.go(AppRoutes.selectBranch),
            ),
          UserProfileMenu(
            userName: user?.name,
            roleLabel: user?.role.displayName,
            onSignOut: () => context.read<SessionController>().signOut(),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(
            height: 1,
            thickness: 1,
            color: AppColors.outlineSubtle,
          ),
        ),
      ),
      body: child,
    );
  }
}

class _BrandTitle extends StatelessWidget {
  const _BrandTitle();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.xs),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          child: const Icon(
            Icons.shield_outlined,
            color: AppColors.onPrimary,
            size: 18,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          'WorkAxis',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: AppColors.onSurface,
          ),
        ),
      ],
    );
  }
}
