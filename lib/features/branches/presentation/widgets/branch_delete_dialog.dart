import 'package:flutter/material.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/features/branches/domain/models/branch_record.dart';

/// Asks before permanently deleting [branch]. Resolves to true only when the
/// user confirms.
Future<bool> confirmBranchDelete(
  BuildContext context,
  BranchRecord branch,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text('Delete ${branch.name}?'),
      content: const Text(
        'The branch is removed for good. A branch with employees, returns '
        'or attendance cannot be deleted; suspend it instead.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.statusUrgentText,
          ),
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  return confirmed == true;
}
