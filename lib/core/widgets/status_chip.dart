import 'package:flutter/material.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/app/theme/app_typography.dart';

enum StatusType { active, pending, urgent, neutral }

/// Operations status chip featuring a 6px status indicator and high-contrast styling.
class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.label,
    required this.type,
    this.width = 96.0,
  });

  factory StatusChip.fromStatus(String status, {double? width = 96.0}) {
    final lower = status.toLowerCase();
    final type = lower == 'active'
        ? StatusType.active
        : (lower == 'suspended' || lower == 'urgent'
              ? StatusType.urgent
              : (lower == 'pending' ? StatusType.pending : StatusType.neutral));
    return StatusChip(label: status, type: type, width: width);
  }

  final String label;
  final StatusType type;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final (textColor, containerColor, borderColor) = _colorsForType(type);

    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: containerColor,
        borderRadius: AppSpacing.roundedPill,
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: width != null ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment:
            width != null ? MainAxisAlignment.center : MainAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: textColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Text(
              label,
              style: AppTypography.labelMono.copyWith(
                color: textColor,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  (Color text, Color container, Color border) _colorsForType(StatusType type) {
    switch (type) {
      case StatusType.active:
        return (
          AppColors.statusActiveText,
          AppColors.statusActiveContainer,
          AppColors.statusActiveBorder,
        );
      case StatusType.pending:
        return (
          AppColors.statusPendingText,
          AppColors.statusPendingContainer,
          AppColors.statusPendingBorder,
        );
      case StatusType.urgent:
        return (
          AppColors.statusUrgentText,
          AppColors.statusUrgentContainer,
          AppColors.statusUrgentBorder,
        );
      case StatusType.neutral:
        return (
          AppColors.statusNeutralText,
          AppColors.statusNeutralContainer,
          AppColors.statusNeutralBorder,
        );
    }
  }
}
