import 'dart:async';

import 'package:flutter/material.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/core/widgets/account_card/account_card_actions.dart';
import 'package:workaxis/core/widgets/app_icon_button.dart';
import 'package:workaxis/features/platform_organizations/domain/models/organization_admin_status.dart';
import 'package:workaxis/features/platform_organizations/domain/models/organization_admin_user.dart';
import 'package:workaxis/features/platform_organizations/presentation/widgets/organization_details/administrators/administrator_parts.dart';

/// Called when the user picks an action for an administrator.
typedef AdministratorActionCallback = FutureOr<void> Function(
  OrganizationAdminUser administrator,
  OrganizationAdminAction action,
);

/// Edit, reset-password and suspend/restore actions for one administrator.
///
/// The third action reflects the account's current state (suspend when
/// active, restore when suspended) and is disabled for the last active admin.
/// Icon-only in tables; [labelled] shows text beside the icons for cards.
class AdministratorActionButtons extends StatelessWidget {
  const AdministratorActionButtons({
    super.key,
    required this.administrator,
    required this.onAction,
    required this.canSuspend,
    this.enabled = true,
    this.labelled = false,
  });

  final OrganizationAdminUser administrator;
  final AdministratorActionCallback onAction;

  /// Whether this administrator may be suspended. Only the tooltip depends on
  /// it: a refused suspend is still tappable and explains itself on tap.
  final bool canSuspend;
  final bool enabled;
  final bool labelled;

  @override
  Widget build(BuildContext context) {
    final isActive = administrator.status == OrganizationAdminStatus.active;
    final actions = <AccountCardAction>[
      AccountCardAction(
        tooltip: 'Edit administrator',
        label: 'Edit',
        icon: Icons.edit_outlined,
        color: AppColors.secondary,
        onPressed: enabled
            ? () => onAction(administrator, OrganizationAdminAction.edit)
            : null,
      ),
      AccountCardAction(
        tooltip: 'Reset password',
        label: 'Reset Password',
        icon: Icons.key_outlined,
        color: AppColors.secondary,
        onPressed: enabled
            ? () =>
                  onAction(administrator, OrganizationAdminAction.resetPassword)
            : null,
      ),
      if (isActive)
        AccountCardAction(
          tooltip: canSuspend
              ? 'Suspend administrator'
              : lastActiveAdminTooltip,
          label: 'Suspend',
          icon: Icons.person_off_outlined,
          color: AppColors.statusUrgentText,
          onPressed: enabled
              ? () => onAction(administrator, OrganizationAdminAction.suspend)
              : null,
        )
      else
        AccountCardAction(
          tooltip: 'Restore administrator',
          label: 'Restore',
          icon: Icons.how_to_reg_outlined,
          color: AppColors.kpiPositive,
          onPressed: enabled
              ? () => onAction(administrator, OrganizationAdminAction.restore)
              : null,
        ),
      AccountCardAction(
        tooltip: 'Delete administrator',
        label: 'Delete',
        icon: Icons.delete_outline,
        color: AppColors.statusUrgentText,
        onPressed: enabled
            ? () => onAction(administrator, OrganizationAdminAction.delete)
            : null,
      ),
    ];

    if (labelled) return AccountCardActions(actions: actions);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [for (final action in actions) _IconAction(spec: action)],
    );
  }
}

class _IconAction extends StatelessWidget {
  const _IconAction({required this.spec});

  final AccountCardAction spec;

  @override
  Widget build(BuildContext context) => AppIconButton(
    tooltip: spec.tooltip ?? spec.label,
    onPressed: spec.onPressed,
    icon: spec.icon,
    color: spec.color,
    constraints: const BoxConstraints(
      minWidth: AppSpacing.minTouchTarget,
      minHeight: AppSpacing.minTouchTarget,
    ),
  );
}
