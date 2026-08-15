import 'package:flutter/material.dart';
import 'package:workaxis/core/constants/app_breakpoints.dart';

/// Builder widget providing adaptive layouts based on current width constraints.
class AdaptiveLayout extends StatelessWidget {
  const AdaptiveLayout({
    required this.compact,
    this.medium,
    this.expanded,
    super.key,
  });

  /// Widget to render on Compact screens (width < 600dp, typically phones).
  final WidgetBuilder compact;

  /// Widget to render on Medium screens (width 600dp - 839dp, tablet portrait).
  final WidgetBuilder? medium;

  /// Widget to render on Expanded screens (width >= 840dp, tablet landscape / desktop).
  final WidgetBuilder? expanded;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        if (width >= AppBreakpoints.expandedMin && expanded != null) {
          return expanded!(context);
        }
        if (width >= AppBreakpoints.mediumMin && medium != null) {
          return medium!(context);
        }
        return compact(context);
      },
    );
  }
}
