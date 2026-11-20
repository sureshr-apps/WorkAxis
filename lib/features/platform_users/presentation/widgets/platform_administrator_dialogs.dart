import 'package:flutter/material.dart';
import 'package:workaxis/core/widgets/async_confirmation_dialog.dart';
import 'package:workaxis/features/authentication/domain/models/account_status.dart';
import 'package:workaxis/features/platform_users/domain/models/platform_administrator.dart';
import 'package:workaxis/features/platform_users/presentation/widgets/platform_dialog_frame.dart';

/// Confirms a status change and waits for it to finish before closing.
Future<bool> confirmAdministratorStatusChange(
  BuildContext context, {
  required PlatformAdministrator administrator,
  required AccountStatus nextStatus,
  required Future<bool> Function() onConfirm,
  String? Function()? failureMessage,
}) {
  final suspend = nextStatus == AccountStatus.suspended;
  final title = suspend ? 'Suspend access?' : 'Restore access?';
  return showAsyncConfirmationDialog(
    context: context,
    title: title,
    content: Text(
      suspend
          ? '${administrator.fullName} will no longer be able to sign in. '
                'You can restore access later.'
          : 'Allow ${administrator.fullName} to sign in to WorkAxis again?',
    ),
    confirmLabel: suspend ? 'Suspend access' : 'Restore access',
    destructive: suspend,
    onConfirm: onConfirm,
    failureMessage: failureMessage,
    dialogBuilder: (context, content, actions) =>
        PlatformDialogFrame(title: title, body: content, actions: actions),
  );
}

/// Confirms permanent deletion and waits for the request before closing.
Future<bool> confirmAdministratorDelete(
  BuildContext context, {
  required PlatformAdministrator administrator,
  required Future<bool> Function() onConfirm,
  String? Function()? failureMessage,
}) => showAsyncConfirmationDialog(
  context: context,
  title: 'Delete administrator?',
  content: Text(
    '${administrator.fullName} will be removed from WorkAxis and can no '
    'longer sign in. This cannot be undone.',
  ),
  confirmLabel: 'Delete administrator',
  destructive: true,
  onConfirm: onConfirm,
  failureMessage: failureMessage,
  dialogBuilder: (context, content, actions) => PlatformDialogFrame(
    title: 'Delete administrator?',
    body: content,
    actions: actions,
  ),
);
