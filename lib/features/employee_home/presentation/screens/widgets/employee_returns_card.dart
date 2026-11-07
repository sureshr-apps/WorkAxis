import 'package:flutter/material.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_shadows.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/app/theme/app_typography.dart';
import 'package:workaxis/core/widgets/app_button.dart';
import 'package:workaxis/core/widgets/status_chip.dart';
import 'package:workaxis/features/employee_home/domain/models/employee_home_summary.dart';

/// Recent return ticket, approval counts and return actions. The recent ticket
/// box appears only when the summary actually carries a ticket.
class EmployeeReturnsCard extends StatelessWidget {
  const EmployeeReturnsCard({
    super.key,
    required this.summary,
    required this.onSubmitReturn,
    required this.onViewReturns,
  });

  final EmployeeHomeSummary summary;
  final VoidCallback onSubmitReturn;
  final VoidCallback onViewReturns;

  static bool _has(String? value) =>
      value != null &&
      value.isNotEmpty &&
      value != EmployeeHomeSummary.unavailable;

  @override
  Widget build(BuildContext context) {
    final hasRecent = _has(summary.recentReturnTitle);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: AppSpacing.roundedMd,
        border: Border.all(color: AppColors.kpiBorder),
        boxShadow: AppShadows.card,
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.assignment_return_outlined,
                    size: 20,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'My Returns',
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  StatusChip(
                    label: '${summary.pendingReturnsCount ?? '—'} Pending',
                    type: StatusType.pending,
                    width: null,
                  ),
                  StatusChip(
                    label: '${summary.approvedReturnsCount ?? '—'} Approved',
                    type: StatusType.active,
                    width: null,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (hasRecent) ...[
            _RecentReturn(summary: summary),
            const SizedBox(height: AppSpacing.md),
          ],
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              AppButton.secondary(
                text: 'Submit return',
                iconData: Icons.add,
                isFullWidth: false,
                onPressed: onSubmitReturn,
              ),
              AppButton.outlined(
                text: 'View returns',
                iconData: Icons.arrow_forward,
                isFullWidth: false,
                onPressed: onViewReturns,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RecentReturn extends StatelessWidget {
  const _RecentReturn({required this.summary});
  final EmployeeHomeSummary summary;

  static StatusType _typeFor(String status) {
    final lower = status.toLowerCase();
    if (lower.contains('approv')) return StatusType.active;
    if (lower.contains('reject')) return StatusType.urgent;
    return StatusType.pending;
  }

  @override
  Widget build(BuildContext context) {
    final status = summary.recentReturnStatus;
    final subtitle = summary.recentReturnSubtitle;
    final office = summary.recentReturnOffice;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: AppSpacing.roundedMd,
        border: Border.all(color: AppColors.kpiBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.kpiBorder,
                  borderRadius: AppSpacing.roundedSm,
                ),
                child: const Icon(
                  Icons.inventory_2_outlined,
                  size: 19,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      summary.recentReturnTitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (EmployeeReturnsCard._has(subtitle)) ...[
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        subtitle!,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (EmployeeReturnsCard._has(status) ||
              EmployeeReturnsCard._has(office)) ...[
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (EmployeeReturnsCard._has(status))
                  StatusChip(
                    label: status!,
                    type: _typeFor(status),
                    width: null,
                  ),
                if (EmployeeReturnsCard._has(office))
                  Text(
                    office!,
                    style: AppTypography.labelMono.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
