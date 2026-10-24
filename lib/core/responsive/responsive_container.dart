import 'package:flutter/widgets.dart';
import 'package:workaxis/core/constants/app_breakpoints.dart';

/// Wraps child content with a centered max-width constraint for wide tablet and desktop screens.
class ResponsiveContainer extends StatelessWidget {
  const ResponsiveContainer({
    super.key,
    required this.child,
    this.maxWidth = AppBreakpoints.maxContentWidth,
    this.padding = EdgeInsets.zero,
    this.alignment = Alignment.topCenter,
  });

  /// Maximum allowed width for content.
  final double maxWidth;

  /// External padding around the constrained area.
  final EdgeInsetsGeometry padding;

  /// Alignment within the outer available space.
  final AlignmentGeometry alignment;

  /// Inner child content.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Padding(
        padding: padding,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: child,
        ),
      ),
    );
  }
}
