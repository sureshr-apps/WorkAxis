import 'package:flutter/material.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/app/theme/app_typography.dart';
import 'package:workaxis/core/formatting/date_time_formatters.dart';
import 'package:workaxis/features/platform_organizations/domain/models/organization_license_details.dart';
import 'package:workaxis/features/platform_organizations/presentation/widgets/organization_details/license/license_formatters.dart';
import 'package:workaxis/features/platform_organizations/presentation/widgets/organization_details/license/license_shared_widgets.dart';

/// Plan entitlements and commercial agreement, side by side when wide.
class LicenseDetailsPanel extends StatelessWidget {
  const LicenseDetailsPanel({super.key, required this.license});

  final OrganizationLicenseDetails license;

  /// Width at which the two panes sit side by side.
  static const double _splitWidth = 1040;

  /// Pane content width at which the two figure cards sit side by side.
  static const double _inlineCardsWidth = 540;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final split = constraints.maxWidth >= _splitWidth;
        final paneContentWidth = split
            ? (constraints.maxWidth - 1) / 2 - AppSpacing.lg * 2
            : constraints.maxWidth - AppSpacing.lg * 2;
        final cardsInline = paneContentWidth >= _inlineCardsWidth;
        final entitlements = _EntitlementsPane(
          license: license,
          cardsInline: cardsInline,
        );
        final agreement = _CommercialAgreementPane(
          license: license,
          cardsInline: cardsInline,
        );
        return LicensePanel(
          child: split
              ? IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: entitlements),
                      const VerticalDivider(
                        width: 1,
                        color: AppColors.outlineSubtle,
                      ),
                      Expanded(child: agreement),
                    ],
                  ),
                )
              : Column(
                  children: [
                    entitlements,
                    const Divider(height: 1, color: AppColors.outlineSubtle),
                    agreement,
                  ],
                ),
        );
      },
    );
  }
}

class _EntitlementsPane extends StatelessWidget {
  const _EntitlementsPane({required this.license, required this.cardsInline});

  final OrganizationLicenseDetails license;
  final bool cardsInline;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(AppSpacing.lg),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Row(
          children: [
            Expanded(child: LicenseSectionHeading(title: 'PLAN ENTITLEMENTS')),
            LicenseSmallBadge(
              label: 'Defined by Plan',
              icon: Icons.lock_outline,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Usage quotas defined by ${license.planName}',
          style: AppTypography.bodySmall.copyWith(color: AppColors.onSurface),
        ),
        const SizedBox(height: AppSpacing.md),
        _FigureCards(
          inline: cardsInline,
          first: _FigureCard(
            label: 'Maximum Stores',
            value: AppFormatters.formatNumber(license.maximumStores),
            detail: license.maximumStores == 1
                ? 'Single store outlet'
                : 'Store locations allowed',
            icon: Icons.storefront_outlined,
          ),
          second: _FigureCard(
            label: 'Maximum Users',
            value: AppFormatters.formatNumber(license.maximumUsers),
            detail: 'Maximum user accounts allowed',
            icon: Icons.people_outline,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            border: Border.all(color: AppColors.outlineSubtle),
            borderRadius: AppSpacing.roundedXs,
          ),
          child: Text(
            'Entitlements cannot be overridden at organization level. '
            'Organizations requiring higher capacity must move to a '
            'higher-level active plan via Change Plan.',
            style: licenseBodyStyle,
          ),
        ),
      ],
    ),
  );
}

class _CommercialAgreementPane extends StatelessWidget {
  const _CommercialAgreementPane({
    required this.license,
    required this.cardsInline,
  });

  final OrganizationLicenseDetails license;
  final bool cardsInline;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: LicenseSectionHeading(title: 'COMMERCIAL AGREEMENT'),
              ),
              Flexible(
                child: LicenseSmallBadge(
                  label: license.agreementId,
                  mono: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Independently negotiated pricing & term',
            style: AppTypography.bodySmall.copyWith(color: AppColors.onSurface),
          ),
          const SizedBox(height: AppSpacing.md),
          _FigureCards(
            inline: cardsInline,
            first: _FigureCard(
              label: 'Negotiated Price (One-time)',
              value: LicenseFormatters.money(license.negotiatedPrice),
              detail:
                  'Initial purchase price • Negotiated independently, not '
                  'fixed by plan catalog',
              icon: Icons.payments_outlined,
              iconColor: AppColors.secondary,
              fitValue: true,
            ),
            second: _FigureCard(
              label: 'Annual Maintenance Price',
              value: LicenseFormatters.money(license.annualMaintenancePrice),
              detail: 'Recurring yearly maintenance fee',
              icon: Icons.payments_outlined,
              iconColor: AppColors.secondary,
              fitValue: true,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _DateCard(
                    label: 'Agreement Start',
                    value: LicenseFormatters.date(license.agreementStart),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _DateCard(
                    label: 'Agreement Expiry',
                    value: LicenseFormatters.date(license.agreementExpiry),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              border: Border.all(color: AppColors.outlineSubtle),
              borderRadius: AppSpacing.roundedXs,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Prices in: ${license.currencyCode} (₹)',
                    style: licenseBodyStyle,
                  ),
                ),
                Text('Status: ${license.status}', style: licenseBodyStyle),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FigureCards extends StatelessWidget {
  const _FigureCards({
    required this.inline,
    required this.first,
    required this.second,
  });

  final bool inline;
  final Widget first;
  final Widget second;

  @override
  Widget build(BuildContext context) {
    if (inline) {
      return IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: first),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: second),
          ],
        ),
      );
    }
    return Column(
      children: [
        first,
        const SizedBox(height: AppSpacing.sm),
        second,
      ],
    );
  }
}

class _FigureCard extends StatelessWidget {
  const _FigureCard({
    required this.label,
    required this.value,
    required this.detail,
    required this.icon,
    this.iconColor = AppColors.tertiary,
    this.fitValue = false,
  });

  final String label;
  final String value;
  final String detail;
  final IconData icon;
  final Color iconColor;

  /// Scales the value down instead of wrapping (long currency amounts).
  final bool fitValue;

  @override
  Widget build(BuildContext context) {
    final valueText = Text(
      value,
      style: AppTypography.labelMono.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        height: 1.2,
      ),
    );
    return LicenseInsetCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(label, style: licenseLabelStyle)),
              Icon(icon, size: 16, color: iconColor),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          fitValue
              ? FittedBox(
                  alignment: Alignment.centerLeft,
                  fit: BoxFit.scaleDown,
                  child: valueText,
                )
              : valueText,
          const SizedBox(height: AppSpacing.xs),
          Text(detail, style: licenseBodyStyle),
        ],
      ),
    );
  }
}

class _DateCard extends StatelessWidget {
  const _DateCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => LicenseInsetCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: licenseLabelStyle),
        const SizedBox(height: AppSpacing.xs),
        Text(value, style: AppTypography.labelMono),
      ],
    ),
  );
}
