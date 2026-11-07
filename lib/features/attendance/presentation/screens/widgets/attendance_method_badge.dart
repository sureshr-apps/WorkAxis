import 'package:flutter/material.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/app/theme/app_typography.dart';
import 'package:workaxis/features/attendance/domain/models/attendance_entry.dart';
import 'package:workaxis/features/attendance/presentation/attendance_presentation.dart';

/// Kiosk / Mobile source badge. Always carries text and an icon.
class AttendanceMethodBadge extends StatelessWidget {
  const AttendanceMethodBadge({super.key, required this.entry});

  final AttendanceEntry entry;

  @override
  Widget build(BuildContext context) {
    final isKiosk = entry.kioskEntry;
    final foreground = isKiosk ? AppColors.kpiLabel : AppColors.primary;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: isKiosk
            ? AppColors.kpiNeutralBackground
            : AppColors.primaryContainer,
        borderRadius: AppSpacing.roundedXs,
        border: Border.all(
          color: isKiosk ? AppColors.kpiBorder : AppColors.outlineSubtle,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isKiosk
                ? Icons.tablet_android_outlined
                : Icons.phone_android_outlined,
            size: 13,
            color: foreground,
          ),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Text(
              entry.sourceLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.labelSmall.copyWith(
                color: foreground,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
