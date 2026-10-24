import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:workaxis/app/routing/app_routes.dart';
import 'package:workaxis/app/shell/nav_destination.dart';
import 'package:workaxis/app/shell/widgets/app_navigation_drawer.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/core/responsive/responsive_layout.dart';
import 'package:workaxis/features/access/presentation/controllers/access_controller.dart';
import 'package:workaxis/features/access/presentation/controllers/branch_context_controller.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';
import 'package:workaxis/features/authentication/presentation/controllers/auth_controller.dart';

/// Adaptive navigation shell accommodating Compact (bottom nav), Medium (rail),
/// and Expanded (persistent sidebar) viewports across all supported roles.
class AdaptiveAppShell extends StatelessWidget {
  final Widget child;
  final List<AppNavDestination> destinations;
  final String currentRoute;

  const AdaptiveAppShell({
    super.key,
    required this.child,
    required this.destinations,
    required this.currentRoute,
  });

  int get _selectedIndex {
    final index = destinations.indexWhere((d) => d.route == currentRoute);
    if (index >= 0) return index;
    final prefixIndex = destinations.indexWhere(
      (d) => d.route != '/' && currentRoute.startsWith('${d.route}/'),
    );
    return prefixIndex >= 0 ? prefixIndex : 0;
  }

  void _onDestinationSelected(BuildContext context, int index) {
    if (index >= 0 && index < destinations.length) {
      final target = destinations[index].route;
      if (target != currentRoute) {
        context.go(target);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCompact = context.isCompact;
    final isMedium = context.isMedium;

    if (isCompact || isMedium) {
      return _buildCollapsibleShell(context);
    } else {
      return _buildExpandedShell(context);
    }
  }

  Widget _buildCollapsibleShell(BuildContext context) {
    final accessContext = context.watch<AccessController>().accessContext;
    final user = accessContext?.user;
    final isBranchManager = user?.role == UserRole.branchManager;
    final hasMultipleBranches =
        accessContext?.hasMultipleAssignedBranches ?? false;

    final String userName = user?.name != null && user!.name.isNotEmpty
        ? user.name
        : 'Alex Vance';
    final String userRole = user?.role != null
        ? user!.role.displayName
        : 'Platform Administrator';

    return Scaffold(
      backgroundColor: AppColors.surface,
      drawer: AppNavigationDrawer(
        destinations: destinations,
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) =>
            _onDestinationSelected(context, index),
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
        title: Row(
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
        ),
        actions: [
          if (isBranchManager && hasMultipleBranches)
            IconButton(
              tooltip: 'Change Branch',
              icon: const Icon(
                Icons.swap_horiz,
                size: 22,
                color: AppColors.primary,
              ),
              onPressed: () => context.go(AppRoutes.selectBranch),
            ),
          _buildUserProfileMenu(
            context,
            userName: userName,
            userRole: userRole,
            showNameAndRole: false,
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

  Widget _buildExpandedShell(BuildContext context) {
    final accessContext = context.watch<AccessController>().accessContext;
    final activeBranch = context.watch<BranchContextController>().activeBranch;
    final user = accessContext?.user;
    final isBranchManager = user?.role == UserRole.branchManager;
    final hasMultipleBranches =
        accessContext?.hasMultipleAssignedBranches ?? false;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Stack(
        clipBehavior: Clip.none,
        children: [
          // Main horizontal area: Persistent Sidebar on left, Child on right (offset by top bar height: 60)
          Positioned.fill(
            top: 60,
            child: Row(
              children: [
                // Persistent Sidebar (260dp width)
                Container(
                  width: 260,
                  decoration: const BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    border: Border(
                      right: BorderSide(
                        color: Color(0xFFE2E8F0),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: AppSpacing.sm),

                      // Organization Scope Box (for Org Admin)
                      if (user?.role == UserRole.orgAdmin) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.sm,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(
                                AppSpacing.radiusSm,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'SCOPE',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.secondary,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.statusActiveContainer,
                                    borderRadius: BorderRadius.circular(
                                      AppSpacing.radiusPill,
                                    ),
                                  ),
                                  child: Text(
                                    'Single Org',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.statusActiveText,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                      ],

                      // Active Branch Context Box (for Branch Managers)
                      if (isBranchManager && activeBranch != null) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(AppSpacing.sm),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(
                                AppSpacing.radiusSm,
                              ),
                              border: Border.all(color: AppColors.outlineSubtle),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.storefront,
                                  size: 18,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        activeBranch.branchName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        activeBranch.branchCode,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontFamily: 'JetBrains Mono',
                                          color: AppColors.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (hasMultipleBranches)
                                  IconButton(
                                    icon: const Icon(
                                      Icons.swap_horiz,
                                      size: 18,
                                    ),
                                    tooltip: 'Change Branch',
                                    onPressed: () =>
                                        context.go(AppRoutes.selectBranch),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                      ],

                      // Nav Links
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                          ),
                          itemCount: destinations.length,
                          itemBuilder: (context, index) {
                            final item = destinations[index];
                            final isSelected = index == _selectedIndex;

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Material(
                                color: isSelected
                                    ? AppColors.primaryContainer
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(
                                  AppSpacing.radiusSm,
                                ),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(
                                    AppSpacing.radiusSm,
                                  ),
                                  hoverColor: AppColors.surfaceContainerLow,
                                  onTap: () =>
                                      _onDestinationSelected(context, index),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.md,
                                      vertical: 10,
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          isSelected
                                              ? item.selectedIcon
                                              : item.icon,
                                          size: 20,
                                          color: isSelected
                                              ? AppColors.onPrimaryContainer
                                              : AppColors.onSurfaceVariant,
                                        ),
                                        const SizedBox(width: AppSpacing.md),
                                        Text(
                                          item.label,
                                          style: TextStyle(
                                            fontWeight: isSelected
                                                ? FontWeight.w600
                                                : FontWeight.w500,
                                            fontSize: 14,
                                            color: isSelected
                                                ? AppColors.onPrimaryContainer
                                                : AppColors.onSurface,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      // Org System Online Status + Sign Out (for Org Admin)
                      if (user?.role == UserRole.orgAdmin) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.md,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.statusActiveContainer,
                                  borderRadius: BorderRadius.circular(
                                    AppSpacing.radiusSm,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: const BoxDecoration(
                                            color: AppColors.statusActive,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: AppSpacing.sm),
                                        Text(
                                          'Org System Online',
                                          style: GoogleFonts.inter(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.statusActiveText,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      'v2.4',
                                      style: GoogleFonts.jetBrainsMono(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.statusActiveText,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: AppSpacing.md),
                    ],
                  ),
                ),

                // Main Screen Content
                Expanded(child: child),
              ],
            ),
          ),

          // Full-width Unified Top Console Bar (rendered ON TOP so shadow casts over content and sidebar)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 60,
            child: _buildTopConsoleBar(context, user),
          ),
        ],
      ),
    );
  }

  Widget _buildTopConsoleBar(BuildContext context, dynamic user) {
    final accessContext = context.watch<AccessController>().accessContext;
    final role = user?.role as UserRole?;
    final String consoleBadgeText;
    switch (role) {
      case UserRole.platformOwner:
      case UserRole.platformAdmin:
        consoleBadgeText = 'PLATFORM CONSOLE';
      case UserRole.orgAdmin:
        consoleBadgeText = 'ORGANIZATION CONSOLE';
      case UserRole.branchManager:
        consoleBadgeText = 'BRANCH OPERATIONS';
      case UserRole.employee:
        consoleBadgeText = 'EMPLOYEE PORTAL';
      case null:
        consoleBadgeText = 'OPERATIONS CONSOLE';
    }

    final String userName =
        user?.name != null && (user!.name as String).isNotEmpty
        ? user.name as String
        : 'Alex Vance';
    final String userRole = user?.role != null
        ? (user.role as UserRole).displayName
        : 'Platform Administrator';

    return Container(
      height: 60,
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        border: Border(
          bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1.0),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x1A000000),
            offset: Offset(0, 3),
            blurRadius: 6,
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Color(0x0F000000),
            offset: Offset(0, 1),
            blurRadius: 2,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left: "Ops Hub / MANAGEMENT" Brand (width: 260dp to align with sidebar below)
          SizedBox(
            width: 260,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(
                        AppSpacing.radiusSm,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.25),
                          offset: const Offset(0, 2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.hub_outlined,
                      color: AppColors.onPrimary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ops Hub',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            letterSpacing: -0.2,
                            color: AppColors.onSurface,
                          ),
                        ),
                        Text(
                          user?.role == UserRole.orgAdmin
                              ? (accessContext?.organization?.name
                                        .toUpperCase() ??
                                    'APEX LOGISTICS & FREIGHT')
                              : 'MANAGEMENT',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: user?.role == UserRole.orgAdmin
                                ? AppColors.secondary
                                : const Color(0xFF004AC6),
                            letterSpacing: 0.8,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Section Divider matching the one next to notification icon (with shadow)
          Container(
            width: 1,
            height: 24,
            decoration: const BoxDecoration(
              color: AppColors.outlineSubtle,
              boxShadow: [
                BoxShadow(
                  color: Color(0x1A000000),
                  offset: Offset(1.5, 0),
                  blurRadius: 3,
                  spreadRadius: 0,
                ),
                BoxShadow(
                  color: Color(0x0F000000),
                  offset: Offset(0.5, 0),
                  blurRadius: 1,
                  spreadRadius: 0,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.lg),

          // Center/Left-Center: Operations Hub title & badge
          if (role == UserRole.orgAdmin)
            Expanded(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.corporate_fare,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Flexible(
                    child: Text(
                      accessContext?.organization?.name ??
                          'Apex Logistics & Freight',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurface,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  const Text(
                    '•',
                    style: TextStyle(color: AppColors.outline, fontSize: 14),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      accessContext?.organization?.code ?? 'HQ-001',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.secondary,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Expanded(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      'Operations Hub',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                        letterSpacing: -0.2,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDBE1FF),
                      borderRadius: BorderRadius.circular(
                        AppSpacing.radiusPill,
                      ),
                    ),
                    child: Text(
                      consoleBadgeText,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF003EA8),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(width: AppSpacing.sm),

          // Right: Notifications + Divider + Profile Menu
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.xl),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IconButton(
                      tooltip: 'Notifications',
                      icon: const Icon(
                        Icons.notifications_outlined,
                        size: 22,
                        color: AppColors.onSurfaceVariant,
                      ),
                      onPressed: () {},
                    ),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppColors.statusUrgent,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.surfaceContainerLowest,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                Container(
                  width: 1,
                  height: 24,
                  margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                  decoration: const BoxDecoration(
                    color: AppColors.outlineSubtle,
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x1A000000),
                        offset: Offset(1.5, 0),
                        blurRadius: 3,
                        spreadRadius: 0,
                      ),
                      BoxShadow(
                        color: Color(0x0F000000),
                        offset: Offset(0.5, 0),
                        blurRadius: 1,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                _buildUserProfileMenu(
                  context,
                  userName: userName,
                  userRole: userRole,
                  showNameAndRole: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserProfileMenu(
    BuildContext context, {
    required String userName,
    required String userRole,
    required bool showNameAndRole,
  }) {
    return PopupMenuButton<String>(
      tooltip: 'User Profile & Actions',
      offset: const Offset(0, 48),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        side: const BorderSide(color: AppColors.outlineSubtle),
      ),
      onSelected: (value) {
        if (value == 'sign_out') {
          _handleSignOut(context);
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                userName,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: AppColors.onSurface,
                ),
              ),
              Text(
                userRole,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppColors.secondary,
                ),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          value: 'sign_out',
          child: Row(
            children: [
              const Icon(
                Icons.logout,
                size: 18,
                color: AppColors.statusUrgentText,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Sign Out',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.statusUrgentText,
                ),
              ),
            ],
          ),
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (showNameAndRole) ...[
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 150),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      userName,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurface,
                        height: 1.2,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    Text(
                      userRole,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.secondary,
                        height: 1.2,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm + 2),
            ],
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: Color(0xFF003594),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(Icons.person, size: 18, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleSignOut(BuildContext context) {
    context.read<BranchContextController>().clear();
    context.read<AccessController>().clear();
    context.read<AuthController>().signOut();
  }
}
