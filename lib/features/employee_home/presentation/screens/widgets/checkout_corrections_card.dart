import 'package:flutter/material.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_shadows.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/app/theme/app_typography.dart';
import 'package:workaxis/core/widgets/app_button.dart';
import 'package:workaxis/core/widgets/status_chip.dart';
import 'package:workaxis/features/attendance/domain/models/attendance_entry.dart';
import 'package:workaxis/features/employee_home/presentation/controllers/checkout_corrections_controller.dart';
import 'package:workaxis/features/employee_home/presentation/screens/widgets/checkout_correction_tile.dart';

/// "Check-outs to correct": sessions with a missing or late check-out. The
/// card is hidden while there is nothing to correct, including the first
/// load, so most employees never see it flash in.
class CheckoutCorrectionsCard extends StatelessWidget {
  const CheckoutCorrectionsCard({
    super.key,
    required this.controller,
    required this.onRequestCorrection,
  });

  final CheckoutCorrectionsController controller;
  final void Function(AttendanceEntry entry) onRequestCorrection;

  /// Whether the card has anything to show.
  static bool isVisible(CheckoutCorrectionsController controller) =>
      controller.hasError || controller.entries.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    if (!isVisible(controller)) return const SizedBox.shrink();
    final entries = controller.entries;
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
          _header(entries.length),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Your manager reviews each request before your hours change.',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          if (controller.isLoading) ...[
            const SizedBox(height: AppSpacing.sm),
            const LinearProgressIndicator(minHeight: 2),
          ],
          const SizedBox(height: AppSpacing.md),
          if (controller.hasError)
            _ErrorRow(
              message:
                  controller.errorMessage ??
                  'Check-outs to correct could not be loaded.',
              onRetry: controller.retry,
            )
          else
            for (final (index, entry) in entries.indexed) ...[
              if (index > 0) const SizedBox(height: AppSpacing.sm),
              CheckoutCorrectionTile(
                entry: entry,
                onRequestCorrection: controller.isSubmitting
                    ? null
                    : () => onRequestCorrection(entry),
              ),
            ],
        ],
      ),
    );
  }

  Widget _header(int count) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.xs,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.more_time_outlined,
              size: 20,
              color: AppColors.primary,
            ),
            const SizedBox(width: AppSpacing.sm),
            Flexible(
              child: Text(
                'Check-outs to correct',
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        if (count > 0)
          StatusChip(
            label: count == 1 ? '1 session' : '$count sessions',
            type: StatusType.urgent,
            width: null,
          ),
      ],
    );
  }
}

class _ErrorRow extends StatelessWidget {
  const _ErrorRow({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 18,
              color: AppColors.statusUrgentText,
            ),
            const SizedBox(width: AppSpacing.xs),
            Flexible(
              child: Text(
                message,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.statusUrgentText,
                ),
              ),
            ),
          ],
        ),
        AppButton.outlined(
          text: 'Retry',
          iconData: Icons.refresh,
          isFullWidth: false,
          onPressed: onRetry,
        ),
      ],
    );
  }
}
