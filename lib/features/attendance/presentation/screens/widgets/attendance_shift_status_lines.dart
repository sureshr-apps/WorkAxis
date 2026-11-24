import 'package:flutter/material.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/app/theme/app_typography.dart';
import 'package:workaxis/core/widgets/status_chip.dart';
import 'package:workaxis/features/attendance/presentation/attendance_session_presentation.dart';

/// Shift window, check-out state and overtime for a session or a day. Every
/// state carries a text label, so colour is never the only signal.
class AttendanceShiftStatusLines extends StatelessWidget {
  const AttendanceShiftStatusLines({
    super.key,
    this.shiftWindow,
    this.checkoutState,
    this.overtimeLabel,
    this.overtimeType = StatusType.neutral,
    this.correctionLabel,
    this.showDetail = false,
  });

  final String? shiftWindow;
  final CheckoutStateDisplay? checkoutState;
  final String? overtimeLabel;
  final StatusType overtimeType;
  final String? correctionLabel;

  /// Whether to explain the check-out state below the chips.
  final bool showDetail;

  bool get isEmpty =>
      shiftWindow == null &&
      checkoutState == null &&
      overtimeLabel == null &&
      correctionLabel == null;

  @override
  Widget build(BuildContext context) {
    if (isEmpty) return const SizedBox.shrink();
    final state = checkoutState;
    final detail = showDetail ? state?.detail : null;
    final hasChips =
        state != null || overtimeLabel != null || correctionLabel != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (shiftWindow != null)
          _IconLine(icon: Icons.nights_stay_outlined, text: shiftWindow!),
        if (shiftWindow != null && hasChips)
          const SizedBox(height: AppSpacing.xs),
        if (hasChips)
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              if (state != null)
                StatusChip(label: state.label, type: state.type, width: null),
              if (correctionLabel != null)
                StatusChip(
                  label: correctionLabel!,
                  type: StatusType.neutral,
                  width: null,
                ),
              if (overtimeLabel != null)
                StatusChip(
                  label: overtimeLabel!,
                  type: overtimeType,
                  width: null,
                ),
            ],
          ),
        if (detail != null) ...[
          const SizedBox(height: AppSpacing.xs),
          _IconLine(icon: state!.icon, text: detail),
        ],
      ],
    );
  }
}

class _IconLine extends StatelessWidget {
  const _IconLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 14, color: AppColors.secondary),
      const SizedBox(width: AppSpacing.xs),
      Expanded(
        child: Text(
          text,
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ),
    ],
  );
}
