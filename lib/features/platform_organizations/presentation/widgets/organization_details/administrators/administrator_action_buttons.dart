import 'package:flutter/material.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/features/platform_organizations/domain/models/organization_admin_status.dart';
import 'package:workaxis/features/platform_organizations/domain/models/organization_admin_user.dart';
import 'package:workaxis/features/platform_organizations/presentation/widgets/organization_details/administrators/administrator_parts.dart';

/// Called when the user picks an action for an administrator.
typedef AdministratorActionCallback = void Function(
  OrganizationAdminUser administrator,
  OrganizationAdminAction action,
);

/// Edit, reset-password and suspend/restore buttons for one administrator.
///
/// The third button reflects the account's current state (suspend when
/// active, restore when suspended) and is disabled for the last active admin.
class AdministratorActionButtons extends StatelessWidget {
  const AdministratorActionButtons({
    super.key,
    required this.administrator,
    required this.onAction,
    required this.canSuspend,
    this.enabled = true,
  });

  final OrganizationAdminUser administrator;
  final AdministratorActionCallback onAction;

  /// Whether this administrator may be suspended (false for the last active
  /// administrator).
  final bool canSuspend;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final isActive = administrator.status == OrganizationAdminStatus.active;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ActionIcon(
          tooltip: 'Edit administrator',
          icon: Icons.edit_outlined,
          onPressed: enabled
              ? () => onAction(administrator, OrganizationAdminAction.edit)
              : null,
        ),
        _ActionIcon(
          tooltip: 'Reset password',
          icon: Icons.key_outlined,
          onPressed: enabled
              ? () => onAction(
                  administrator,
                  OrganizationAdminAction.resetPassword,
                )
              : null,
        ),
        if (isActive)
          _ActionIcon(
            tooltip: canSuspend
                ? 'Suspend administrator'
                : lastActiveAdminTooltip,
            icon: Icons.person_off_outlined,
            onPressed: enabled && canSuspend
                ? () => onAction(administrator, OrganizationAdminAction.suspend)
                : null,
          )
        else
          _ActionIcon(
            tooltip: 'Restore administrator',
            icon: Icons.how_to_reg_outlined,
            onPressed: enabled
                ? () => onAction(administrator, OrganizationAdminAction.restore)
                : null,
          ),
      ],
    );
  }
}

class _ActionIcon extends StatelessWidget {
  const _ActionIcon({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: tooltip,
    onPressed: onPressed,
    icon: Icon(icon, size: 20, color: AppColors.secondary),
    constraints: const BoxConstraints(
      minWidth: AppSpacing.minTouchTarget,
      minHeight: AppSpacing.minTouchTarget,
    ),
  );
}
