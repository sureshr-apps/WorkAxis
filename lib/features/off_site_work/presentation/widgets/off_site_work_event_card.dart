import 'package:flutter/material.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/app/theme/app_typography.dart';
import 'package:workaxis/core/formatting/date_time_formatters.dart';
import 'package:workaxis/core/widgets/attachment_image.dart';
import 'package:workaxis/features/off_site_work/domain/models/off_site_work_assignment.dart';
import 'package:workaxis/shared/widgets/dashboard_surface_card.dart';

class OffSiteWorkEventCard extends StatelessWidget {
  const OffSiteWorkEventCard({super.key, required this.event});

  final OffSiteWorkEvent event;

  @override
  Widget build(BuildContext context) {
    final location = event.location;
    return DashboardSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _iconFor(event.type),
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  event.type.label,
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${event.actorName} · ${AppFormatters.formatDateTime(event.occurredAt)}',
            style: AppTypography.bodySmall,
          ),
          if (location != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Location: ${location.latitude.toStringAsFixed(6)}, ${location.longitude.toStringAsFixed(6)} · accuracy ${location.accuracyMeters.toStringAsFixed(0)} m',
              style: AppTypography.bodySmall,
            ),
          ],
          if (event.note?.isNotEmpty == true) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(event.note!, style: AppTypography.bodyMedium),
          ],
          if (event.evidenceReferences.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text('Evidence', style: AppTypography.labelLarge),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final reference in event.evidenceReferences)
                  _EvidenceThumbnail(reference: reference),
              ],
            ),
          ],
        ],
      ),
    );
  }

  IconData _iconFor(OffSiteWorkEventType type) => switch (type) {
    OffSiteWorkEventType.assigned => Icons.assignment_outlined,
    OffSiteWorkEventType.started => Icons.play_circle_outline,
    OffSiteWorkEventType.arrived => Icons.place_outlined,
    OffSiteWorkEventType.completed => Icons.task_alt,
    OffSiteWorkEventType.unableToComplete => Icons.error_outline,
    OffSiteWorkEventType.returnedToBranch => Icons.keyboard_return,
  };
}

class _EvidenceThumbnail extends StatelessWidget {
  const _EvidenceThumbnail({required this.reference});

  final String reference;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showDialog<void>(
        context: context,
        builder: (context) => Dialog(
          child: InteractiveViewer(
            child: AspectRatio(
              aspectRatio: 1,
              child: AttachmentImage(reference: reference),
            ),
          ),
        ),
      ),
      child: ClipRRect(
        borderRadius: AppSpacing.roundedSm,
        child: SizedBox(
          width: 96,
          height: 96,
          child: AttachmentImage(reference: reference),
        ),
      ),
    );
  }
}
