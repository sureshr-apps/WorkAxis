import 'package:flutter/material.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/app/theme/app_typography.dart';
import 'package:workaxis/core/widgets/app_page_header.dart';
import 'package:workaxis/core/widgets/status_chip.dart';
import 'package:workaxis/features/platform_organizations/domain/models/customer_organization.dart';

/// Page header for editing an organization: title plus code, status and an
/// "Unsaved Changes" marker.
class EditOrganizationHeader extends StatelessWidget {
  const EditOrganizationHeader({
    super.key,
    required this.organization,
    required this.isDirty,
  });

  final CustomerOrganization organization;
  final bool isDirty;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppPageHeader(
          eyebrow: 'Platform catalog',
          title: 'Edit Organization',
          subtitle:
              'Update the details for this customer organization. Changes are '
              'logged to the platform audit registry.',
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHigh,
                borderRadius: AppSpacing.roundedXs,
              ),
              child: Text(
                '# ${organization.code}',
                style: AppTypography.labelMono.copyWith(
                  fontSize: 12,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ),
            StatusChip.fromStatus(organization.status.displayName, width: 96),
            if (isDirty) const _UnsavedChangesBadge(),
          ],
        ),
      ],
    );
  }
}

class _UnsavedChangesBadge extends StatelessWidget {
  const _UnsavedChangesBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.statusPendingContainer,
        borderRadius: AppSpacing.roundedPill,
        border: Border.all(color: AppColors.statusPendingBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.change_circle_outlined,
            size: 14,
            color: AppColors.statusPendingText,
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            'Unsaved Changes',
            style: AppTypography.labelSmall.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.statusPendingText,
            ),
          ),
        ],
      ),
    );
  }
}
