import 'package:flutter/widgets.dart';
import 'package:workaxis/core/constants/app_breakpoints.dart';
import 'package:workaxis/core/responsive/responsive_layout.dart';

/// Standard page wrapper providing consistent maximum width (1440dp matching Home page)
/// and adaptive responsive padding across compact, tablet, and desktop viewports.
class ResponsivePageContent extends StatelessWidget {
  const ResponsivePageContent({
    super.key,
    required this.child,
    this.maxWidth = AppBreakpoints.maxPageWidth,
    this.padding,
    this.alignment = Alignment.topCenter,
  });

  /// The inner content of the page (typically a Column).
  final Widget child;

  /// Maximum allowed width for content (defaults to [AppBreakpoints.maxPageWidth] = 1440).
  final double maxWidth;

  /// Optional override for page padding. When omitted, uses standard responsive page padding:
  /// - Compact (< 600): 16dp (AppSpacing.lg)
  /// - Medium (600 - 839): 24dp (AppSpacing.xl)
  /// - Expanded (>= 840): 32dp (AppSpacing.xxl)
  final EdgeInsetsGeometry? padding;

  /// Alignment within the outer viewport (defaults to [Alignment.topCenter]).
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    final effectivePadding = padding ?? context.responsivePagePadding;

    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: effectivePadding,
          child: child,
        ),
      ),
    );
  }
}
