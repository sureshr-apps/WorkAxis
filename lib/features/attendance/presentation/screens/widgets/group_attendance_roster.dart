import 'package:flutter/material.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/app/theme/app_typography.dart';
import 'package:workaxis/core/widgets/app_button.dart';
import 'package:workaxis/core/widgets/app_text_field.dart';
import 'package:workaxis/core/widgets/empty_state.dart';
import 'package:workaxis/core/widgets/status_chip.dart';
import 'package:workaxis/features/attendance/presentation/screens/widgets/group_attendance_form_controller.dart';

/// Searchable, bounded roster with per-employee selection.
class GroupAttendanceRoster extends StatefulWidget {
  const GroupAttendanceRoster({super.key, required this.form});

  final GroupAttendanceFormController form;

  @override
  State<GroupAttendanceRoster> createState() => _GroupAttendanceRosterState();
}

class _GroupAttendanceRosterState extends State<GroupAttendanceRoster> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final form = widget.form;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Personnel Roster',
                  style: AppTypography.bodyLarge.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '${form.selectedCount} of ${form.memberCount} selected',
                  style: AppTypography.bodySmall,
                ),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppButton.outlined(
                  text: 'Select All',
                  isFullWidth: false,
                  onPressed: form.selectAllUnrecorded,
                ),
                const SizedBox(width: AppSpacing.sm),
                AppButton.outlined(
                  text: 'Clear',
                  isFullWidth: false,
                  onPressed: form.clearSelection,
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        AppTextField.search(
          controller: _searchController,
          hintText: 'Filter by employee name or username...',
          onChanged: form.setSearch,
        ),
        const SizedBox(height: AppSpacing.sm),
        _body(form),
      ],
    );
  }

  Widget _body(GroupAttendanceFormController form) {
    if (form.isLoadingMembers) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.xl),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    final members = form.visibleMembers;
    if (members.isEmpty) {
      return const EmptyState(
        icon: Icons.group_off_outlined,
        title: 'No eligible active employees found for this branch.',
      );
    }
    return Container(
      constraints: const BoxConstraints(maxHeight: 360),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.outlineSubtle),
        borderRadius: AppSpacing.roundedMd,
      ),
      clipBehavior: Clip.antiAlias,
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: members.length,
        separatorBuilder: (_, _) =>
            const Divider(height: 1, color: AppColors.outlineSubtle),
        itemBuilder: (context, index) {
          final member = members[index];
          return CheckboxListTile(
            key: ValueKey(member.id),
            value: form.isSelected(member),
            dense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xxs,
            ),
            activeColor: AppColors.primary,
            onChanged: (checked) => form.toggle(member, checked == true),
            secondary: CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primaryContainer,
              child: Text(
                member.initials,
                style: AppTypography.labelMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.onPrimaryContainer,
                ),
              ),
            ),
            title: Row(
              children: [
                Flexible(
                  child: Text(
                    member.fullName,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (form.isRecorded(member)) ...[
                  const SizedBox(width: AppSpacing.sm),
                  const StatusChip(
                    label: 'Checked In',
                    type: StatusType.active,
                    width: null,
                  ),
                ],
              ],
            ),
            subtitle: Text(
              '@${member.username}',
              style: AppTypography.bodySmall,
            ),
          );
        },
      ),
    );
  }
}
