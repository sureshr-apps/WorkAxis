import 'package:flutter/material.dart';
import 'package:workaxis/features/platform_users/domain/models/platform_administrator.dart';
import 'package:workaxis/features/platform_users/presentation/controllers/platform_users_controller.dart';
import 'package:workaxis/features/platform_users/presentation/widgets/platform_administrator_dialogs.dart';

/// Confirms, deletes [administrator] and reports the outcome. Returns true
/// only when the administrator was deleted.
Future<bool> confirmAndDeleteAdministrator(
  BuildContext context,
  PlatformUsersController controller,
  PlatformAdministrator administrator,
) async {
  final confirmed = await confirmAdministratorDelete(
    context,
    administrator: administrator,
  );
  if (!confirmed || !context.mounted) return false;
  controller.clearActionError();
  final messenger = ScaffoldMessenger.of(context);
  final deleted = await controller.deleteAdministrator(administrator.id);
  if (!deleted) {
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          controller.actionErrorMessage ??
              'The administrator could not be deleted. Try again.',
        ),
      ),
    );
    return false;
  }
  messenger.showSnackBar(
    SnackBar(content: Text('${administrator.fullName} deleted.')),
  );
  return true;
}
