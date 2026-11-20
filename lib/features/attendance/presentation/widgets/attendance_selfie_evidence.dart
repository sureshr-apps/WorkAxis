import 'package:flutter/material.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/app/theme/app_typography.dart';
import 'package:workaxis/core/formatting/date_time_formatters.dart';
import 'package:workaxis/core/widgets/attachment_image.dart';
import 'package:workaxis/features/attendance/domain/models/attendance_entry.dart';
import 'package:workaxis/shared/widgets/dashboard_surface_card.dart';

/// Shows the timestamp and optional selfie for each employee attendance punch.
class AttendanceSelfieEvidence extends StatelessWidget {
  const AttendanceSelfieEvidence({super.key, required this.entry});

  final AttendanceEntry entry;

  @override
  Widget build(BuildContext context) {
    final events = _events();
    return DashboardSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Punch verification', style: AppTypography.titleMedium),
          const SizedBox(height: AppSpacing.md),
          if (events.isEmpty)
            Text(
              'No attendance punches were recorded for this day.',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            )
          else
            for (var index = 0; index < events.length; index++) ...[
              if (index > 0)
                const Divider(
                  height: AppSpacing.lg,
                  color: AppColors.outlineSubtle,
                ),
              _AttendanceEventTile(event: events[index]),
            ],
        ],
      ),
    );
  }

  List<_AttendanceEvent> _events() {
    final events = <_AttendanceEvent>[];
    if (entry.checkInAt != null) {
      events.add(
        _AttendanceEvent('Check-in', entry.checkInAt!, entry.checkInSelfiePath),
      );
    }
    for (var index = 0; index < entry.breaks.length; index++) {
      final record = entry.breaks[index];
      events.add(
        _AttendanceEvent(
          'Break ${index + 1} started',
          record.startAt,
          record.startSelfiePath,
        ),
      );
      if (record.endAt != null) {
        events.add(
          _AttendanceEvent(
            'Break ${index + 1} ended',
            record.endAt!,
            record.endSelfiePath,
          ),
        );
      }
    }
    if (entry.checkOutAt != null) {
      events.add(
        _AttendanceEvent(
          'Check-out',
          entry.checkOutAt!,
          entry.checkOutSelfiePath,
        ),
      );
    }
    return events;
  }
}

class _AttendanceEvent {
  const _AttendanceEvent(this.label, this.at, this.selfiePath);

  final String label;
  final DateTime at;
  final String? selfiePath;
}

class _AttendanceEventTile extends StatelessWidget {
  const _AttendanceEventTile({required this.event});

  final _AttendanceEvent event;

  @override
  Widget build(BuildContext context) {
    final selfiePath = event.selfiePath;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.verified_user_outlined, color: AppColors.primary),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(event.label, style: AppTypography.bodyMedium),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                AppFormatters.formatDateTime(event.at),
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              if (selfiePath == null || selfiePath.isEmpty)
                Text(
                  'No selfie recorded',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                )
              else
                _SelfieThumbnail(reference: selfiePath),
            ],
          ),
        ),
      ],
    );
  }
}

class _SelfieThumbnail extends StatelessWidget {
  const _SelfieThumbnail({required this.reference});

  final String reference;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'View attendance selfie',
      child: InkWell(
        borderRadius: AppSpacing.roundedSm,
        onTap: () => showDialog<void>(
          context: context,
          builder: (context) => Dialog(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: SizedBox(
                width: 560,
                height: 640,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: InteractiveViewer(
                        child: AttachmentImage(
                          reference: reference,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: IconButton(
                        tooltip: 'Close selfie',
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        child: SizedBox(
          width: 88,
          height: 88,
          child: ClipRRect(
            borderRadius: AppSpacing.roundedSm,
            child: AttachmentImage(reference: reference),
          ),
        ),
      ),
    );
  }
}
