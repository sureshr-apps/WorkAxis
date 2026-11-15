import 'package:flutter/material.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_shadows.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/app/theme/app_typography.dart';
import 'package:workaxis/core/widgets/attachment_image.dart';
import 'package:workaxis/core/widgets/card_action_icon.dart';
import 'package:workaxis/core/widgets/inset_metrics_box.dart';
import 'package:workaxis/core/widgets/status_chip.dart';
import 'package:workaxis/features/authentication/domain/models/account_status.dart';
import 'package:workaxis/features/employees/domain/models/organization_member.dart';

/// One organization account in the directory, laid out like the branch card:
/// name and status with a chevron on top, the code and branches in an inset
/// box, and the username with the row action in the footer. The whole card
/// opens the account's details.
class OrganizationMemberCard extends StatelessWidget {
  const OrganizationMemberCard({
    super.key,
    required this.member,
    required this.branchNames,
    required this.onOpen,
    required this.onEdit,
  });

  final OrganizationMember member;
  final List<String> branchNames;
  final VoidCallback onOpen;

  /// Null when the caller may not edit this account (the action is hidden).
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onOpen,
      borderRadius: AppSpacing.roundedMd,
      child: Container(
        key: Key('employee-card-${member.id}'),
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
            _Header(member: member),
            const SizedBox(height: AppSpacing.xs),
            Text(
              _roleLine(member),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            InsetMetricsBox(
              metrics: [
                InsetMetric(
                  icon: Icons.badge_outlined,
                  label: 'Employee code',
                  value: _hasCode(member) ? member.employeeCode! : 'Not set',
                ),
                InsetMetric(
                  icon: Icons.store_outlined,
                  label: 'Branches',
                  value: branchNames.isEmpty ? 'None' : branchNames.join(', '),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            _Footer(member: member, onEdit: onEdit),
          ],
        ),
      ),
    );
  }

  static bool _hasCode(OrganizationMember member) =>
      member.employeeCode != null && member.employeeCode!.isNotEmpty;

  static String _roleLine(OrganizationMember member) {
    final designation = member.designation;
    return designation != null && designation.isNotEmpty
        ? '$designation  ·  ${member.role.displayName}'
        : member.role.displayName;
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.member});

  final OrganizationMember member;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _MemberAvatar(member: member),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            member.fullName,
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        StatusChip.fromStatus(
          member.status == AccountStatus.active ? 'Active' : 'Suspended',
          width: 96,
        ),
        const SizedBox(width: AppSpacing.xs),
        const Icon(
          Icons.chevron_right_rounded,
          size: 24,
          color: AppColors.primary,
        ),
      ],
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.member, required this.onEdit});

  final OrganizationMember member;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            '@${member.username}',
            style: AppTypography.labelMono.copyWith(
              fontSize: 11,
              color: AppColors.textMuted,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (onEdit != null)
          CardActionIcon(
            tooltip: 'Edit ${member.fullName}',
            icon: Icons.edit_outlined,
            color: AppColors.secondary,
            onPressed: onEdit!,
          ),
      ],
    );
  }
}

/// Initials avatar, replaced by the member's photo when one is stored.
class _MemberAvatar extends StatelessWidget {
  const _MemberAvatar({required this.member});

  final OrganizationMember member;

  @override
  Widget build(BuildContext context) {
    final photo = member.profilePhotoUrl;
    return CircleAvatar(
      radius: 21,
      backgroundColor: AppColors.primaryContainer,
      child: photo != null && photo.isNotEmpty
          ? ClipOval(
              child: SizedBox.square(
                dimension: 42,
                child: AttachmentImage(reference: photo, iconSize: 20),
              ),
            )
          : Text(
              member.initials,
              style: AppTypography.labelLarge.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
    );
  }
}
