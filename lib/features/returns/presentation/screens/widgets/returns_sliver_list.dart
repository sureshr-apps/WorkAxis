import 'package:flutter/material.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/core/constants/app_breakpoints.dart';
import 'package:workaxis/features/returns/domain/models/return_item.dart';
import 'package:workaxis/features/returns/presentation/screens/widgets/return_card_item.dart';
import 'package:workaxis/features/returns/presentation/screens/widgets/returns_table.dart';

/// Lazy list of returns that picks its composition from the available width:
/// a table when wide, two card columns on medium widths, one column otherwise.
class SliverReturnsList extends StatelessWidget {
  const SliverReturnsList({
    super.key,
    required this.items,
    required this.columns,
    required this.onOpen,
    this.showReviewAction = false,
  });

  final List<ReturnItem> items;
  final List<ReturnsTableColumn> columns;
  final void Function(ReturnItem item) onOpen;
  final bool showReviewAction;

  @override
  Widget build(BuildContext context) {
    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.crossAxisExtent;
        if (width >= AppBreakpoints.wideContent) {
          return SliverReturnsTable(items: items, columns: columns);
        }
        if (width >= AppBreakpoints.mediumMin) {
          return _twoColumnCards(context);
        }
        return SliverList.separated(
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
          itemBuilder: (_, index) => _card(items[index]),
        );
      },
    );
  }

  /// Cards contain intrinsic-hostile widgets (LayoutBuilder buttons), so rows
  /// get a fixed extent that grows with the text scale instead of stretching.
  Widget _twoColumnCards(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    return SliverGrid.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AppSpacing.md,
        mainAxisSpacing: AppSpacing.md,
        mainAxisExtent: 110 + 100 * textScale,
      ),
      itemCount: items.length,
      itemBuilder: (_, index) => _card(items[index]),
    );
  }

  Widget _card(ReturnItem item) => ReturnCardItem(
    item: item,
    showReviewAction: showReviewAction,
    onTap: () => onOpen(item),
    onReview: () => onOpen(item),
  );
}
