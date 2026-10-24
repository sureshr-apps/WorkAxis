import 'package:flutter/material.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/core/responsive/responsive_layout.dart';

/// Canonical, responsive layout template for KPI sections across all viewports.
///
/// Responsive Adaptations:
/// - **Smartphone (`isCompact`, < 600dp)**:
///   Full-width horizontal swipeable PageView with pagination dots. Each tile
///   spans 100% width, aligning perfectly with other screen sections.
/// - **Tablet (`isMedium`, 600dp – 839dp)**:
///   Balanced 2-column grid (rows of 2 `Expanded` cards) spanning 100% width.
/// - **Desktop / Web (`expanded`, ≥ 840dp)**:
///   Balanced single-row grid (all cards in a single `Row` of `Expanded` cards).
class ResponsiveKpiSection extends StatefulWidget {
  final List<Widget> cards;
  final double cardHeight;

  const ResponsiveKpiSection({
    super.key,
    required this.cards,
    this.cardHeight = 96,
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
    final isCompact = context.isCompact;
    final isMedium = context.isMedium;
    final cards = widget.cards;

    if (isCompact) {
      // Smartphone: Full-width swipeable PageView with animated pagination dots
      return Column(
        children: [
          SizedBox(
            height: widget.cardHeight,
            child: PageView.builder(
              controller: _pageController,
              padEnds: false,
              physics: const BouncingScrollPhysics(),
              itemCount: cards.length,
              onPageChanged: (idx) {
                setState(() => _currentPage = idx);
              },
              itemBuilder: (context, index) {
                return cards[index];
              },
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
    } else if (isMedium) {
      // Tablet: 2-column balanced grid spanning 100% width
      final rows = <Widget>[];
      for (int i = 0; i < cards.length; i += 2) {
        final card1 = cards[i];
        final card2 = (i + 1 < cards.length) ? cards[i + 1] : null;

        rows.add(
          Row(
            children: [
              Expanded(
                child: SizedBox(height: widget.cardHeight, child: card1),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: card2 != null
                    ? SizedBox(height: widget.cardHeight, child: card2)
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        );
        if (i + 2 < cards.length) {
          rows.add(const SizedBox(height: AppSpacing.md));
        }
      }

      return Column(children: rows);
    } else {
      // Desktop / Web: Balanced N-column row spanning 100% width
      return Row(
        children: [
          for (int i = 0; i < cards.length; i++) ...[
            if (i > 0) const SizedBox(width: AppSpacing.md),
            Expanded(
              child: SizedBox(height: widget.cardHeight, child: cards[i]),
            ),
          ],
        ],
      );
    }
  }
}
