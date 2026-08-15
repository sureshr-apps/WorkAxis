import 'package:flutter/material.dart';
import 'package:workaxis/core/constants/app_radius.dart';
import 'package:workaxis/core/constants/app_spacing.dart';
import 'package:workaxis/core/theme/app_colors.dart';
import 'package:workaxis/features/access_control/domain/entities/organization_membership.dart';
import 'package:workaxis/features/organization/presentation/widgets/organization_card.dart';

class OrganizationSwitcherSheet extends StatelessWidget {
  const OrganizationSwitcherSheet({
    required this.memberships,
    required this.activeMembership,
    required this.onSelect,
    super.key,
  });

  final List<OrganizationMembership> memberships;
  final OrganizationMembership activeMembership;
  final ValueChanged<OrganizationMembership> onSelect;

  static Future<void> show({
    required BuildContext context,
    required List<OrganizationMembership> memberships,
    required OrganizationMembership activeMembership,
    required ValueChanged<OrganizationMembership> onSelect,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (ctx) => OrganizationSwitcherSheet(
        memberships: memberships,
        activeMembership: activeMembership,
        onSelect: onSelect,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.marginCompact,
          vertical: AppSpacing.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: const BoxDecoration(
                  color: AppColors.outlineVariant,
                  borderRadius: AppRadius.borderFull,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Switch Organization',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Select an organization workspace to switch your role and context.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: memberships.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, index) {
                  final membership = memberships[index];
                  final isCurrent = membership.organizationId ==
                      activeMembership.organizationId;
                  return OrganizationCard(
                    membership: membership,
                    isActive: isCurrent,
                    onTap: () {
                      Navigator.of(context).pop();
                      if (!isCurrent) {
                        onSelect(membership);
                      }
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }
}
