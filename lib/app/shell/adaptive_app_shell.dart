import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:workaxis/app/shell/nav_destination.dart';
import 'package:workaxis/app/shell/widgets/compact_shell.dart';
import 'package:workaxis/app/shell/widgets/expanded_shell.dart';
import 'package:workaxis/core/responsive/responsive_layout.dart';

/// Index of the destination that owns [route]: an exact match, otherwise the
/// destination with the longest route prefix. Home routes (`/organization`)
/// prefix every child path, so the first prefix match would always be Home.
int selectedDestinationIndex(
  List<AppNavDestination> destinations,
  String route,
) {
  final exact = destinations.indexWhere((d) => d.route == route);
  if (exact >= 0) return exact;
  var best = 0;
  var bestLength = -1;
  for (var i = 0; i < destinations.length; i++) {
    final candidate = destinations[i].route;
    if (candidate != '/' &&
        route.startsWith('$candidate/') &&
        candidate.length > bestLength) {
      best = i;
      bestLength = candidate.length;
    }
  }
  return best;
}

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

  int get _selectedIndex =>
      selectedDestinationIndex(destinations, currentRoute);

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
