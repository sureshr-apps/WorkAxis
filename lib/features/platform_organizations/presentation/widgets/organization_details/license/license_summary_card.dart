import 'package:flutter/material.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/app/theme/app_typography.dart';
import 'package:workaxis/core/widgets/app_button.dart';
import 'package:workaxis/core/widgets/status_chip.dart';
import 'package:workaxis/features/platform_organizations/domain/models/organization_license_details.dart';
import 'package:workaxis/features/platform_organizations/presentation/widgets/organization_details/license/license_formatters.dart';
import 'package:workaxis/features/platform_organizations/presentation/widgets/organization_details/license/license_shared_widgets.dart';

/// Plan name, status, expiry and the plan-level actions.
class LicenseSummaryCard extends StatelessWidget {
  const LicenseSummaryCard({
    super.key,
    required this.license,
    required this.today,
    required this.onAction,
  });

  final OrganizationLicenseDetails license;
  final DateTime today;
  final ValueChanged<String> onAction;

  /// Width at which the actions sit beside the summary.
  static const double _inlineActionsWidth = 940;

  @override
  Widget build(BuildContext context) {
    return LicensePanel(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final summary = _Summary(license: license, today: today);
            final actions = Wrap(
              alignment: WrapAlignment.end,
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                AppButton.outlined(
                  text: 'Change Plan',
                  iconData: Icons.north_east,
                  isFullWidth: false,
                  onPressed: () => onAction('Change Plan'),
                ),
                AppButton.outlined(
                  text: 'Modify Commercial Terms',
                  iconData: Icons.payments_outlined,
                  isFullWidth: false,
                  onPressed: () => onAction('Modify Commercial Terms'),
                ),
                AppButton.primary(
                  text: 'Renew License',
                  iconData: Icons.sync,
                  isFullWidth: false,
                  onPressed: () => onAction('Renew License'),
                ),
              ],
            );
            if (constraints.maxWidth < _inlineActionsWidth) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  summary,
                  const SizedBox(height: AppSpacing.md),
                  actions,
                ],
              );
            }
            return Row(
              children: [
                Expanded(child: summary),
                const SizedBox(width: AppSpacing.md),
                actions,
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.license, required this.today});

  final OrganizationLicenseDetails license;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final isActive = license.status.toLowerCase() == 'active';
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.tertiaryContainer.withValues(alpha: 0.12),
            border: Border.all(
              color: AppColors.tertiaryContainer.withValues(alpha: 0.25),
            ),
            borderRadius: AppSpacing.roundedSm,
          ),
          child: const Icon(
            Icons.verified_user_outlined,
            size: 22,
            color: AppColors.tertiary,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                children: [
                  Text(
                    license.planName,
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  StatusChip(
                    label: license.status.toUpperCase(),
                    type: isActive ? StatusType.active : StatusType.urgent,
                    width: 96,
                  ),
                  LicenseSmallBadge(label: 'LEVEL ${license.level}'),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  const Icon(
                    Icons.schedule_outlined,
                    size: 14,
                    color: AppColors.secondary,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Flexible(
                    child: Text(
                      LicenseFormatters.expiryLabel(license, today),
                      style: AppTypography.bodySmall,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
