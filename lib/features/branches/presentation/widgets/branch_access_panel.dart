import 'package:flutter/material.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/app/theme/app_typography.dart';
import 'package:workaxis/core/responsive/responsive_layout.dart';
import 'package:workaxis/core/widgets/access_panel.dart';
import 'package:workaxis/core/widgets/app_button.dart';
import 'package:workaxis/core/widgets/status_chip.dart';
import 'package:workaxis/features/branches/domain/models/branch_record.dart';

/// Account access section of the branch details page, laid out like the
/// administrator's Account access panel: the status and a delete icon at the
/// top right, then Edit and Suspend or Restore.
class BranchAccessPanel extends StatelessWidget {
  const BranchAccessPanel({
    super.key,
    required this.branch,
    required this.isUpdating,
    required this.onEdit,
    required this.onToggleActive,
    required this.onDelete,
  });

  final BranchRecord branch;
  final bool isUpdating;
  final VoidCallback onEdit;
  final VoidCallback onToggleActive;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isActive = branch.isActive;
    final isCompact = context.isCompact;

    final editButton = AppButton.outlined(
      text: 'Edit',
      iconData: Icons.edit_outlined,
      isFullWidth: isCompact,
      onPressed: isUpdating ? null : onEdit,
    );
    final toggleButton = isActive
        ? AppButton.outlined(
            text: 'Suspend',
            iconData: Icons.block_outlined,
            isFullWidth: isCompact,
            onPressed: isUpdating ? null : onToggleActive,
          )
        : AppButton.secondary(
            text: 'Restore',
            iconData: Icons.check_circle_outline,
            isFullWidth: isCompact,
            onPressed: isUpdating ? null : onToggleActive,
          );

    final statusText = Text(
      isActive
          ? 'This branch is active and open for attendance.'
          : 'This branch is suspended and not open for attendance.',
      style: AppTypography.bodyMedium.copyWith(
        color: AppColors.onSurfaceVariant,
      ),
    );

    final headerActions = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        StatusChip.fromStatus(isActive ? 'Active' : 'Inactive'),
        const SizedBox(width: AppSpacing.xs),
        IconButton(
          tooltip: 'Delete ${branch.name}',
          icon: const Icon(
            Icons.delete_outline,
            color: AppColors.statusUrgentText,
          ),
          constraints: const BoxConstraints(
            minWidth: AppSpacing.minTouchTarget,
            minHeight: AppSpacing.minTouchTarget,
          ),
          onPressed: isUpdating ? null : onDelete,
        ),
      ],
    );

    return AccessPanel(
      title: 'Branch access',
      trailing: headerActions,
      child: isCompact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                statusText,
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(child: editButton),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(child: toggleButton),
                  ],
                ),
              ],
            )
          : Row(
              children: [
                Expanded(child: statusText),
                const SizedBox(width: AppSpacing.md),
                editButton,
                const SizedBox(width: AppSpacing.sm),
                toggleButton,
              ],
            ),
    );
  }
}
