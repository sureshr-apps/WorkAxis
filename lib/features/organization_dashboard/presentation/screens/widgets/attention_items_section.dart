import 'package:flutter/material.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/app/theme/app_typography.dart';
import 'package:workaxis/core/responsive/responsive_layout.dart';
import 'package:workaxis/core/widgets/app_button.dart';
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
    this.onViewAll,
    this.onItemAction,
  });

  final List<AttentionItem> items;

  /// True when shown on the branch manager dashboard (affects item routes).
  final bool branchScope;

  /// Opens the full list; the link is hidden when null.
  final VoidCallback? onViewAll;

  /// Invoked with an item and its destination route.
  final void Function(AttentionItem item, String route)? onItemAction;

  static const double _compactCardWidth = 280;
  static const double _compactListHeight = 190;

  @override
  Widget build(BuildContext context) {
    return DashboardSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Header(count: items.length, onViewAll: onViewAll),
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
            SizedBox(
              height: _compactListHeight,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: items.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(width: AppSpacing.sm),
                itemBuilder: (_, index) => SizedBox(
                  width: _compactCardWidth,
                  child: _card(items[index]),
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
  const _Header({required this.count, this.onViewAll});

  final int count;
  final VoidCallback? onViewAll;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Flexible(
          child: Text(
            'Needs Attention',
            style: AppTypography.titleLarge.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
            ),
            overflow: TextOverflow.ellipsis,
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
        const Spacer(),
        if (onViewAll != null)
          AppButton.outlined(
            text: 'View all',
            isFullWidth: false,
            onPressed: onViewAll,
          ),
      ],
    );
  }
}
