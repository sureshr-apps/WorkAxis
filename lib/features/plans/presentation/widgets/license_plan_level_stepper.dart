import 'package:flutter/material.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/app/theme/app_typography.dart';

/// Minus / value / plus control for a plan level. Levels are whole numbers from
/// 1 upward; the value is never typed so it cannot be invalid.
class LicensePlanLevelStepper extends StatelessWidget {
  const LicensePlanLevelStepper({
    super.key,
    required this.value,
    required this.onChanged,
    this.enabled = true,
    this.errorText,
  });

  final int value;
  final ValueChanged<int> onChanged;
  final bool enabled;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final hasError = errorText != null;
    final borderColor = hasError
        ? AppColors.statusUrgent
        : AppColors.outlineSubtle;
    final canDecrease = enabled && value > 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _StepButton(
              icon: Icons.remove,
              tooltip: 'Decrease plan level',
              onPressed: canDecrease ? () => onChanged(value - 1) : null,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Container(
                height: AppSpacing.minTouchTarget,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: AppSpacing.roundedSm,
                  border: Border.all(color: borderColor),
                ),
                child: Semantics(
                  label: 'Plan level',
                  value: '$value',
                  child: Text(
                    '$value',
                    style: AppTypography.labelMono.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            _StepButton(
              icon: Icons.add,
              tooltip: 'Increase plan level',
              onPressed: enabled ? () => onChanged(value + 1) : null,
            ),
          ],
        ),
        if (hasError) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            errorText!,
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.statusUrgentText,
            ),
          ),
        ],
      ],
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton.outlined(
      tooltip: tooltip,
      icon: Icon(icon, size: 18),
      onPressed: onPressed,
      style: IconButton.styleFrom(
        minimumSize: const Size.square(AppSpacing.minTouchTarget),
        foregroundColor: AppColors.secondary,
        side: const BorderSide(color: AppColors.outlineSubtle),
      ),
    );
  }
}
