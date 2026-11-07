import 'package:flutter/material.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/core/constants/app_breakpoints.dart';
import 'package:workaxis/core/responsive/content_width_scope.dart';

/// Canonical, responsive layout template for KPI sections across all viewports.
///
/// The layout is chosen from the content width published by the enclosing page
/// ([ContentWidthScope], which excludes the sidebar), falling back to the screen
/// width. A `LayoutBuilder` is deliberately avoided: this widget is embedded in
/// `IntrinsicHeight` rows, which cannot size a `LayoutBuilder`.
///
/// - **Compact (< 600dp available)**:
///   Full-width horizontal swipeable PageView with pagination dots.
/// - **Medium (600dp – 839dp available)**:
///   Balanced 2-column grid spanning 100% width.
/// - **Expanded (>= 840dp available)**:
///   Balanced single-row grid; falls back to 2 columns if cards would be
///   narrower than [minCardWidth].
///
/// Cards have a minimum height of [cardHeight] and grow with text scale.
class ResponsiveKpiSection extends StatefulWidget {
  final List<Widget> cards;
  final double cardHeight;
  final double minCardWidth;

  const ResponsiveKpiSection({
    super.key,
    required this.cards,
    this.cardHeight = 96,
    this.minCardWidth = 160,
  });

  @override
  State<ResponsiveKpiSection> createState() => _ResponsiveKpiSectionState();
}

class _ResponsiveKpiSectionState extends State<ResponsiveKpiSection> {
  int _currentPage = 0;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 1.0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Width available to the content (after the sidebar), not the screen.
    final width = ContentWidthScope.of(context);
    if (width < AppBreakpoints.mediumMin) return _buildCarousel(context);
    if (width < AppBreakpoints.expandedMin) return _buildGrid(columns: 2);

    final cards = widget.cards;
    final perCard =
        (width - AppSpacing.md * (cards.length - 1)) /
        (cards.isEmpty ? 1 : cards.length);
    final columns = perCard >= widget.minCardWidth ? cards.length : 2;
    return _buildGrid(columns: columns < 1 ? 1 : columns);
  }

  Widget _buildCarousel(BuildContext context) {
    final cards = widget.cards;
    // The carousel needs a bounded height; scale it with the text scale so
    // larger fonts do not overflow.
    final scaledHeight = MediaQuery.textScalerOf(context)
        .scale(widget.cardHeight);
    final height = scaledHeight < widget.cardHeight
        ? widget.cardHeight
        : scaledHeight;

    return Column(
      children: [
        SizedBox(
          height: height,
          child: PageView.builder(
            controller: _pageController,
            padEnds: false,
            physics: const BouncingScrollPhysics(),
            itemCount: cards.length,
            onPageChanged: (idx) => setState(() => _currentPage = idx),
            itemBuilder: (context, index) => cards[index],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(cards.length, (index) {
            final isSelected = index == _currentPage;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: isSelected ? 20 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary
                    : AppColors.outlineVariant,
                borderRadius: BorderRadius.circular(999),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildGrid({required int columns}) {
    final cards = widget.cards;
    final rows = <Widget>[];
    for (var start = 0; start < cards.length; start += columns) {
      final children = <Widget>[];
      for (var offset = 0; offset < columns; offset++) {
        if (offset > 0) children.add(const SizedBox(width: AppSpacing.md));
        final index = start + offset;
        children.add(
          Expanded(
            child: index < cards.length
                ? ConstrainedBox(
                    constraints: BoxConstraints(minHeight: widget.cardHeight),
                    child: cards[index],
                  )
                : const SizedBox.shrink(),
          ),
        );
      }
      if (rows.isNotEmpty) rows.add(const SizedBox(height: AppSpacing.md));
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      );
    }
    return Column(children: rows);
  }
}
