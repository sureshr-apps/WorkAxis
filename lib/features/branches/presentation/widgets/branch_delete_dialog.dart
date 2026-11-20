import 'package:flutter/material.dart';
import 'package:workaxis/core/widgets/async_confirmation_dialog.dart';
import 'package:workaxis/features/branches/domain/models/branch_record.dart';

/// Confirms branch deletion and waits for the delete request before closing.
Future<bool> confirmBranchDelete(
  BuildContext context,
  BranchRecord branch, {
  required Future<bool> Function() onConfirm,
  String? Function()? failureMessage,
}) => showAsyncConfirmationDialog(
  context: context,
  title: 'Delete ${branch.name}?',
  content: const Text(
    'The branch is removed for good. A branch with employees, returns '
    'or attendance cannot be deleted; suspend it instead.',
  ),
  confirmLabel: 'Delete',
  destructive: true,
  onConfirm: onConfirm,
  failureMessage: failureMessage,
);
