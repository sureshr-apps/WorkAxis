import 'package:flutter/material.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/app/theme/app_typography.dart';
import 'package:workaxis/core/widgets/table_header_cell.dart';
import 'package:workaxis/features/platform_organizations/domain/models/organization_admin_user.dart';
import 'package:workaxis/features/platform_organizations/presentation/widgets/organization_details/administrators/administrator_action_buttons.dart';
import 'package:workaxis/features/platform_organizations/presentation/widgets/organization_details/administrators/administrator_parts.dart';

/// Desktop table of administrators with inline actions.
class AdministratorsTable extends StatelessWidget {
  const AdministratorsTable({
    super.key,
    required this.administrators,
    required this.onAction,
    required this.canSuspend,
    required this.enabled,
  });

  final List<OrganizationAdminUser> administrators;
  final AdministratorActionCallback onAction;
  final bool Function(OrganizationAdminUser administrator) canSuspend;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return AdministratorPanel(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: AppSpacing.roundedMd,
        child: Column(
          children: [
            const _TableHeader(),
            for (var index = 0; index < administrators.length; index++) ...[
              if (index > 0)
                const Divider(height: 1, color: AppColors.outlineSubtle),
              _AdministratorRow(
                administrator: administrators[index],
                onAction: onAction,
                canSuspend: canSuspend(administrators[index]),
                enabled: enabled,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader();

  @override
  Widget build(BuildContext context) => Container(
    color: AppColors.surfaceContainerLow,
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.md,
      vertical: AppSpacing.md,
    ),
    child: const Row(
      children: [
        TableHeaderCell('ADMINISTRATOR', flex: 22),
        TableHeaderCell('CONTACT DETAILS', flex: 26),
        TableHeaderCell('STATUS', flex: 14),
        TableHeaderCell('LAST LOGIN', flex: 14),
        TableHeaderCell('ACTIONS', flex: 18, alignment: Alignment.centerRight),
      ],
    ),
  );
}

class _AdministratorRow extends StatelessWidget {
  const _AdministratorRow({
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
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: Row(
        children: [
          Expanded(
            flex: 22,
            child: AdministratorIdentity(administrator: administrator),
          ),
          Expanded(
            flex: 26,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  orDash(administrator.email),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.onSurface,
                  ),
                ),
                Text(
                  orDash(administrator.phone),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.secondary,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 14,
            child: Align(
              alignment: Alignment.centerLeft,
              child: AdministratorStatusChip(status: administrator.status),
            ),
          ),
          Expanded(
            flex: 14,
            child: Text(
              administrator.lastLogin ?? '—',
              style: AppTypography.labelSmall,
            ),
          ),
          Expanded(
            flex: 18,
            child: Align(
              alignment: Alignment.centerRight,
              child: AdministratorActionButtons(
                administrator: administrator,
                onAction: onAction,
                canSuspend: canSuspend,
                enabled: enabled,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
