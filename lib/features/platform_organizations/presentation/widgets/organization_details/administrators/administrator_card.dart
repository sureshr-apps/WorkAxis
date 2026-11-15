import 'package:flutter/material.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/app/theme/app_typography.dart';
import 'package:workaxis/features/platform_organizations/domain/models/organization_admin_user.dart';
import 'package:workaxis/features/platform_organizations/presentation/widgets/organization_details/administrators/administrator_action_buttons.dart';
import 'package:workaxis/features/platform_organizations/presentation/widgets/organization_details/administrators/administrator_parts.dart';

/// Phone and tablet card for one administrator: identity and status, contact
/// details, then a labelled action row set off by a full-width divider.
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
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    _CardAvatar(initials: administrator.initials),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            administrator.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.titleMedium.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            administrator.displayUsername,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.labelMono.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
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
              ],
            ),
          ),
          const Divider(
            height: 1,
            thickness: 1,
            color: AppColors.outlineSubtle,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            child: AdministratorActionButtons(
              administrator: administrator,
              onAction: onAction,
              canSuspend: canSuspend,
              enabled: enabled,
              labelled: true,
            ),
          ),
        ],
      ),
    );
  }
}

/// Larger mint avatar used on the card header.
class _CardAvatar extends StatelessWidget {
  const _CardAvatar({required this.initials});

  final String initials;

  @override
  Widget build(BuildContext context) => Container(
    width: 44,
    height: 44,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: AppColors.onTertiaryContainer.withValues(alpha: 0.35),
      shape: BoxShape.circle,
      border: Border.all(
        color: AppColors.onTertiaryContainer.withValues(alpha: 0.7),
      ),
    ),
    child: Text(
      initials,
      style: AppTypography.labelMedium.copyWith(
        fontWeight: FontWeight.w700,
        color: AppColors.tertiary,
      ),
    ),
  );
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 18, color: AppColors.secondary),
      const SizedBox(width: AppSpacing.sm),
      Expanded(
        child: Text(
          value,
          style: AppTypography.bodyMedium.copyWith(color: AppColors.onSurface),
        ),
      ),
    ],
  );
}
