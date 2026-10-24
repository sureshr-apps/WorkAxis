import 'package:flutter/widgets.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/core/constants/app_breakpoints.dart';

export 'responsive_page_content.dart';

/// Screen form factor classification based on available width.
enum DeviceScreenType {
  compact,
  medium,
  expanded;

  bool get isCompact => this == DeviceScreenType.compact;
  bool get isMedium => this == DeviceScreenType.medium;
  bool get isExpanded => this == DeviceScreenType.expanded;
}

/// Extension on [BuildContext] for ergonomic breakpoint inspection.
extension ResponsiveContext on BuildContext {
  double get screenWidth => MediaQuery.sizeOf(this).width;
  double get screenHeight => MediaQuery.sizeOf(this).height;

  DeviceScreenType get screenType {
    final width = screenWidth;
    if (width < AppBreakpoints.mediumMin) {
      return DeviceScreenType.compact;
    } else if (width < AppBreakpoints.expandedMin) {
      return DeviceScreenType.medium;
    } else {
      return DeviceScreenType.expanded;
    }
  }

  bool get isCompact => screenType.isCompact;
  bool get isMedium => screenType.isMedium;
  bool get isExpanded => screenType.isExpanded;

  /// Canonical responsive page padding matching the Home page reference:
  /// - Compact (< 600): 16dp (AppSpacing.lg)
  /// - Medium (600 - 839): 24dp (AppSpacing.xl)
  /// - Expanded (>= 840): 32dp (AppSpacing.xxl)
  EdgeInsets get responsivePagePadding => EdgeInsets.symmetric(
        horizontal: isCompact
            ? AppSpacing.lg
            : (isMedium ? AppSpacing.xl : AppSpacing.xxl),
        vertical: isCompact
            ? AppSpacing.lg
            : (isMedium ? AppSpacing.xl : AppSpacing.xxl),
      );
}

/// A widget that conditionally builds layouts based on available viewport width.
class ResponsiveLayout extends StatelessWidget {
  const ResponsiveLayout({
    super.key,
    required this.compact,
    this.medium,
    this.expanded,
  });

  /// Layout for smartphone widths (< 600dp).
  final WidgetBuilder compact;

  /// Layout for tablet portrait/medium widths (600dp - 839dp).
  final WidgetBuilder? medium;

  /// Layout for desktop web / tablet landscape widths (>= 840dp).
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
