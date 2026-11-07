import 'package:flutter/material.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_shadows.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/app/theme/app_typography.dart';
import 'package:workaxis/core/time/clock.dart';
import 'package:workaxis/core/widgets/status_chip.dart';
import 'package:workaxis/features/authentication/domain/models/account_status.dart';
import 'package:workaxis/features/platform_users/domain/administrator_activity_label.dart';
import 'package:workaxis/features/platform_users/domain/models/platform_administrator.dart';
import 'package:workaxis/features/platform_users/presentation/widgets/platform_administrator_action_menu.dart';
import 'package:workaxis/features/platform_users/presentation/widgets/platform_administrator_avatar.dart';

class PlatformAdministratorCard extends StatelessWidget {
  const PlatformAdministratorCard({
    super.key,
    required this.administrator,
    required this.onTap,
    required this.onAction,
    this.now = systemNow,
  });

  final PlatformAdministrator administrator;
  final VoidCallback onTap;
  final ValueChanged<PlatformAdministratorAction> onAction;

  /// Clock used for the relative "last active" text.
  final Now now;

  @override
  Widget build(BuildContext context) {
    final statusLabel = administrator.status == AccountStatus.active
        ? 'Active'
        : 'Suspended';

    return Semantics(
      button: true,
      label: 'View details for ${administrator.fullName}',
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: AppSpacing.roundedMd,
          border: Border.all(color: AppColors.outlineSubtle),
          boxShadow: AppShadows.card,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: AppSpacing.roundedMd,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      PlatformAdministratorAvatar(
                        initials: administrator.initials,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.xxs),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                administrator.fullName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xxs),
                              Text(
                                'Platform Administrator',
                                style: AppTypography.labelSmall,
                              ),
                            ],
                          ),
                        ),
                      ),
                      PlatformAdministratorActionMenu(
                        administrator: administrator,
                        onSelected: onAction,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _IdentifierLine(
                    icon: Icons.alternate_email,
                    value: administrator.username,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  _IdentifierLine(
                    icon: Icons.mail_outline,
                    value: administrator.email.isEmpty
                        ? '—'
                        : administrator.email,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const Divider(height: 1, color: AppColors.outlineSubtle),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      StatusChip.fromStatus(statusLabel),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          AdministratorActivityLabel.sentence(
                            administrator.lastActiveAt,
                            now(),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.labelSmall,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Details',
                            style: AppTypography.labelMedium.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xxs),
                          const Icon(
                            Icons.chevron_right_rounded,
                            size: 16,
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _IdentifierLine extends StatelessWidget {
  const _IdentifierLine({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.onSurfaceVariant),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodySmall,
          ),
        ),
      ],
    );
  }
}
