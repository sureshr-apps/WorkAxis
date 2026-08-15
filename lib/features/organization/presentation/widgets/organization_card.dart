import 'package:flutter/material.dart';
import 'package:workaxis/core/constants/app_radius.dart';
import 'package:workaxis/core/constants/app_spacing.dart';
import 'package:workaxis/core/theme/app_colors.dart';
import 'package:workaxis/features/access_control/domain/entities/organization_membership.dart';

class OrganizationCard extends StatelessWidget {
  const OrganizationCard({
    required this.membership,
    required this.onTap,
    this.isActive = false,
    this.isDisabled = false,
    super.key,
  });

  final OrganizationMembership membership;
  final VoidCallback onTap;
  final bool isActive;
  final bool isDisabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final org = membership.organization;

    return Card(
      elevation: isActive ? 2 : 0,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.borderDefault,
        side: BorderSide(
          color: isActive
              ? AppColors.primary
              : (isDisabled
                  ? AppColors.outlineVariant.withValues(alpha: 0.5)
                  : AppColors.outlineVariant),
          width: isActive ? 2 : 1,
        ),
      ),
      color: isDisabled
          ? AppColors.surfaceContainerLow
          : (isActive
              ? AppColors.surfaceContainerLowest
              : AppColors.surfaceContainerLowest),
      child: InkWell(
        onTap: isDisabled ? null : onTap,
        borderRadius: AppRadius.borderDefault,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              // Org Avatar
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.primaryContainer
                      : AppColors.surfaceContainerHigh,
                  borderRadius: AppRadius.borderDefault,
                ),
                child: Center(
                  child: Icon(
                    Icons.business_rounded,
                    color: isActive
                        ? AppColors.onPrimaryContainer
                        : AppColors.primary,
                    size: 26,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              // Org Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            org.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isDisabled
                                  ? AppColors.onSurfaceVariant
                                  : AppColors.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isActive)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: 2,
                            ),
                            decoration: const BoxDecoration(
                              color: AppColors.primaryFixed,
                              borderRadius: AppRadius.borderFull,
                            ),
                            child: Text(
                              'Active',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: 2,
                          ),
                          decoration: const BoxDecoration(
                            color: AppColors.surfaceContainerHigh,
                            borderRadius: AppRadius.borderSm,
                          ),
                          child: Text(
                            membership.role.displayName,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ),
                        if (membership.branchName != null) ...[
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              membership.branchName!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Icon(
                Icons.chevron_right_rounded,
                color: isDisabled
                    ? AppColors.outlineVariant
                    : AppColors.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
