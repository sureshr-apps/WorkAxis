import 'package:flutter/material.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/app/theme/app_typography.dart';
import 'package:workaxis/core/formatting/date_time_formatters.dart';
import 'package:workaxis/core/widgets/app_button.dart';
import 'package:workaxis/features/attendance/domain/models/attendance_entry.dart';
import 'package:workaxis/features/attendance/presentation/attendance_presentation.dart';
import 'package:workaxis/features/attendance/presentation/widgets/attendance_selfie_evidence.dart';
import 'package:workaxis/shared/widgets/dashboard_surface_card.dart';

/// One branch-specific punch session within an employee's daily summary.
class AttendanceSessionDetailsCard extends StatelessWidget {
  const AttendanceSessionDetailsCard({
    super.key,
    required this.index,
    required this.entry,
    required this.branchName,
    required this.canReview,
    required this.isSaving,
    required this.onReview,
  });

  final int index;
  final AttendanceEntry entry;
  final String branchName;
  final bool canReview;
  final bool isSaving;
  final Future<void> Function(
    AttendanceEntry entry,
    AttendanceReviewDecision decision,
  )?
  onReview;

  @override
  Widget build(BuildContext context) => DashboardSurfaceCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Session $index', style: AppTypography.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        _Detail(label: 'Branch', value: branchName),
        _Detail(
          label: 'Check-in',
          value: AppFormatters.formatTime(entry.checkInAt, placeholder: '—'),
        ),
        _Detail(
          label: 'Check-out',
          value: AppFormatters.formatTime(
            entry.checkOutAt,
            placeholder: 'In progress',
          ),
        ),
        _Detail(label: 'Status', value: entry.status.label),
        _Detail(
          label: 'Source',
          value: entry.kioskEntry ? 'Kiosk terminal' : 'Mobile app',
        ),
        if (entry.note != null && entry.note!.isNotEmpty)
          _Detail(label: 'Note', value: entry.note!),
        if (entry.needsReview && canReview && onReview != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              AppButton.secondary(
                text: 'Verify session',
                iconData: Icons.check,
                isFullWidth: false,
                onPressed: isSaving
                    ? null
                    : () => onReview!(entry, AttendanceReviewDecision.verify),
              ),
              AppButton.outlined(
                text: 'Dismiss exception',
                iconData: Icons.close,
                isFullWidth: false,
                onPressed: isSaving
                    ? null
                    : () => onReview!(entry, AttendanceReviewDecision.dismiss),
              ),
            ],
          ),
        ],
        const SizedBox(height: AppSpacing.sm),
        AttendanceSelfieEvidence(entry: entry),
      ],
    ),
  );
}

class _Detail extends StatelessWidget {
  const _Detail({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: AppTypography.bodyMedium.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(child: Text(value, style: AppTypography.bodyMedium)),
      ],
    ),
  );
}
