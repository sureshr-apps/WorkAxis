import 'package:flutter/material.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/app/theme/app_typography.dart';
import 'package:workaxis/features/platform_organizations/domain/models/organization_admin_user.dart';
import 'package:workaxis/features/platform_organizations/presentation/widgets/organization_details/administrators/administrator_action_buttons.dart';
import 'package:workaxis/features/platform_organizations/presentation/widgets/organization_details/administrators/administrator_parts.dart';

/// Phone and tablet card for one administrator.
class AdministratorCard extends StatelessWidget {
  const AdministratorCard({
    super.key,
    required this.administrator,
    required this.onAction,
    required this.canSuspend,
    required this.enabled,
  });

  final OrganizationAdminUser administrator;
  final AdministratorActionCallback onAction;
  final bool canSuspend;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return AdministratorPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: AdministratorIdentity(administrator: administrator),
              ),
              const SizedBox(width: AppSpacing.sm),
              AdministratorStatusChip(status: administrator.status),
            ],
          ),
          const Divider(height: AppSpacing.xl),
          _ContactRow(
            icon: Icons.mail_outline,
            value: orDash(administrator.email),
          ),
          const SizedBox(height: AppSpacing.sm),
          _ContactRow(
            icon: Icons.call_outlined,
            value: orDash(administrator.phone),
          ),
          const SizedBox(height: AppSpacing.sm),
          _ContactRow(
            icon: Icons.schedule_outlined,
            value: 'Last login: ${administrator.lastLogin ?? '—'}',
          ),
          Align(
            alignment: Alignment.centerRight,
            child: AdministratorActionButtons(
              administrator: administrator,
              onAction: onAction,
              canSuspend: canSuspend,
              enabled: enabled,
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 16, color: AppColors.secondary),
      const SizedBox(width: AppSpacing.sm),
      Expanded(child: Text(value, style: AppTypography.bodySmall)),
    ],
  );
}
