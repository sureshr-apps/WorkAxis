import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:workaxis/core/constants/app_breakpoints.dart';
import 'package:workaxis/core/responsive/content_width_scope.dart';
import 'package:workaxis/core/responsive/responsive_layout.dart';

/// Scrollable page body built from slivers, so long lists stay lazy.
///
/// Applies the same centered max width and responsive padding as
/// `ResponsivePageContent` and publishes the usable width through
/// [ContentWidthScope] for adaptive descendants. Pass [onRefresh] to enable
/// pull-to-refresh.
class ResponsiveSliverPage extends StatelessWidget {
  const ResponsiveSliverPage({
    super.key,
    required this.slivers,
    this.onRefresh,
    this.maxWidth = AppBreakpoints.maxPageWidth,
  });

  final List<Widget> slivers;
  final Future<void> Function()? onRefresh;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final padding = context.responsivePagePadding;
    return LayoutBuilder(
      builder: (context, constraints) {
        final available = constraints.maxWidth;
        final contentOuter = math.min(available, maxWidth);
        final side = (available - contentOuter) / 2 + padding.left;
        final scrollView = CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                side,
                padding.top,
                side,
                padding.bottom,
              ),
              sliver: SliverMainAxisGroup(slivers: slivers),
            ),
          ],
        );
        return ContentWidthScope(
          width: contentOuter - 2 * padding.left,
          child: onRefresh == null
              ? scrollView
              : RefreshIndicator(onRefresh: onRefresh!, child: scrollView),
        );
      },
    );
  }
}
