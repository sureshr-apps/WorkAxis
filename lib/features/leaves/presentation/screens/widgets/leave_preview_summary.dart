import 'package:flutter/material.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/app/theme/app_typography.dart';
import 'package:workaxis/features/leaves/domain/models/leave_preview.dart';
import 'package:workaxis/features/leaves/presentation/controllers/leave_preview_controller.dart';

/// User-facing copy for a [LeavePreview]: [lead] in the normal text colour
/// followed by an optional [unpaid] part shown in the urgent colour.
class LeavePreviewMessage {
  const LeavePreviewMessage(this.lead, [this.unpaid]);

  /// e.g. "Annual leave: 2 days available · 3 working days requested —
  /// 2 paid, " + unpaid "1 unpaid (deducted from salary)".
  factory LeavePreviewMessage.describe({
    required String typeName,
    required bool paid,
    required LeavePreview preview,
  }) {
    final requested = _count(preview.workdays, 'working day');
    if (!paid) {
      return preview.workdays == 0
          ? LeavePreviewMessage('$typeName is not paid.')
          : LeavePreviewMessage(
              '$typeName is not paid. ',
              '$requested requested (deducted from salary).',
            );
    }
    final available = '${_count(preview.availableDays, 'day')} available';
    if (preview.workdays == 0) {
      return LeavePreviewMessage(
        '$typeName: $available · no working days in these dates.',
      );
    }
    final lead = '$typeName: $available · $requested requested — ';
    if (!preview.hasUnpaidDays) {
      return LeavePreviewMessage('$lead${preview.paidDays} paid.');
    }
    return LeavePreviewMessage(
      '$lead${preview.paidDays} paid, ',
      '${preview.unpaidDays} unpaid (deducted from salary)',
    );
  }

  final String lead;
  final String? unpaid;

  String get text => '$lead${unpaid ?? ''}';

  static String _count(int value, String unit) =>
      '$value ${value == 1 ? unit : '${unit}s'}';
}

/// One-line paid/unpaid summary driven by a [LeavePreviewController].
/// Shows a quiet loading or unavailable state; it never blocks the dialog.
class LeavePreviewSummary extends StatelessWidget {
  const LeavePreviewSummary({
    super.key,
    required this.controller,
    required this.typeName,
    required this.paid,
  });

  final LeavePreviewController controller;
  final String typeName;
  final bool paid;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      final preview = controller.preview;
      if (controller.isLoading) {
        return const _SummaryRow(
          leading: SizedBox.square(
            dimension: 14,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          child: Text('Checking paid days…'),
        );
      }
      final error = controller.errorMessage;
      if (error != null) {
        return _SummaryRow(
          leading: const Icon(Icons.info_outline, size: 16),
          child: Text(error),
        );
      }
      if (preview == null) return const SizedBox.shrink();
      final message = LeavePreviewMessage.describe(
        typeName: typeName,
        paid: paid,
        preview: preview,
      );
      final unpaid = message.unpaid;
      return _SummaryRow(
        leading: Icon(
          unpaid == null ? Icons.event_available_outlined : Icons.info_outline,
          size: 16,
          color: unpaid == null
              ? AppColors.onSurfaceVariant
              : AppColors.statusUrgentText,
        ),
        child: Text.rich(
          TextSpan(
            text: message.lead,
            children: [
              if (unpaid != null)
                TextSpan(
                  text: unpaid,
                  style: const TextStyle(
                    color: AppColors.statusUrgentText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ),
      );
    },
  );
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.leading, required this.child});

  final Widget leading;
  final Widget child;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.only(top: 2),
        child: IconTheme.merge(
          data: const IconThemeData(color: AppColors.onSurfaceVariant),
          child: leading,
        ),
      ),
      const SizedBox(width: AppSpacing.sm),
      Expanded(
        child: DefaultTextStyle.merge(
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
          child: child,
        ),
      ),
    ],
  );
}
