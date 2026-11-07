import 'package:flutter/material.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_shadows.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/app/theme/app_typography.dart';
import 'package:workaxis/features/employee_home/domain/models/employee_home_summary.dart';

/// Today's station assignment and shift supervisor, shown only for the parts
/// the backend provides.
class TodayAssignmentCard extends StatelessWidget {
  const TodayAssignmentCard({super.key, required this.summary});

  final EmployeeHomeSummary summary;

  static bool _has(String value) =>
      value.isNotEmpty && value != EmployeeHomeSummary.unavailable;

  /// Whether the summary carries anything for this card.
  static bool hasContent(EmployeeHomeSummary summary) =>
      _has(summary.assignedStationCode) ||
      _has(summary.assignedStationName) ||
      _has(summary.supervisorName);

  @override
  Widget build(BuildContext context) {
    final hasStation =
        _has(summary.assignedStationCode) || _has(summary.assignedStationName);
    final hasSupervisor = _has(summary.supervisorName);
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
          Row(
            children: [
              const Icon(
                Icons.work_history_outlined,
                size: 20,
                color: AppColors.primary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  "Today's Assignment",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: AppSpacing.roundedMd,
              border: Border.all(color: AppColors.kpiBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (hasStation) _station(),
                if (hasStation && hasSupervisor)
                  const SizedBox(height: AppSpacing.md),
                if (hasSupervisor) _supervisor(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _station() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ASSIGNED STATION',
                style: AppTypography.labelMono.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                summary.assignedStationCode,
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                summary.assignedStationName,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.kpiBorder,
            borderRadius: AppSpacing.roundedSm,
          ),
          child: const Icon(
            Icons.precision_manufacturing_outlined,
            size: 22,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }

  Widget _supervisor() {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: const BoxDecoration(
            color: AppColors.secondaryContainer,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            summary.supervisorInitials,
            style: AppTypography.labelMono.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Shift Supervisor',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              Text(
                summary.supervisorName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (_has(summary.supervisorRole))
                Text(
                  summary.supervisorRole,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
