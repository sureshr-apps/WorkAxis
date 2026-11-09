import 'package:flutter/material.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_shadows.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/app/theme/app_typography.dart';
import 'package:workaxis/core/formatting/date_time_formatters.dart';
import 'package:workaxis/core/widgets/status_chip.dart';
import 'package:workaxis/features/platform_organizations/domain/models/customer_organization.dart';

/// Card for a customer organization on smartphone and tablet widths.
///
/// Tapping the card (or "Details") opens the organization; the pencil button
/// opens the edit form.
class OrganizationCardItem extends StatelessWidget {
  const OrganizationCardItem({
    super.key,
    required this.organization,
    required this.onTap,
    required this.onEdit,
  });

  final CustomerOrganization organization;
  final VoidCallback onTap;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
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
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                _MetricsRow(organization: organization),
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
                      onPressed: onEdit,
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

class _MetricsRow extends StatelessWidget {
  const _MetricsRow({required this.organization});

  final CustomerOrganization organization;

  @override
  Widget build(BuildContext context) {
    const divider = SizedBox(
      height: 20,
      child: VerticalDivider(width: 1, color: AppColors.outlineSubtle),
    );
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: AppSpacing.roundedSm,
        border: Border.all(
          color: AppColors.outlineSubtle.withValues(alpha: 0.6),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _Metric(
            value: organization.branchCount?.toString() ?? '—',
            label: 'hubs',
            icon: Icons.storefront_outlined,
          ),
          divider,
          _Metric(
            value: organization.employeeCount?.toString() ?? '—',
            label: 'staff',
            icon: Icons.people_outline,
          ),
          divider,
          _Metric(
            value: AppFormatters.formatDate(organization.createdAt),
            label: 'onboarded',
            icon: Icons.calendar_today_outlined,
            isDate: true,
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.value,
    required this.label,
    required this.icon,
    this.isDate = false,
  });

  final String value;
  final String label;
  final IconData icon;
  final bool isDate;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppColors.secondary),
            const SizedBox(width: AppSpacing.xs),
            Text(
              value,
              style: isDate
                  ? AppTypography.labelSmall.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurface,
                    )
                  : AppTypography.labelMono.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
            ),
          ],
        ),
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(color: AppColors.secondary),
        ),
      ],
    );
  }
}
