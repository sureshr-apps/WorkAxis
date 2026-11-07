import 'package:flutter/material.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_shadows.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/app/theme/app_typography.dart';
import 'package:workaxis/core/validation/login_email.dart';
import 'package:workaxis/core/widgets/app_button.dart';
import 'package:workaxis/core/widgets/status_chip.dart';
import 'package:workaxis/features/authentication/domain/models/account_status.dart';
import 'package:workaxis/features/employees/domain/models/organization_member.dart';

/// Card summarising one organization account in the directory.
class OrganizationMemberCard extends StatelessWidget {
  const OrganizationMemberCard({
    super.key,
    required this.member,
    required this.branchNames,
    required this.onView,
    required this.onEdit,
  });

  final OrganizationMember member;
  final List<String> branchNames;
  final VoidCallback onView;

  /// Null when the caller may not edit this account (the button is hidden).
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final email = LoginEmail.displayable(member.email);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: AppSpacing.roundedMd,
        border: Border.all(color: AppColors.outlineSubtle),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 21,
                backgroundColor: AppColors.primaryContainer,
                child: Text(
                  member.initials,
                  style: AppTypography.labelLarge.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      member.fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      member.role.displayName,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              StatusChip.fromStatus(
                member.status == AccountStatus.active ? 'Active' : 'Suspended',
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _MemberLine(icon: Icons.alternate_email, value: member.username),
          if (email.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            _MemberLine(icon: Icons.mail_outline, value: email),
          ],
          const SizedBox(height: AppSpacing.xs),
          _MemberLine(
            icon: Icons.store_outlined,
            value: branchNames.isEmpty
                ? 'No branch assigned'
                : branchNames.join(', '),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: AppButton.outlined(
                  text: 'View details',
                  iconData: Icons.visibility_outlined,
                  onPressed: onView,
                ),
              ),
              if (onEdit != null) ...[
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: AppButton.primary(
                    text: 'Edit',
                    iconData: Icons.edit_outlined,
                    onPressed: onEdit,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _MemberLine extends StatelessWidget {
  const _MemberLine({required this.icon, required this.value});
  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 16, color: AppColors.onSurfaceVariant),
      const SizedBox(width: AppSpacing.xs),
      Expanded(
        child: Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ),
    ],
  );
}
