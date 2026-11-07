import 'package:flutter/material.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_typography.dart';

/// One labelled value in the hero telemetry strip (label, value, note).
class HeroMetric extends StatelessWidget {
  const HeroMetric({
    super.key,
    required this.label,
    required this.value,
    this.note,
    this.valueColor = AppColors.onSurface,
    this.noteColor = AppColors.onSurfaceVariant,
  });

  final String label;
  final String value;
  final String? note;
  final Color valueColor;
  final Color noteColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.titleMedium.copyWith(
            fontWeight: FontWeight.w700,
            color: valueColor,
          ),
        ),
        if (note != null) ...[
          const SizedBox(height: 3),
          Text(
            note!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.labelMono.copyWith(color: noteColor),
          ),
        ],
      ],
    );
  }
}
