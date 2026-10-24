import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/core/responsive/responsive_layout.dart';
import 'package:workaxis/core/widgets/app_button.dart';
import 'package:workaxis/core/widgets/status_chip.dart';
import 'package:workaxis/features/platform_organizations/domain/models/organization_license_details.dart';

class OrganizationLicenseEmptyState extends StatelessWidget {
  const OrganizationLicenseEmptyState({
    super.key,
    required this.onAssignLicense,
  });

  final VoidCallback onAssignLicense;

  @override
  Widget build(BuildContext context) => _Panel(
    child: Padding(
      padding: EdgeInsets.all(
        context.isCompact ? AppSpacing.lg : AppSpacing.xxl,
      ),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          border: Border.all(color: AppColors.outlineVariant),
          borderRadius: AppSpacing.roundedSm,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 272),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLow,
                        border: Border.all(color: AppColors.outlineVariant),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.vpn_key_outlined,
                        size: 24,
                        color: AppColors.tertiary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'No license assigned',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'This organization does not currently have an assigned license agreement. Platform usage limits (Maximum Stores and Maximum Users) are not established until a license plan is provisioned.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        height: 1.55,
                        color: AppColors.secondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AppButton.responsive(
                      text: 'Assign License',
                      variant: AppButtonVariant.outlined,
                      onPressed: onAssignLicense,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class OrganizationLicenseTab extends StatelessWidget {
  const OrganizationLicenseTab({
    super.key,
    required this.license,
    required this.onAction,
  });

  final OrganizationLicenseDetails license;
  final ValueChanged<String> onAction;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy-MM-dd');
    final expiresIn = license.daysRemaining(DateTime.now());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _LicenseSummaryCard(
          license: license,
          expiresIn: expiresIn,
          dateFormat: dateFormat,
          onAction: onAction,
        ),
        const SizedBox(height: AppSpacing.md),
        LayoutBuilder(
          builder: (context, constraints) {
            final splitPanels = constraints.maxWidth >= 1040;
            final paneContentWidth = splitPanels
                ? (constraints.maxWidth - 1) / 2 - AppSpacing.lg * 2
                : constraints.maxWidth - AppSpacing.lg * 2;
            return _LicenseDetailsPanel(
              license: license,
              dateFormat: dateFormat,
              split: splitPanels,
              cardsInline: paneContentWidth >= 540,
            );
          },
        ),
        const SizedBox(height: AppSpacing.md),
        _LicenseHistoryPanel(license: license, dateFormat: dateFormat),
      ],
    );
  }
}

class _LicenseSummaryCard extends StatelessWidget {
  const _LicenseSummaryCard({
    required this.license,
    required this.expiresIn,
    required this.dateFormat,
    required this.onAction,
  });

  final OrganizationLicenseDetails license;
  final int expiresIn;
  final DateFormat dateFormat;
  final ValueChanged<String> onAction;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final summary = Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.tertiaryContainer.withValues(alpha: 0.12),
                    border: Border.all(
                      color: AppColors.tertiaryContainer.withValues(
                        alpha: 0.25,
                      ),
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
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.onSurface,
                            ),
                          ),
                          StatusChip(
                            label: license.status.toUpperCase(),
                            type: license.status.toLowerCase() == 'active'
                                ? StatusType.active
                                : StatusType.urgent,
                            width: 96,
                          ),
                          _SmallBadge(label: 'LEVEL ${license.level}'),
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
                              'Expires in $expiresIn days (${dateFormat.format(license.agreementExpiry)})',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            );

            final actions = Wrap(
              alignment: WrapAlignment.end,
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                _OutlineAction(
                  label: 'Change Plan',
                  icon: Icons.north_east,
                  onPressed: () => onAction('Change Plan'),
                ),
                _OutlineAction(
                  label: 'Modify Commercial Terms',
                  icon: Icons.payments_outlined,
                  onPressed: () => onAction('Modify Commercial Terms'),
                ),
                FilledButton.icon(
                  onPressed: () => onAction('Renew License'),
                  icon: const Icon(Icons.sync, size: 16),
                  label: const Text('Renew License'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(136, 48),
                    foregroundColor: Colors.white,
                    backgroundColor: AppColors.tertiaryContainer,
                    shape: RoundedRectangleBorder(
                      borderRadius: AppSpacing.roundedSm,
                    ),
                  ),
                ),
              ],
            );

            if (constraints.maxWidth < 940) {
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

class _LicenseDetailsPanel extends StatelessWidget {
  const _LicenseDetailsPanel({
    required this.license,
    required this.dateFormat,
    required this.split,
    required this.cardsInline,
  });

  final OrganizationLicenseDetails license;
  final DateFormat dateFormat;
  final bool split;
  final bool cardsInline;

  @override
  Widget build(BuildContext context) {
    final entitlements = _EntitlementsPane(
      license: license,
      cardsInline: cardsInline,
    );
    final agreement = _CommercialAgreementPane(
      license: license,
      dateFormat: dateFormat,
      cardsInline: cardsInline,
    );

    return _Panel(
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
        Row(
          children: [
            Expanded(child: _SectionHeading(title: 'PLAN ENTITLEMENTS')),
            const _SmallBadge(
              label: 'Defined by Plan',
              icon: Icons.lock_outline,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Usage quotas defined by ${license.planName}',
          style: GoogleFonts.inter(fontSize: 12, color: AppColors.onSurface),
        ),
        const SizedBox(height: AppSpacing.md),
        _ResponsiveLicenseCards(
          cardsInline: cardsInline,
          first: _EntitlementCard(
            label: 'Maximum Stores',
            value: '${license.maximumStores}',
            detail: license.maximumStores == 1
                ? 'Single store outlet'
                : 'Store locations allowed',
            icon: Icons.storefront_outlined,
          ),
          second: _EntitlementCard(
            label: 'Maximum Users',
            value: '${license.maximumUsers}',
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
            'Entitlements cannot be overridden at organization level. Organizations requiring higher capacity must move to a higher-level active plan via Change Plan.',
            style: GoogleFonts.inter(
              fontSize: 11,
              height: 1.45,
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ),
      ],
    ),
  );
}

class _ResponsiveLicenseCards extends StatelessWidget {
  const _ResponsiveLicenseCards({
    required this.cardsInline,
    required this.first,
    required this.second,
  });

  final bool cardsInline;
  final Widget first;
  final Widget second;

  @override
  Widget build(BuildContext context) {
    if (cardsInline) {
      return Row(
        children: [
          Expanded(child: first),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: second),
        ],
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

class _CommercialAgreementPane extends StatelessWidget {
  const _CommercialAgreementPane({
    required this.license,
    required this.dateFormat,
    required this.cardsInline,
  });

  final OrganizationLicenseDetails license;
  final DateFormat dateFormat;
  final bool cardsInline;

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 2,
    );
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: _SectionHeading(title: 'COMMERCIAL AGREEMENT'),
              ),
              Flexible(
                child: _SmallBadge(label: license.agreementId, mono: true),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Independently negotiated pricing & term',
            style: GoogleFonts.inter(fontSize: 12, color: AppColors.onSurface),
          ),
          const SizedBox(height: AppSpacing.md),
          _ResponsiveLicenseCards(
            cardsInline: cardsInline,
            first: _CommercialPriceCard(
              label: 'Negotiated Price (One-time)',
              value: formatter.format(license.negotiatedPrice),
              detail: 'Initial purchase price • Negotiated independently, not fixed by plan catalog',
            ),
            second: _CommercialPriceCard(
              label: 'Annual Maintenance Price',
              value: formatter.format(license.annualMaintenancePrice),
              detail: 'Recurring yearly maintenance fee',
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _DateCard(
                  label: 'Agreement Start',
                  value: dateFormat.format(license.agreementStart),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _DateCard(
                  label: 'Agreement Expiry',
                  value: dateFormat.format(license.agreementExpiry),
                ),
              ),
            ],
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
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.onSurface,
                    ),
                  ),
                ),
                Text(
                  'Status: ${license.status}',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EntitlementCard extends StatelessWidget {
  const _EntitlementCard({
    required this.label,
    required this.value,
    required this.detail,
    required this.icon,
  });

  final String label;
  final String value;
  final String detail;
  final IconData icon;

  @override
  Widget build(BuildContext context) => _InsetCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(label, style: _smallLabelStyle)),
            Icon(icon, size: 16, color: AppColors.tertiary),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          value,
          style: GoogleFonts.robotoMono(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(detail, style: _smallBodyStyle),
      ],
    ),
  );
}

class _CommercialPriceCard extends StatelessWidget {
  const _CommercialPriceCard({
    required this.label,
    required this.value,
    required this.detail,
  });

  final String label;
  final String value;
  final String detail;

  @override
  Widget build(BuildContext context) => _InsetCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(label, style: _smallLabelStyle)),
            const Icon(
              Icons.payments_outlined,
              size: 15,
              color: AppColors.secondary,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        FittedBox(
          alignment: Alignment.centerLeft,
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: GoogleFonts.robotoMono(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(detail, style: _smallBodyStyle),
      ],
    ),
  );
}

class _DateCard extends StatelessWidget {
  const _DateCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => _InsetCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: _smallLabelStyle),
        const SizedBox(height: AppSpacing.xs),
        Text(
          value,
          style: GoogleFonts.robotoMono(
            fontSize: 12,
            color: AppColors.onSurface,
          ),
        ),
      ],
    ),
  );
}

class _LicenseHistoryPanel extends StatelessWidget {
  const _LicenseHistoryPanel({required this.license, required this.dateFormat});

  final OrganizationLicenseDetails license;
  final DateFormat dateFormat;

  @override
  Widget build(BuildContext context) => _Panel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: _SectionHeading(title: 'LICENSE HISTORY'),
                  ),
                  _SmallBadge(label: '${license.history.length} Record'),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Audit log of license events with the referenced plan (shown as currently defined), validity periods, one-time price, and annual maintenance price.',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth >= 1000) {
              return _HistoryTable(license: license, dateFormat: dateFormat);
            }
            return Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                0,
                AppSpacing.md,
                AppSpacing.md,
              ),
              child: Column(
                children: [
                  for (final entry in license.history)
                    _HistoryCard(entry: entry, dateFormat: dateFormat),
                ],
              ),
            );
          },
        ),
      ],
    ),
  );
}

class _HistoryTable extends StatelessWidget {
  const _HistoryTable({required this.license, required this.dateFormat});

  final OrganizationLicenseDetails license;
  final DateFormat dateFormat;

  @override
  Widget build(BuildContext context) {
    final money = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 2,
    );
    const minTableWidth = 1110.0;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: minTableWidth,
        child: Column(
          children: [
            Container(
              color: AppColors.surfaceContainerLow,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: const Row(
                children: [
                  _HistoryHeading('EVENT', flex: 13),
                  _HistoryHeading('DATE & TIME', flex: 16),
                  _HistoryHeading('PLAN', flex: 10),
                  _HistoryHeading('LICENSE PERIOD', flex: 18),
                  _HistoryHeading('STORES', flex: 7),
                  _HistoryHeading('USERS', flex: 7),
                  _HistoryHeading('ONE-TIME PRICE', flex: 14),
                  _HistoryHeading('ANNUAL MAINTENANCE', flex: 15),
                ],
              ),
            ),
            for (final entry in license.history)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.md,
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 13,
                      child: _HistoryEventBadge(label: entry.event),
                    ),
                    Expanded(
                      flex: 16,
                      child: Text(
                        DateFormat('dd MMM yyyy, hh:mm a')
                            .format(entry.occurredAt),
                        style: GoogleFonts.robotoMono(
                          fontSize: 10,
                          color: AppColors.onSurface,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 10,
                      child: Text(
                        '${entry.planName}\nLevel ${entry.level}',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppColors.onSurface,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 18,
                      child: Text(
                        '${dateFormat.format(entry.periodStart)} to ${dateFormat.format(entry.periodEnd)}',
                        style: GoogleFonts.robotoMono(
                          fontSize: 10,
                          color: AppColors.onSurface,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 7,
                      child: Text(
                        '${entry.stores}',
                        textAlign: TextAlign.center,
                        style: _historyValueStyle,
                      ),
                    ),
                    Expanded(
                      flex: 7,
                      child: Text(
                        '${entry.users}',
                        textAlign: TextAlign.center,
                        style: _historyValueStyle,
                      ),
                    ),
                    Expanded(
                      flex: 14,
                      child: Text(
                        money.format(entry.negotiatedPrice),
                        textAlign: TextAlign.right,
                        style: _historyValueStyle,
                      ),
                    ),
                    Expanded(
                      flex: 15,
                      child: Text(
                        money.format(entry.annualMaintenancePrice),
                        textAlign: TextAlign.right,
                        style: _historyValueStyle,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.entry, required this.dateFormat});

  final LicenseHistoryEntry entry;
  final DateFormat dateFormat;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
    child: _InsetCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _HistoryEventBadge(label: entry.event)),
              Text(
                '${entry.planName} · Level ${entry.level}',
                style: _smallLabelStyle,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            DateFormat('dd MMM yyyy, hh:mm a').format(entry.occurredAt),
            style: _smallBodyStyle,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${dateFormat.format(entry.periodStart)} to ${dateFormat.format(entry.periodEnd)}',
            style: _smallBodyStyle,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${entry.stores} stores · ${entry.users} users',
            style: _smallBodyStyle,
          ),
        ],
      ),
    ),
  );
}

class _HistoryHeading extends StatelessWidget {
  const _HistoryHeading(this.label, {required this.flex});

  final String label;
  final int flex;

  @override
  Widget build(BuildContext context) => Expanded(
    flex: flex,
    child: Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: GoogleFonts.inter(
        fontSize: 9,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.3,
        color: AppColors.secondary,
      ),
    ),
  );
}

class _HistoryEventBadge extends StatelessWidget {
  const _HistoryEventBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer,
        border: Border.all(color: AppColors.outlineVariant),
        borderRadius: AppSpacing.roundedXs,
      ),
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: AppColors.primaryDark,
        ),
      ),
    ),
  );
}

class _OutlineAction extends StatelessWidget {
  const _OutlineAction({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    onPressed: onPressed,
    icon: Icon(icon, size: 16, color: AppColors.tertiary),
    label: Text(label),
    style: OutlinedButton.styleFrom(
      minimumSize: const Size(48, 48),
      foregroundColor: AppColors.onSurface,
      side: const BorderSide(color: AppColors.outlineVariant),
      shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedSm),
    ),
  );
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) => Text(
    title,
    style: GoogleFonts.inter(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.4,
      color: AppColors.secondary,
    ),
  );
}

class _SmallBadge extends StatelessWidget {
  const _SmallBadge({required this.label, this.icon, this.mono = false});

  final String label;
  final IconData? icon;
  final bool mono;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.sm,
      vertical: AppSpacing.xs,
    ),
    decoration: BoxDecoration(
      color: AppColors.surfaceContainerLow,
      border: Border.all(color: AppColors.outlineVariant),
      borderRadius: AppSpacing.roundedXs,
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 12, color: AppColors.secondary),
          const SizedBox(width: AppSpacing.xs),
        ],
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: mono
              ? GoogleFonts.robotoMono(fontSize: 9, color: AppColors.secondary)
              : GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.secondary,
                ),
        ),
      ],
    ),
  );
}

class _InsetCard extends StatelessWidget {
  const _InsetCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: AppColors.surfaceContainerLow,
      border: Border.all(color: AppColors.outlineVariant),
      borderRadius: AppSpacing.roundedSm,
    ),
    child: child,
  );
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: AppColors.surfaceContainerLowest,
      border: Border.all(color: AppColors.outlineSubtle),
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      boxShadow: const [
        BoxShadow(
          color: Color(0x06000000),
          offset: Offset(0, 2),
          blurRadius: 8,
        ),
        BoxShadow(
          color: Color(0x04000000),
          offset: Offset(0, 1),
          blurRadius: 2,
        ),
      ],
    ),
    child: child,
  );
}

TextStyle get _smallLabelStyle =>
    GoogleFonts.inter(fontSize: 11, color: AppColors.secondary);

TextStyle get _smallBodyStyle => GoogleFonts.inter(
  fontSize: 10,
  height: 1.4,
  color: AppColors.onSurfaceVariant,
);

TextStyle get _historyValueStyle => GoogleFonts.inter(
  fontSize: 11,
  fontWeight: FontWeight.w600,
  color: AppColors.onSurface,
);
