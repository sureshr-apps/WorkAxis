import 'package:flutter/material.dart';
import 'package:workaxis/core/widgets/app_button.dart';
import 'package:workaxis/features/authentication/domain/models/account_status.dart';
import 'package:workaxis/features/platform_users/domain/models/platform_administrator.dart';
import 'package:workaxis/features/platform_users/presentation/widgets/platform_dialog_frame.dart';

/// Asks the user to confirm suspending or restoring [administrator]'s access.
/// Resolves to true only when the user confirms.
Future<bool> confirmAdministratorStatusChange(
  BuildContext context, {
  required PlatformAdministrator administrator,
  required AccountStatus nextStatus,
}) async {
  final suspend = nextStatus == AccountStatus.suspended;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => PlatformDialogFrame(
      title: suspend ? 'Suspend access?' : 'Restore access?',
      body: Text(
        suspend
            ? '${administrator.fullName} will no longer be able to sign in. '
                  'You can restore access later.'
            : 'Allow ${administrator.fullName} to sign in to WorkAxis again?',
      ),
      actions: [
        AppButton.outlined(
          text: 'Cancel',
          isFullWidth: false,
          onPressed: () => Navigator.of(dialogContext).pop(false),
        ),
        AppButton(
          variant: suspend
              ? AppButtonVariant.destructive
              : AppButtonVariant.primary,
          text: suspend ? 'Suspend access' : 'Restore access',
          isFullWidth: false,
          onPressed: () => Navigator.of(dialogContext).pop(true),
        ),
      ],
    ),
  );
  return confirmed == true;
}

/// Asks the user to confirm permanently deleting [administrator]. Resolves to
/// true only when the user confirms.
Future<bool> confirmAdministratorDelete(
  BuildContext context, {
  required PlatformAdministrator administrator,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => PlatformDialogFrame(
      title: 'Delete administrator?',
      body: Text(
        '${administrator.fullName} will be removed from WorkAxis and can no '
        'longer sign in. This cannot be undone.',
      ),
      actions: [
        AppButton.outlined(
          text: 'Cancel',
          isFullWidth: false,
          onPressed: () => Navigator.of(dialogContext).pop(false),
        ),
        AppButton(
          variant: AppButtonVariant.destructive,
          text: 'Delete administrator',
          isFullWidth: false,
          onPressed: () => Navigator.of(dialogContext).pop(true),
        ),
      ],
    ),
  );
  return confirmed == true;
}
