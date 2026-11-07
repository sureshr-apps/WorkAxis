import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:workaxis/core/constants/app_breakpoints.dart';
import 'package:workaxis/core/responsive/responsive_layout.dart';

/// Gives a sliver the same horizontal inset and centered maximum width that
/// `ResponsivePageContent` gives box content, so lazily built lists line up
/// with the rest of the page.
class PageSliverPadding extends StatelessWidget {
  const PageSliverPadding({super.key, required this.sliver});

  final Widget sliver;

  @override
  Widget build(BuildContext context) {
    final inset = context.responsivePagePadding.left;
    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final centering = math.max(
          0.0,
          (constraints.crossAxisExtent - AppBreakpoints.maxPageWidth) / 2,
        );
        return SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: inset + centering),
          sliver: sliver,
        );
      },
    );
  }
}
