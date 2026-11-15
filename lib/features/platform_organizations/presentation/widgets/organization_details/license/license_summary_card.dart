import 'package:flutter/material.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/app/theme/app_typography.dart';
import 'package:workaxis/core/widgets/app_button.dart';
import 'package:workaxis/core/widgets/status_chip.dart';
import 'package:workaxis/features/platform_organizations/domain/models/organization_license.dart';
import 'package:workaxis/features/platform_organizations/presentation/widgets/organization_details/license/license_display.dart';
import 'package:workaxis/features/platform_organizations/presentation/widgets/organization_details/license/license_formatters.dart';
import 'package:workaxis/features/platform_organizations/presentation/widgets/organization_details/license/license_shared_widgets.dart';

/// Plan, status, term and commercial terms of the license, with its actions.
class LicenseSummaryCard extends StatelessWidget {
  const LicenseSummaryCard({
    super.key,
    required this.license,
    required this.today,
    required this.canChangePlan,
    required this.onChangePlan,
    required this.onModifyTerms,
    required this.onRenew,
  });

  final OrganizationLicense license;

  /// Business date used for the contextual term line.
  final DateTime today;

  /// False when no active plan ranks above the current one.
  final bool canChangePlan;
  final VoidCallback onChangePlan;
  final VoidCallback onModifyTerms;
  final VoidCallback onRenew;

  /// Width at which the actions sit beside the summary instead of below it.
  static const double _inlineActionsWidth = 940;

  /// Width at which the three term figures share one row.
  static const double _inlineFiguresWidth = 560;

  @override
  Widget build(BuildContext context) {
    return LicensePanel(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final actions = _Actions(
              canChangePlan: canChangePlan,
              inline: constraints.maxWidth >= _inlineActionsWidth,
              onChangePlan: onChangePlan,
              onModifyTerms: onModifyTerms,
              onRenew: onRenew,
            );
            final header = _Header(license: license, today: today);
            if (constraints.maxWidth < _inlineActionsWidth) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  header,
                  const SizedBox(height: AppSpacing.md),
                  _Figures(
                    license: license,
                    inline:
                        constraints.maxWidth - AppSpacing.md * 2 >=
                        _inlineFiguresWidth,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  actions,
                ],
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: header),
                    const SizedBox(width: AppSpacing.md),
                    actions,
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                _Figures(license: license, inline: true),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.license, required this.today});

  final OrganizationLicense license;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final plan = license.plan;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
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
                    plan.name,
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  StatusChip(
                    label: license.status.label.toUpperCase(),
                    type: license.status.chipType,
                    width: null,
                  ),
                  LicenseSmallBadge(label: 'LEVEL ${plan.level}'),
                  if (!plan.isActive)
                    const LicenseSmallBadge(
                      label: 'PLAN INACTIVE',
                      icon: Icons.block,
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(
                      Icons.schedule_outlined,
                      size: 14,
                      color: AppColors.secondary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      LicenseFormatters.termNote(license, today),
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

/// Period, one-time price and annual maintenance price.
class _Figures extends StatelessWidget {
  const _Figures({required this.license, required this.inline});

  final OrganizationLicense license;
  final bool inline;

  @override
  Widget build(BuildContext context) {
    final period = _Figure(
      label: 'License Period',
      value: LicenseFormatters.period(license.startDate, license.expiryDate),
      monoValue: true,
    );
    final oneTime = _Figure(
      label: 'Negotiated Price (One-time)',
      value: LicenseFormatters.money(license.negotiatedPrice),
    );
    final maintenance = _Figure(
      label: 'Annual Maintenance Price',
      value: LicenseFormatters.money(license.maintenancePrice),
    );
    if (!inline) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          period,
          const SizedBox(height: AppSpacing.sm),
          oneTime,
          const SizedBox(height: AppSpacing.sm),
          maintenance,
        ],
      );
    }
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(flex: 3, child: period),
          const SizedBox(width: AppSpacing.md),
          Expanded(flex: 2, child: oneTime),
          const SizedBox(width: AppSpacing.md),
          Expanded(flex: 2, child: maintenance),
        ],
      ),
    );
  }
}

class _Figure extends StatelessWidget {
  const _Figure({
    required this.label,
    required this.value,
    this.monoValue = false,
  });

  final String label;
  final String value;
  final bool monoValue;

  @override
  Widget build(BuildContext context) {
    final valueStyle = monoValue
        ? AppTypography.labelMono.copyWith(fontWeight: FontWeight.w700)
        : AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700);
    return LicenseInsetCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: licenseLabelStyle),
          const SizedBox(height: AppSpacing.xs),
          FittedBox(
            alignment: Alignment.centerLeft,
            fit: BoxFit.scaleDown,
            child: Text(value, style: valueStyle),
          ),
        ],
      ),
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({
    required this.canChangePlan,
    required this.inline,
    required this.onChangePlan,
    required this.onModifyTerms,
    required this.onRenew,
  });

  final bool canChangePlan;
  final bool inline;
  final VoidCallback onChangePlan;
  final VoidCallback onModifyTerms;
  final VoidCallback onRenew;

  @override
  Widget build(BuildContext context) {
    final changePlan = AppButton.outlined(
      text: 'Change Plan',
      iconData: Icons.north_east,
      isFullWidth: !inline,
      onPressed: canChangePlan ? onChangePlan : null,
    );
    final modifyTerms = AppButton.outlined(
      text: 'Modify Commercial Terms',
      iconData: Icons.payments_outlined,
      isFullWidth: !inline,
      onPressed: onModifyTerms,
    );
    final renew = AppButton.primary(
      text: 'Renew License',
      iconData: Icons.sync,
      isFullWidth: !inline,
      onPressed: onRenew,
    );
    final note = canChangePlan
        ? null
        : Text(
            'No higher active plan is available for this organization.',
            style: licenseBodyStyle,
            textAlign: inline ? TextAlign.end : TextAlign.start,
          );
    if (inline) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Wrap(
            alignment: WrapAlignment.end,
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [changePlan, modifyTerms, renew],
          ),
          if (note != null) ...[
            const SizedBox(height: AppSpacing.xs),
            SizedBox(width: 420, child: note),
          ],
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        changePlan,
        const SizedBox(height: AppSpacing.sm),
        modifyTerms,
        const SizedBox(height: AppSpacing.sm),
        renew,
        if (note != null) ...[const SizedBox(height: AppSpacing.sm), note],
      ],
    );
  }
}
