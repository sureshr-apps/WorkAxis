import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/app/theme/app_typography.dart';
import 'package:workaxis/core/validation/login_email.dart';
import 'package:workaxis/core/widgets/attachment_image.dart';
import 'package:workaxis/features/authentication/domain/models/account_status.dart';
import 'package:workaxis/features/employees/domain/models/organization_member.dart';

/// Read-only profile of one organization account, shown on the employee details
/// page. Holds the sections only; the page supplies the navigation and header.
class MemberDetailsView extends StatelessWidget {
  const MemberDetailsView({
    super.key,
    required this.member,
    required this.branchNames,
  });

  final OrganizationMember member;
  final List<String> branchNames;

  static final _dateFormat = DateFormat('dd MMM yyyy');

  @override
  Widget build(BuildContext context) {
    final email = LoginEmail.displayable(member.email);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(child: _Avatar(member: member)),
        const SizedBox(height: AppSpacing.md),
        Center(
          child: Column(
            children: [
              Text(
                member.fullName,
                style: AppTypography.headlineMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              if (member.designation != null &&
                  member.designation!.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  member.designation!,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              if (member.employeeCode != null &&
                  member.employeeCode!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
                  ),
                  child: Text(
                    member.employeeCode!,
                    style: AppTypography.labelMono.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        const Divider(height: 1),
        const SizedBox(height: AppSpacing.sm),

        _Detail(label: 'Role', value: member.role.displayName),
        _Detail(label: 'Username', value: member.username),
        _Detail(label: 'Mobile', value: member.phone ?? 'Not provided'),
        _Detail(label: 'Email', value: email.isEmpty ? 'Not provided' : email),
        _Detail(
          label: 'Status',
          value: member.status == AccountStatus.active ? 'Active' : 'Suspended',
        ),

        if (member.gender != null)
          _Detail(label: 'Gender', value: member.gender!),
        if (member.dateOfBirth != null)
          _Detail(
            label: 'Date of Birth',
            value: _dateFormat.format(member.dateOfBirth!),
          ),
        if (member.aadhaarNumber != null && member.aadhaarNumber!.isNotEmpty)
          _Detail(
            label: 'Aadhaar Number',
            value: member.aadhaarNumber!
                .replaceAllMapped(RegExp(r'.{4}'), (m) => '${m.group(0)} ')
                .trim(),
          ),
        if (member.aadhaarPhotoUrl != null &&
            member.aadhaarPhotoUrl!.isNotEmpty)
          const _Detail(
            label: 'Aadhaar Card',
            value: 'Attached Document Available',
          ),
        if (member.address != null && member.address!.isNotEmpty)
          _Detail(label: 'Address', value: member.address!),

        const Divider(height: 16),

        _Detail(
          label: 'Work hours',
          value:
              '${member.dailyWorkHours == member.dailyWorkHours.roundToDouble() ? member.dailyWorkHours.toInt() : member.dailyWorkHours.toStringAsFixed(1)} hrs / day',
        ),
        if (member.shiftHours != null && member.shiftHours!.isNotEmpty)
          _Detail(label: 'Shift window', value: member.shiftHours!),

        if (member.joiningDate != null)
          _Detail(
            label: 'Joining Date',
            value: _dateFormat.format(member.joiningDate!),
          ),
        if (member.relievingDate != null)
          _Detail(
            label: 'Relieving Date',
            value: _dateFormat.format(member.relievingDate!),
          ),
        if (member.salary != null)
          _Detail(
            label: 'Monthly Salary',
            value: '₹${member.salary!.toStringAsFixed(0)}',
          ),
        _Detail(
          label: 'Branches',
          value: branchNames.isEmpty ? 'None' : branchNames.join(', '),
        ),
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.member});

  final OrganizationMember member;

  @override
  Widget build(BuildContext context) {
    final photoPath = member.profilePhotoUrl;
    return CircleAvatar(
      radius: 36,
      backgroundColor: AppColors.primaryContainer,
      child: photoPath != null && photoPath.isNotEmpty
          ? ClipOval(
              child: SizedBox.square(
                dimension: 72,
                child: AttachmentImage(reference: photoPath, iconSize: 28),
              ),
            )
          : Text(
              member.initials,
              style: AppTypography.headlineMedium.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              value,
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
