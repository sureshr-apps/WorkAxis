import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/core/responsive/responsive_layout.dart';
import 'package:workaxis/core/widgets/status_chip.dart';
import 'package:workaxis/features/organization_dashboard/domain/models/attention_item.dart';

/// Needs Attention column section adhering strictly to Stitch layout geometry.
class AttentionItemsSection extends StatelessWidget {
  final List<AttentionItem> items;
  final VoidCallback? onViewAll;

  const AttentionItemsSection({super.key, required this.items, this.onViewAll});

  @override
  Widget build(BuildContext context) {
    final isCompact = context.isCompact;

    return Container(
      padding: EdgeInsets.all(isCompact ? AppSpacing.md : AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outlineSubtle, width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A191C20),
            offset: Offset(0, 1),
            blurRadius: 3,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          LayoutBuilder(
            builder: (context, headerConstraints) {
              final isCompactHeader = headerConstraints.maxWidth < 320;
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Flexible(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            'Needs Attention',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.onSurface,
                              letterSpacing: -0.2,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Container(
                          width: 20,
                          height: 20,
                          decoration: const BoxDecoration(
                            color: AppColors.statusUrgentContainer,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${items.length}',
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.statusUrgentText,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  InkWell(
                    onTap: onViewAll,
                    borderRadius: BorderRadius.circular(4),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 2,
                        horizontal: 4,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'View all',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                          if (!isCompactHeader)
                            Text(
                              ' • ACTION ITEMS',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.secondary,
                                letterSpacing: 0.5,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 4),

          // Subtitle
          Text(
            'Immediate escalations requiring administrative sign-off or branch follow-up',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: AppColors.secondary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Attention Cards List
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'No items currently require attention.',
                  style: GoogleFonts.inter(color: AppColors.secondary),
                ),
              ),
            )
          else if (isCompact)
            // Mobile: Horizontal swipeable cards with next card peek
            SizedBox(
              height: 154,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: items.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(width: AppSpacing.sm),
                itemBuilder: (context, index) {
                  return SizedBox(
                    width: 280,
                    child: _buildItemCard(context, items[index]),
                  );
                },
              ),
            )
          else
            // Tablet & Desktop: Stacked cards
            Column(
              children: items.map((item) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: _buildItemCard(context, item),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildItemCard(BuildContext context, AttentionItem item) {
    // Resolve semantic icon and colors
    final IconData icon =
        item.itemIcon ??
        (item.statusType == StatusType.urgent
            ? Icons.timer_off
            : item.statusType == StatusType.pending
            ? Icons.assignment_return
            : item.statusType == StatusType.neutral
            ? Icons.domain_disabled
            : Icons.swap_horiz);

    final Color iconBg = item.statusType == StatusType.urgent
        ? AppColors.statusUrgentContainer
        : item.statusType == StatusType.pending
        ? AppColors.statusPendingContainer
        : item.statusType == StatusType.neutral
        ? AppColors.surfaceContainerHigh
        : AppColors.primaryContainer;

    final Color iconColor = item.statusType == StatusType.urgent
        ? AppColors.statusUrgentText
        : item.statusType == StatusType.pending
        ? AppColors.statusPendingText
        : item.statusType == StatusType.neutral
        ? AppColors.onSurfaceVariant
        : AppColors.onPrimaryContainer;

    final Color badgeColor = item.statusType == StatusType.urgent
        ? AppColors.error
        : item.statusType == StatusType.pending
        ? AppColors.statusPendingText
        : item.statusType == StatusType.neutral
        ? AppColors.secondary
        : AppColors.primary;

    final String badgeText = item.badgeText ?? item.statusLabel;
    final String actionLabel = item.actionLabel ?? 'Review';
    final IconData actionIcon = item.actionIcon ?? Icons.arrow_forward;
    final bool isPrimaryAction =
        item.actionLabel == 'Review Returns' || item.actionLabel == 'Review';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(child: Icon(icon, size: 18, color: iconColor)),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.onSurface,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          badgeText,
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: badgeColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.details,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: AppColors.onSurfaceVariant,
                        height: 1.35,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // Bottom Action Button
          Align(
            alignment: Alignment.centerRight,
            child: Material(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(8),
              elevation: 0,
              child: InkWell(
                onTap: () {},
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  height: 32,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.outlineSubtle,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        actionLabel,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isPrimaryAction
                              ? AppColors.primary
                              : AppColors.onSurface,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        actionIcon,
                        size: 14,
                        color: isPrimaryAction
                            ? AppColors.primary
                            : AppColors.onSurface,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
