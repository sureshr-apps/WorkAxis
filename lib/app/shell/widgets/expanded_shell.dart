import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:workaxis/app/routing/app_routes.dart';
import 'package:workaxis/app/session/session_controller.dart';
import 'package:workaxis/app/shell/nav_destination.dart';
import 'package:workaxis/app/shell/widgets/shell_sidebar.dart';
import 'package:workaxis/app/shell/widgets/top_console_bar.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/core/constants/app_breakpoints.dart';
import 'package:workaxis/core/responsive/content_width_scope.dart';
import 'package:workaxis/features/access/presentation/controllers/access_controller.dart';
import 'package:workaxis/features/access/presentation/controllers/branch_context_controller.dart';

/// Expanded (>= 840dp) layout: persistent sidebar, full-width top console bar
/// rendered above the content so its shadow falls over sidebar and page.
class ExpandedShell extends StatelessWidget {
  const ExpandedShell({
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
    final activeBranch = context.watch<BranchContextController>().activeBranch;
    final user = accessContext?.user;
    final hasMultipleBranches =
        accessContext?.hasMultipleAssignedBranches ?? false;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            top: AppBreakpoints.topBarHeight,
            child: Row(
              children: [
                ShellSidebar(
                  destinations: destinations,
                  selectedIndex: selectedIndex,
                  onDestinationSelected: onDestinationSelected,
                  role: user?.role,
                  organizationName: accessContext?.organization?.name,
                  activeBranch: activeBranch,
                  onChangeBranch: hasMultipleBranches
                      ? () => context.go(AppRoutes.selectBranch)
                      : null,
                ),
                Expanded(child: ContentWidthProvider(child: child)),
              ],
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: AppBreakpoints.topBarHeight,
            child: TopConsoleBar(
              role: user?.role,
              organization: accessContext?.organization,
              userName: user?.name,
              onSignOut: () => context.read<SessionController>().signOut(),
            ),
          ),
        ],
      ),
    );
  }
}
