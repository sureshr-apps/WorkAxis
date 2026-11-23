import 'package:flutter/material.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/app/theme/app_typography.dart';
import 'package:workaxis/core/widgets/card_action_icon.dart';
import 'package:workaxis/features/leave_policy/domain/models/leave_type_policy.dart';
import 'package:workaxis/features/leave_policy/presentation/formatting/leave_days_format.dart';

/// One leave type row: name, allowance summary, and edit/remove actions.
/// The unpaid type offers no remove action.
class LeaveTypeTile extends StatelessWidget {
  const LeaveTypeTile({
    super.key,
    required this.leaveType,
    required this.onEdit,
    required this.onRemove,
  });

  final LeaveTypePolicy leaveType;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  String get _summary {
    if (!leaveType.hasAllowance) return 'No allowance · always unpaid';
    final perYear = LeaveDaysFormat.perYear(leaveType.yearlyDays);
    return leaveType.carryForward ? '$perYear · Carries forward' : perYear;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.outlineSubtle)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  leaveType.name,
                  style: AppTypography.labelLarge.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(_summary, style: AppTypography.bodySmall),
              ],
            ),
          ),
          CardActionIcon(
            tooltip: 'Edit ${leaveType.name}',
            icon: Icons.edit_outlined,
            color: AppColors.primary,
            // Not awaited: the dialog shows progress, not the icon.
            onPressed: () {
              onEdit();
            },
          ),
          if (leaveType.canBeRemoved)
            CardActionIcon(
              tooltip: 'Remove ${leaveType.name}',
              icon: Icons.delete_outline,
              color: AppColors.statusUrgentText,
              onPressed: () {
                onRemove();
              },
            ),
        ],
      ),
    );
  }
}
