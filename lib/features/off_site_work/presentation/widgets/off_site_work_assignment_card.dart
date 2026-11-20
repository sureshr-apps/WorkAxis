import 'package:flutter/material.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/app/theme/app_typography.dart';
import 'package:workaxis/core/formatting/date_time_formatters.dart';
import 'package:workaxis/features/off_site_work/domain/models/off_site_work_assignment.dart';
import 'package:workaxis/shared/widgets/dashboard_surface_card.dart';

class OffSiteWorkAssignmentCard extends StatelessWidget {
  const OffSiteWorkAssignmentCard({
    super.key,
    required this.assignment,
    required this.isEmployee,
    required this.onTap,
  });

  final OffSiteWorkAssignment assignment;
  final bool isEmployee;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (assignment.status) {
      OffSiteWorkStatus.completed ||
      OffSiteWorkStatus.returned => Theme.of(context).colorScheme.tertiary,
      OffSiteWorkStatus.unableToComplete => Theme.of(context).colorScheme.error,
      _ => Theme.of(context).colorScheme.primary,
    };
    return DashboardSurfaceCard(
      padding: EdgeInsets.zero,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: AppSpacing.roundedMd,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        assignment.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.titleMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: AppSpacing.roundedPill,
                      ),
                      child: Text(
                        assignment.status.label,
                        style: AppTypography.labelSmall.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                _InfoLine(
                  icon: Icons.place_outlined,
                  text: assignment.destination,
                ),
                const SizedBox(height: AppSpacing.xs),
                _InfoLine(
                  icon: Icons.store_outlined,
                  text: assignment.branchName,
                ),
                if (!isEmployee) ...[
                  const SizedBox(height: AppSpacing.xs),
                  _InfoLine(
                    icon: Icons.person_outline,
                    text: assignment.employeeName,
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Icon(
                      assignment.latestLocation == null
                          ? Icons.schedule_outlined
                          : Icons.my_location_outlined,
                      size: 16,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        assignment.latestLocation == null
                            ? assignment.dueAt == null
                                  ? 'Assigned ${AppFormatters.formatDateTime(assignment.createdAt)}'
                                  : 'Due ${AppFormatters.formatDateTime(assignment.dueAt)}'
                            : 'Last location ${assignment.latestLocation!.latitude.toStringAsFixed(4)}, ${assignment.latestLocation!.longitude.toStringAsFixed(4)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodySmall,
                      ),
                    ),
                    const Icon(Icons.chevron_right),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodySmall,
          ),
        ),
      ],
    );
  }
}
