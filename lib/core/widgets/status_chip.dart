import 'package:flutter/material.dart';
import 'package:workaxis/core/constants/app_radius.dart';
import 'package:workaxis/core/constants/app_spacing.dart';
import 'package:workaxis/core/theme/app_colors.dart';

enum StatusChipType {
  active,
  relieved,
  absent,
  pending,
  disabled,
}

class StatusChip extends StatelessWidget {
  const StatusChip({
    required this.type,
    this.label,
    super.key,
  });

  final StatusChipType type;
  final String? label;

  @override
  Widget build(BuildContext context) {
    Color color;
    Color backgroundColor;
    IconData iconData;
    String defaultText;

    switch (type) {
      case StatusChipType.active:
        color = AppColors.statusActive;
        backgroundColor = AppColors.statusActive.withValues(alpha: 0.15);
        iconData = Icons.check_circle_rounded;
        defaultText = 'Active';
      case StatusChipType.relieved:
        color = AppColors.onSurfaceVariant;
        backgroundColor = AppColors.statusRelieved.withValues(alpha: 0.25);
        iconData = Icons.schedule_rounded;
        defaultText = 'Relieved';
      case StatusChipType.absent:
        color = AppColors.statusAbsent;
        backgroundColor = AppColors.statusAbsent.withValues(alpha: 0.15);
        iconData = Icons.cancel_rounded;
        defaultText = 'Absent';
      case StatusChipType.pending:
        color = AppColors.statusPending;
        backgroundColor = AppColors.secondaryContainer.withValues(alpha: 0.35);
        iconData = Icons.hourglass_top_rounded;
        defaultText = 'Pending';
      case StatusChipType.disabled:
        color = AppColors.statusDisabled;
        backgroundColor = AppColors.statusDisabled.withValues(alpha: 0.20);
        iconData = Icons.block_rounded;
        defaultText = 'Disabled';
    }

    final displayText = label ?? defaultText;

    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm + 2),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: AppRadius.borderFull,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(iconData, size: 16, color: color),
          const SizedBox(width: AppSpacing.xs + 2),
          Text(
            displayText,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
          ),
        ],
      ),
    );
  }
}
