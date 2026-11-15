import 'package:flutter/material.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_shadows.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/app/theme/app_typography.dart';
import 'package:workaxis/core/responsive/responsive_layout.dart';
import 'package:workaxis/core/widgets/organization_metrics_row.dart';
import 'package:workaxis/core/widgets/status_chip.dart';
import 'package:workaxis/features/platform_organizations/domain/models/customer_organization.dart';

const BoxConstraints _touchTarget = BoxConstraints(
  minWidth: AppSpacing.minTouchTarget,
  minHeight: AppSpacing.minTouchTarget,
);

/// Card for a customer organization on smartphone and tablet widths.
///
/// Tapping the card opens the organization on every width. Smartphones
/// (compact width) show a chevron beside the status and nothing else; wider
/// layouts also show edit, delete and "Details" actions.
class OrganizationCardItem extends StatelessWidget {
  const OrganizationCardItem({
    super.key,
    required this.organization,
    required this.onTap,
    required this.onEdit,
    this.onDelete,
  });

  final CustomerOrganization organization;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final compact = context.isCompact;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: AppSpacing.roundedMd,
        border: Border.all(color: AppColors.outlineSubtle),
        boxShadow: AppShadows.card,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppSpacing.roundedMd,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            organization.name,
                            style: AppTypography.titleMedium.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          _CodeBadge(code: organization.code),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    StatusChip.fromStatus(
                      organization.status.displayName,
                      width: 96,
                    ),
                    // Phones show only a chevron: the whole card is the
                    // tap target and edit/delete live on the details page.
                    if (compact) ...const [
                      SizedBox(width: AppSpacing.xs),
                      Padding(
                        padding: EdgeInsets.only(top: AppSpacing.xxs),
                        child: Icon(
                          Icons.chevron_right_rounded,
                          size: 24,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                OrganizationMetricsRow(
                  hubCount: organization.branchCount,
                  staffCount: organization.employeeCount,
                  onboardedOn: organization.createdAt,
                ),
                if (!compact) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        tooltip: 'Edit ${organization.name}',
                        icon: const Icon(
                          Icons.edit_outlined,
                          size: 18,
                          color: AppColors.secondary,
                        ),
                        constraints: _touchTarget,
                        onPressed: onEdit,
                      ),
                      if (onDelete != null)
                        IconButton(
                          tooltip: 'Delete ${organization.name}',
                          icon: const Icon(
                            Icons.delete_outline,
                            size: 18,
                            color: AppColors.statusUrgentText,
                          ),
                          constraints: _touchTarget,
                          onPressed: onDelete,
                        ),
                      ConstrainedBox(
                        constraints: const BoxConstraints(
                          minHeight: AppSpacing.minTouchTarget,
                        ),
                        child: Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Details',
                                style: AppTypography.labelMedium.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right_rounded,
                                size: 16,
                                color: AppColors.primary,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CodeBadge extends StatelessWidget {
  const _CodeBadge({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: AppSpacing.roundedXs,
        border: Border.all(color: AppColors.outlineSubtle),
      ),
      child: Text(
        code,
        style: AppTypography.labelMono.copyWith(
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
      ),
    );
  }
}
