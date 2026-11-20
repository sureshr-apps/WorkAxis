import 'dart:async';

import 'package:flutter/material.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/app/theme/app_typography.dart';
import 'package:workaxis/core/responsive/responsive_layout.dart';
import 'package:workaxis/core/widgets/access_panel.dart';
import 'package:workaxis/core/widgets/app_button.dart';
import 'package:workaxis/core/widgets/app_icon_button.dart';
import 'package:workaxis/core/widgets/status_chip.dart';

/// The Account access panel of a user's details page. The sign-in status and a
/// delete icon sit at the top right; below them are the status message and the
/// Reset and Suspend or Restore actions. Pass null to leave an action out.
class AccountStatusPanel extends StatelessWidget {
  const AccountStatusPanel({
    super.key,
    required this.isActive,
    required this.activeMessage,
    required this.inactiveMessage,
    this.isUpdating = false,
    this.onReset,
    this.onToggleActive,
    this.onDelete,
    this.deleteTooltip = 'Delete',
  });

  final bool isActive;

  /// Explains what an active account can do.
  final String activeMessage;

  /// Explains what a suspended account cannot do.
  final String inactiveMessage;

  /// Disables the actions while a change is being saved.
  final bool isUpdating;
  final FutureOr<void> Function()? onReset;
  final FutureOr<void> Function()? onToggleActive;
  final FutureOr<void> Function()? onDelete;
  final String deleteTooltip;

  @override
  Widget build(BuildContext context) {
    final isCompact = context.isCompact;

    final statusText = Text(
      isActive ? activeMessage : inactiveMessage,
      style: AppTypography.bodyMedium.copyWith(
        color: AppColors.onSurfaceVariant,
      ),
    );

    final headerActions = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        StatusChip.fromStatus(isActive ? 'Active' : 'Suspended'),
        if (onDelete != null) ...[
          const SizedBox(width: AppSpacing.xs),
          AppIconButton(
            tooltip: deleteTooltip,
            icon: Icons.delete_outline,
            color: AppColors.statusUrgentText,
            constraints: const BoxConstraints(
              minWidth: AppSpacing.minTouchTarget,
              minHeight: AppSpacing.minTouchTarget,
            ),
            onPressed: isUpdating ? null : onDelete,
          ),
        ],
      ],
    );

    final buttons = [
      if (onReset != null)
        AppButton.outlined(
          text: 'Reset',
          iconData: Icons.key_outlined,
          isFullWidth: isCompact,
          onPressed: isUpdating ? null : onReset,
        ),
      if (onToggleActive != null)
        isActive
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
              ),
    ];

    return AccessPanel(
      title: 'Account access',
      trailing: headerActions,
      child: isCompact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                statusText,
                if (buttons.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      for (final (index, button) in buttons.indexed) ...[
                        if (index > 0) const SizedBox(width: AppSpacing.sm),
                        Expanded(child: button),
                      ],
                    ],
                  ),
                ],
              ],
            )
          : Row(
              children: [
                Expanded(child: statusText),
                for (final button in buttons) ...[
                  const SizedBox(width: AppSpacing.sm),
                  button,
                ],
              ],
            ),
    );
  }
}
