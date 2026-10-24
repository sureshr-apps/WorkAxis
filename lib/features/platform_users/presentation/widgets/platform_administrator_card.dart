import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/core/widgets/status_chip.dart';
import 'package:workaxis/features/authentication/domain/models/account_status.dart';
import 'package:workaxis/features/platform_users/domain/models/platform_administrator.dart';
import 'package:workaxis/features/platform_users/presentation/widgets/platform_administrator_action_menu.dart';

class PlatformAdministratorCard extends StatelessWidget {
  const PlatformAdministratorCard({
    super.key,
    required this.administrator,
    required this.onTap,
    required this.onAction,
  });

  final PlatformAdministrator administrator;
  final VoidCallback onTap;
  final ValueChanged<PlatformAdministratorAction> onAction;

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
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: AppColors.outlineSubtle),
          boxShadow: const [
            BoxShadow(
              color: Color(0x06000000),
              offset: Offset(0, 2),
              blurRadius: 6,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _AdministratorAvatar(initials: administrator.initials),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              administrator.fullName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.onSurface,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Platform Administrator',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: AppColors.onSurfaceVariant,
                              ),
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
                  value: administrator.email,
                ),
                const SizedBox(height: AppSpacing.md),
                const Divider(height: 1, color: AppColors.outlineSubtle),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    StatusChip.fromStatus(
                      statusLabel,
                      width: 96,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        _lastActiveLabel(administrator.lastActiveAt),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Details',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 2),
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

  String _lastActiveLabel(DateTime? lastActive) {
    if (lastActive == null) return 'Never signed in';
    final elapsed = DateTime.now().difference(lastActive);
    if (elapsed.inMinutes < 60) return 'Active ${elapsed.inMinutes}m ago';
    if (elapsed.inHours < 24) return 'Active ${elapsed.inHours}h ago';
    if (elapsed.inDays == 1) return 'Active yesterday';
    return 'Active ${elapsed.inDays}d ago';
  }
}

class _AdministratorAvatar extends StatelessWidget {
  const _AdministratorAvatar({required this.initials});

  final String initials;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
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
        Icon(icon, size: 15, color: AppColors.onSurfaceVariant),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}
