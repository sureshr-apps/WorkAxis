import 'package:flutter/material.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/app/theme/app_typography.dart';
import 'package:workaxis/core/constants/app_breakpoints.dart';
import 'package:workaxis/features/platform_organizations/domain/models/license_history_event.dart';
import 'package:workaxis/features/platform_organizations/presentation/widgets/organization_details/license/license_display.dart';
import 'package:workaxis/features/platform_organizations/presentation/widgets/organization_details/license/license_formatters.dart';
import 'package:workaxis/features/platform_organizations/presentation/widgets/organization_details/license/license_shared_widgets.dart';

/// Audit log of license events, newest first: a table when wide, cards otherwise.
class LicenseHistoryPanel extends StatelessWidget {
  const LicenseHistoryPanel({super.key, required this.history});

  /// Already ordered newest first.
  final List<LicenseHistoryEvent> history;

  @override
  Widget build(BuildContext context) {
    final count = history.length;
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
                  'Audit log of license events with the referenced plan (shown '
                  'as currently defined), validity periods, one-time price, and '
                  'annual maintenance price.',
                  style: licenseBodyStyle,
                ),
              ],
            ),
          ),
          if (history.isEmpty)
            const _EmptyHistory()
          else
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth >= AppBreakpoints.wideTable) {
                  return _HistoryTable(history: history);
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
                      for (final event in history) _HistoryCard(event: event),
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

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(AppSpacing.lg),
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        border: Border.all(color: AppColors.outlineSubtle),
        borderRadius: AppSpacing.roundedSm,
      ),
      child: Column(
        children: [
          const Icon(Icons.history, size: 24, color: AppColors.outline),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'No License History Recorded',
            style: AppTypography.labelMedium.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'History events are recorded when a license is assigned, changed, '
            'modified, or renewed.',
            style: licenseBodyStyle,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}

class _HistoryTable extends StatelessWidget {
  const _HistoryTable({required this.history});

  final List<LicenseHistoryEvent> history;

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
          _HistoryRow(event: history[i]),
        ],
      ],
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.event});

  final LicenseHistoryEvent event;

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
          Expanded(flex: 13, child: _EventBadge(label: event.eventType.label)),
          Expanded(
            flex: 16,
            child: Text(
              LicenseFormatters.eventTime(event.eventAt),
              style: mono,
            ),
          ),
          Expanded(
            flex: 10,
            child: Text(
              '${event.planName}\nLevel ${event.planLevel}',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.onSurface,
              ),
            ),
          ),
          Expanded(
            flex: 18,
            child: Text(
              LicenseFormatters.period(event.startDate, event.expiryDate),
              style: mono,
            ),
          ),
          Expanded(
            flex: 7,
            child: Text(
              '${event.maxStores}',
              textAlign: TextAlign.center,
              style: value,
            ),
          ),
          Expanded(
            flex: 7,
            child: Text(
              '${event.maxUsers}',
              textAlign: TextAlign.center,
              style: value,
            ),
          ),
          Expanded(
            flex: 14,
            child: Text(
              LicenseFormatters.money(event.negotiatedPrice),
              textAlign: TextAlign.right,
              style: value,
            ),
          ),
          Expanded(
            flex: 15,
            child: Text(
              LicenseFormatters.money(event.maintenancePrice),
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
  const _HistoryCard({required this.event});

  final LicenseHistoryEvent event;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
    child: LicenseInsetCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _EventBadge(label: event.eventType.label)),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: Text(
                  '${event.planName} · Level ${event.planLevel}',
                  style: licenseLabelStyle,
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            LicenseFormatters.eventTime(event.eventAt),
            style: licenseBodyStyle,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            LicenseFormatters.period(event.startDate, event.expiryDate),
            style: licenseBodyStyle,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${event.maxStores} stores · ${event.maxUsers} users',
            style: licenseBodyStyle,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'One-time ${LicenseFormatters.money(event.negotiatedPrice)} · '
            'Annual maintenance ${LicenseFormatters.money(event.maintenancePrice)}',
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
