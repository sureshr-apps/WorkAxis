import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:workaxis/app/shell/nav_destination.dart';
import 'package:workaxis/app/shell/widgets/compact_shell.dart';
import 'package:workaxis/app/shell/widgets/expanded_shell.dart';
import 'package:workaxis/core/responsive/responsive_layout.dart';

/// Adaptive navigation shell: a drawer-based [CompactShell] below 840dp and a
/// persistent-sidebar [ExpandedShell] above, across all supported roles.
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
    void select(int index) => _onDestinationSelected(context, index);

    if (context.isExpanded) {
      return ExpandedShell(
        destinations: destinations,
        selectedIndex: _selectedIndex,
        onDestinationSelected: select,
        child: child,
      );
    }
    return CompactShell(
      destinations: destinations,
      selectedIndex: _selectedIndex,
      onDestinationSelected: select,
      child: child,
    );
  }
}
