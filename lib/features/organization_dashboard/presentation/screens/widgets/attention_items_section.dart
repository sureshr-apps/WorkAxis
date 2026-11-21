import 'package:flutter/material.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/app/theme/app_typography.dart';
import 'package:workaxis/core/responsive/responsive_layout.dart';
import 'package:workaxis/core/widgets/empty_state.dart';
import 'package:workaxis/features/organization_dashboard/domain/models/attention_item.dart';
import 'package:workaxis/features/organization_dashboard/presentation/attention_item_presentation.dart';
import 'package:workaxis/features/organization_dashboard/presentation/screens/widgets/attention_item_card.dart';
import 'package:workaxis/shared/widgets/dashboard_surface_card.dart';

/// "Needs Attention" section shared by the organization and branch dashboards.
class AttentionItemsSection extends StatelessWidget {
  const AttentionItemsSection({
    super.key,
    required this.items,
    required this.branchScope,
    this.onItemAction,
  });

  final List<AttentionItem> items;

  /// True when shown on the branch manager dashboard (affects item routes).
  final bool branchScope;

  /// Invoked with an item and its destination route.
  final void Function(AttentionItem item, String route)? onItemAction;

  @override
  Widget build(BuildContext context) {
    return DashboardSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Header(count: items.length),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Escalations requiring sign-off or follow-up',
            style: AppTypography.bodySmall.copyWith(color: AppColors.secondary),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (items.isEmpty)
            const EmptyState(
              icon: Icons.check_circle_outline,
              title: 'No items currently require attention.',
            )
          else if (context.isCompact)
            LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var index = 0; index < items.length; index++)
                      Padding(
                        padding: EdgeInsets.only(
                          right: index == items.length - 1 ? 0 : AppSpacing.sm,
                        ),
                        child: SizedBox(
                          width: constraints.maxWidth,
                          child: _card(items[index]),
                        ),
                      ),
                  ],
                ),
              ),
            )
          else
            Column(
              children: [
                for (final item in items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: _card(item),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _card(AttentionItem item) {
    final route = item.routeFor(branchScope: branchScope);
    return AttentionItemCard(
      item: item,
      onAction: route == null || onItemAction == null
          ? null
          : () => onItemAction!(item, route),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Needs Attention',
            style: AppTypography.titleLarge.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Semantics(
          label: '$count items',
          child: Container(
            constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs + 2),
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.statusUrgentContainer,
              borderRadius: BorderRadius.all(
                Radius.circular(AppSpacing.radiusPill),
              ),
            ),
            child: Text(
              '$count',
              style: AppTypography.labelMono.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.statusUrgentText,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
