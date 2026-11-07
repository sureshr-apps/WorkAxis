import 'package:flutter/material.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/app/theme/app_typography.dart';
import 'package:workaxis/core/widgets/status_chip.dart';
import 'package:workaxis/features/platform_dashboard/domain/models/recent_organization_summary.dart';

/// Monospace organization code badge.
class OrganizationCodeBadge extends StatelessWidget {
  const OrganizationCodeBadge({super.key, required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
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

/// Active/Suspended chip for a recent organization.
class OrganizationStatusBadge extends StatelessWidget {
  const OrganizationStatusBadge({super.key, required this.org});

  final RecentOrganizationSummary org;

  @override
  Widget build(BuildContext context) => StatusChip(
    type: org.isActive ? StatusType.active : StatusType.urgent,
    label: org.isActive ? 'Active' : 'Suspended',
  );
}

/// "Details >" affordance at the end of a row or card.
class OrganizationDetailsLink extends StatelessWidget {
  const OrganizationDetailsLink({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Details',
          style: AppTypography.labelMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: AppSpacing.xxs),
        const Icon(
          Icons.chevron_right_rounded,
          size: 16,
          color: AppColors.primary,
        ),
      ],
    );
  }
}

/// "n branches / n staff" summary used by compact rows and cards.
class OrganizationCountsText extends StatelessWidget {
  const OrganizationCountsText({super.key, required this.org});

  final RecentOrganizationSummary org;

  @override
  Widget build(BuildContext context) {
    return Text(
      '${org.branchCount} branches • ${org.employeeCount} staff',
      style: AppTypography.bodySmall,
    );
  }
}
