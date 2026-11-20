import 'dart:async';

import 'package:flutter/material.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/features/plans/domain/models/license_plan.dart';
import 'package:workaxis/features/plans/presentation/widgets/license_plan_card.dart';

/// Sliver of plan cards: one column on phones, [columns] equal-height columns
/// on wider layouts. Rows are built lazily.
class LicensePlanCardList extends StatelessWidget {
  const LicensePlanCardList({
    super.key,
    required this.plans,
    required this.columns,
    required this.onEdit,
    required this.onToggleStatus,
    required this.onDelete,
  });

  final List<LicensePlan> plans;
  final int columns;
  final FutureOr<void> Function(LicensePlan) onEdit;
  final FutureOr<void> Function(LicensePlan) onToggleStatus;
  final FutureOr<void> Function(LicensePlan) onDelete;

  @override
  Widget build(BuildContext context) {
    final rowCount = (plans.length / columns).ceil();
    return SliverList.separated(
      itemCount: rowCount,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, row) {
        Widget cardAt(int index) => LicensePlanCard(
          plan: plans[index],
          onEdit: () => onEdit(plans[index]),
          onToggleStatus: () => onToggleStatus(plans[index]),
          onDelete: () => onDelete(plans[index]),
        );
        if (columns == 1) return cardAt(row);

        final cells = <Widget>[];
        for (var col = 0; col < columns; col++) {
          final index = row * columns + col;
          if (col > 0) cells.add(const SizedBox(width: AppSpacing.md));
          cells.add(
            Expanded(
              child: index < plans.length
                  ? cardAt(index)
                  : const SizedBox.shrink(),
            ),
          );
        }
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: cells,
          ),
        );
      },
    );
  }
}
