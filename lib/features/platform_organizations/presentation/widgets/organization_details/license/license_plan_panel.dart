import 'package:flutter/material.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/app/theme/app_typography.dart';
import 'package:workaxis/core/constants/app_breakpoints.dart';
import 'package:workaxis/core/widgets/kpi/app_kpi_card.dart';
import 'package:workaxis/features/platform_organizations/domain/models/organization_license.dart';
import 'package:workaxis/features/platform_organizations/presentation/widgets/organization_details/license/license_formatters.dart';
import 'package:workaxis/features/platform_organizations/presentation/widgets/organization_details/license/license_shared_widgets.dart';

/// Entitlements of the license plan. The limits come from the live plan row, so
/// they are read-only here and change only through the plan itself.
class LicensePlanPanel extends StatelessWidget {
  const LicensePlanPanel({super.key, required this.plan});

  final OrganizationLicensePlan plan;

  @override
  Widget build(BuildContext context) {
    return LicensePanel(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Row(
              children: [
                Expanded(
                  child: LicenseSectionHeading(title: 'PLAN ENTITLEMENTS'),
                ),
                LicenseSmallBadge(
                  label: 'Defined by Plan',
                  icon: Icons.lock_outline,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Usage quotas defined by ${plan.name}',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            LayoutBuilder(
              builder: (context, constraints) {
                final stores = _limitCard(
                  title: 'Maximum Stores',
                  value: plan.maxStores,
                  icon: Icons.storefront_outlined,
                );
                final users = _limitCard(
                  title: 'Maximum Users',
                  value: plan.maxUsers,
                  icon: Icons.people_outline,
                );
                if (constraints.maxWidth >= AppBreakpoints.wideTable) {
                  return Row(
                    children: [
                      Expanded(child: stores),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(child: users),
                    ],
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    stores,
                    const SizedBox(height: AppSpacing.sm),
                    users,
                  ],
                );
              },
            ),
            if (!plan.isActive) ...[
              const SizedBox(height: AppSpacing.md),
              const _Note(
                'This plan is inactive, so this license does not grant access '
                'until the organization moves to an active plan.',
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            const _Note(
              'Entitlements cannot be overridden at organization level. '
              'Organizations requiring higher capacity must move to a '
              'higher-level active plan via Change Plan.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _limitCard({
    required String title,
    required int value,
    required IconData icon,
  }) => AppKpiCard(
    title: title,
    value: LicenseFormatters.count(value),
    icon: icon,
    iconColor: AppColors.primary,
    iconBgColor: AppColors.primaryContainer,
    accentColor: AppColors.primaryDark,
  );
}

class _Note extends StatelessWidget {
  const _Note(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: AppColors.surfaceContainerLow,
      border: Border.all(color: AppColors.outlineSubtle),
      borderRadius: AppSpacing.roundedXs,
    ),
    child: Text(text, style: licenseBodyStyle),
  );
}
