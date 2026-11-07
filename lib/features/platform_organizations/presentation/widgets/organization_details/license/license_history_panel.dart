import 'package:flutter/material.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/app/theme/app_typography.dart';
import 'package:workaxis/core/constants/app_breakpoints.dart';
import 'package:workaxis/features/platform_organizations/domain/models/organization_license_details.dart';
import 'package:workaxis/features/platform_organizations/presentation/widgets/organization_details/license/license_formatters.dart';
import 'package:workaxis/features/platform_organizations/presentation/widgets/organization_details/license/license_shared_widgets.dart';

/// Audit log of license events: a table when wide, cards otherwise.
class LicenseHistoryPanel extends StatelessWidget {
  const LicenseHistoryPanel({super.key, required this.license});

  final OrganizationLicenseDetails license;

  @override
  Widget build(BuildContext context) {
    final count = license.history.length;
    return LicensePanel(
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
                      child: LicenseSectionHeading(title: 'LICENSE HISTORY'),
                    ),
                    LicenseSmallBadge(
                      label: '$count ${count == 1 ? 'Record' : 'Records'}',
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Audit log of license events with the referenced plan '
                  '(shown as currently defined), validity periods, one-time '
                  'price, and annual maintenance price.',
                  style: licenseBodyStyle,
                ),
              ],
            ),
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth >= AppBreakpoints.wideTable) {
                return _HistoryTable(history: license.history);
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
                      _HistoryCard(entry: entry),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _HistoryTable extends StatelessWidget {
  const _HistoryTable({required this.history});

  final List<LicenseHistoryEntry> history;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          decoration: const BoxDecoration(
            color: AppColors.surfaceContainerLow,
            border: Border(bottom: BorderSide(color: AppColors.outlineSubtle)),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: const Row(
            children: [
              _Heading('EVENT', flex: 13),
              _Heading('DATE & TIME', flex: 16),
              _Heading('PLAN', flex: 10),
              _Heading('LICENSE PERIOD', flex: 18),
              _Heading('STORES', flex: 7, textAlign: TextAlign.center),
              _Heading('USERS', flex: 7, textAlign: TextAlign.center),
              _Heading('ONE-TIME PRICE', flex: 14, textAlign: TextAlign.right),
              _Heading(
                'ANNUAL MAINTENANCE',
                flex: 15,
                textAlign: TextAlign.right,
              ),
            ],
          ),
        ),
        for (var i = 0; i < history.length; i++) ...[
          if (i > 0) const Divider(height: 1, color: AppColors.outlineSubtle),
          _HistoryRow(entry: history[i]),
        ],
      ],
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.entry});

  final LicenseHistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final mono = AppTypography.labelMono.copyWith(fontSize: 11);
    final value = AppTypography.labelSmall.copyWith(
      fontWeight: FontWeight.w600,
      color: AppColors.onSurface,
    );
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Expanded(flex: 13, child: _EventBadge(label: entry.event)),
          Expanded(
            flex: 16,
            child: Text(
              LicenseFormatters.dateTime(entry.occurredAt),
              style: mono,
            ),
          ),
          Expanded(
            flex: 10,
            child: Text(
              '${entry.planName}\nLevel ${entry.level}',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.onSurface,
              ),
            ),
          ),
          Expanded(
            flex: 18,
            child: Text(
              '${LicenseFormatters.date(entry.periodStart)} to '
              '${LicenseFormatters.date(entry.periodEnd)}',
              style: mono,
            ),
          ),
          Expanded(
            flex: 7,
            child: Text(
              '${entry.stores}',
              textAlign: TextAlign.center,
              style: value,
            ),
          ),
          Expanded(
            flex: 7,
            child: Text(
              '${entry.users}',
              textAlign: TextAlign.center,
              style: value,
            ),
          ),
          Expanded(
            flex: 14,
            child: Text(
              LicenseFormatters.money(entry.negotiatedPrice),
              textAlign: TextAlign.right,
              style: value,
            ),
          ),
          Expanded(
            flex: 15,
            child: Text(
              LicenseFormatters.money(entry.annualMaintenancePrice),
              textAlign: TextAlign.right,
              style: value,
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.entry});

  final LicenseHistoryEntry entry;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
    child: LicenseInsetCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _EventBadge(label: entry.event)),
              Text(
                '${entry.planName} · Level ${entry.level}',
                style: licenseLabelStyle,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            LicenseFormatters.dateTime(entry.occurredAt),
            style: licenseBodyStyle,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${LicenseFormatters.date(entry.periodStart)} to '
            '${LicenseFormatters.date(entry.periodEnd)}',
            style: licenseBodyStyle,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${entry.stores} stores · ${entry.users} users',
            style: licenseBodyStyle,
          ),
        ],
      ),
    ),
  );
}

class _Heading extends StatelessWidget {
  const _Heading(this.label, {required this.flex, this.textAlign});

  final String label;
  final int flex;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) => Expanded(
    flex: flex,
    child: Text(
      label,
      textAlign: textAlign,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: AppTypography.labelSmall.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: 0.3,
        color: AppColors.secondary,
      ),
    ),
  );
}

class _EventBadge extends StatelessWidget {
  const _EventBadge({required this.label});

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
        style: AppTypography.labelSmall.copyWith(
          fontWeight: FontWeight.w700,
          color: AppColors.primaryDark,
        ),
      ),
    ),
  );
}
