import 'package:flutter/material.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/app/theme/app_typography.dart';
import 'package:workaxis/features/platform_organizations/domain/models/organization_admin_status.dart';
import 'package:workaxis/features/platform_organizations/domain/models/organization_admin_user.dart';
import 'package:workaxis/features/platform_organizations/presentation/widgets/organization_details/administrators/administrator_parts.dart';

/// Called when the user picks an action for an administrator.
typedef AdministratorActionCallback = void Function(
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

  /// Whether this administrator may be suspended (false for the last active
  /// administrator).
  final bool canSuspend;
  final bool enabled;
  final bool labelled;

  @override
  Widget build(BuildContext context) {
    final isActive = administrator.status == OrganizationAdminStatus.active;
    final actions = [
      _ActionSpec(
        tooltip: 'Edit administrator',
        label: 'Edit',
        icon: Icons.edit_outlined,
        color: AppColors.secondary,
        onPressed: enabled
            ? () => onAction(administrator, OrganizationAdminAction.edit)
            : null,
      ),
      _ActionSpec(
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
        _ActionSpec(
          tooltip: canSuspend
              ? 'Suspend administrator'
              : lastActiveAdminTooltip,
          label: 'Suspend',
          icon: Icons.person_off_outlined,
          color: AppColors.statusUrgentText,
          onPressed: enabled && canSuspend
              ? () => onAction(administrator, OrganizationAdminAction.suspend)
              : null,
        )
      else
        _ActionSpec(
          tooltip: 'Restore administrator',
          label: 'Restore',
          icon: Icons.how_to_reg_outlined,
          color: AppColors.kpiPositive,
          onPressed: enabled
              ? () => onAction(administrator, OrganizationAdminAction.restore)
              : null,
        ),
    ];

    if (labelled) {
      return Wrap(
        alignment: WrapAlignment.spaceEvenly,
        runSpacing: AppSpacing.xs,
        children: [for (final action in actions) _LabelledAction(spec: action)],
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [for (final action in actions) _IconAction(spec: action)],
    );
  }
}

/// One administrator action, shared by the icon and labelled presentations.
class _ActionSpec {
  const _ActionSpec({
    required this.tooltip,
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  final String tooltip;
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onPressed;
}

class _IconAction extends StatelessWidget {
  const _IconAction({required this.spec});

  final _ActionSpec spec;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: spec.tooltip,
    onPressed: spec.onPressed,
    icon: Icon(spec.icon, size: 20, color: AppColors.secondary),
    constraints: const BoxConstraints(
      minWidth: AppSpacing.minTouchTarget,
      minHeight: AppSpacing.minTouchTarget,
    ),
  );
}

class _LabelledAction extends StatelessWidget {
  const _LabelledAction({required this.spec});

  final _ActionSpec spec;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: spec.tooltip,
    child: TextButton.icon(
      onPressed: spec.onPressed,
      icon: Icon(spec.icon, size: 18, color: spec.color),
      label: Text(
        spec.label,
        style: AppTypography.labelMedium.copyWith(
          fontWeight: FontWeight.w600,
          color: spec.color,
        ),
      ),
      style: TextButton.styleFrom(
        minimumSize: const Size.square(AppSpacing.minTouchTarget),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      ),
    ),
  );
}
