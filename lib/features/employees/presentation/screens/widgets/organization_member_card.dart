import 'package:flutter/material.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/core/widgets/account_card/account_card.dart';
import 'package:workaxis/core/widgets/account_card/account_card_actions.dart';
import 'package:workaxis/core/widgets/attachment_image.dart';
import 'package:workaxis/core/widgets/status_chip.dart';
import 'package:workaxis/features/authentication/domain/models/account_status.dart';
import 'package:workaxis/features/employees/domain/models/organization_member.dart';

/// One organization account in the employee directory. Uses the shared
/// [AccountCard] layout, the same as the platform administrator cards: the
/// member's photo or initials, name and username, status, role and designation,
/// employee code and branches, and an Edit action. Tapping the header and
/// details opens the account.
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
    final isActive = member.status == AccountStatus.active;
    final editHandler = onEdit;

    return KeyedSubtree(
      key: Key('employee-card-${member.id}'),
      child: AccountCard(
        avatar: _MemberAvatar(member: member),
        name: member.fullName,
        username: member.username,
        statusChip: StatusChip(
          label: isActive ? 'ACTIVE' : 'SUSPENDED',
          type: isActive ? StatusType.active : StatusType.urgent,
        ),
        details: [
          AccountCardDetail(icon: Icons.work_outline, value: _roleLine(member)),
          AccountCardDetail(
            icon: Icons.badge_outlined,
            value: 'Employee code: ${_codeOrNotSet(member)}',
          ),
          AccountCardDetail(
            icon: Icons.store_outlined,
            value:
                'Branches: ${branchNames.isEmpty ? 'None' : branchNames.join(', ')}',
          ),
        ],
        footer: editHandler == null
            ? null
            : AccountCardActions(
                actions: [
                  AccountCardAction(
                    label: 'Edit',
                    icon: Icons.edit_outlined,
                    color: AppColors.secondary,
                    onPressed: editHandler,
                  ),
                ],
              ),
        onTap: onOpen,
        onTapLabel: 'View details for ${member.fullName}',
      ),
    );
  }

  static String _codeOrNotSet(OrganizationMember member) {
    final code = member.employeeCode;
    return code == null || code.isEmpty ? 'Not set' : code;
  }

  static String _roleLine(OrganizationMember member) {
    final designation = member.designation;
    return designation != null && designation.isNotEmpty
        ? '$designation  ·  ${member.role.displayName}'
        : member.role.displayName;
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
      radius: 22,
      backgroundColor: AppColors.primaryContainer,
      child: photo != null && photo.isNotEmpty
          ? ClipOval(
              child: SizedBox.square(
                dimension: 44,
                child: AttachmentImage(reference: photo, iconSize: 20),
              ),
            )
          : Text(
              member.initials,
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
    );
  }
}
