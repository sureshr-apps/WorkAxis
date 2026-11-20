import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:workaxis/app/routing/app_routes.dart';
import 'package:workaxis/core/widgets/async_confirmation_dialog.dart';
import 'package:workaxis/features/platform_organizations/domain/models/organization_admin_status.dart';
import 'package:workaxis/features/platform_organizations/domain/organization_admin_rules.dart';
import 'package:workaxis/features/platform_organizations/domain/models/organization_admin_user.dart';
import 'package:workaxis/features/platform_organizations/presentation/controllers/platform_organizations_controller.dart';
import 'package:workaxis/features/platform_users/presentation/widgets/platform_dialog_frame.dart';

/// Routes one administrator action to its page or confirmation.
///
/// Add, edit and password reset open their own pages, which save through the
/// route loaders. Suspend and restore confirm in a dialog, then change the
/// status through [PlatformOrganizationsController].
class OrganizationAdminFlow {
  OrganizationAdminFlow({
    required this.controller,
    required this.organizationId,
  });

  final PlatformOrganizationsController controller;
  final String organizationId;

  Future<void> dispatch(
    BuildContext context,
    OrganizationAdminUser administrator,
    OrganizationAdminAction action,
  ) => switch (action) {
    OrganizationAdminAction.edit => edit(context, administrator),
    OrganizationAdminAction.resetPassword => resetPassword(
      context,
      administrator,
    ),
    OrganizationAdminAction.suspend => changeStatus(
      context,
      administrator,
      OrganizationAdminStatus.suspended,
    ),
    OrganizationAdminAction.delete => delete(context, administrator),
    OrganizationAdminAction.restore => changeStatus(
      context,
      administrator,
      OrganizationAdminStatus.active,
    ),
  };

  Future<void> add(BuildContext context) => _open(
    context,
    AppRoutes.platformOrganizationAdminAddPath(organizationId),
  );

  Future<void> edit(
    BuildContext context,
    OrganizationAdminUser administrator,
  ) => _open(
    context,
    AppRoutes.platformOrganizationAdminEditPath(
      organizationId,
      administrator.id,
    ),
  );

  Future<void> resetPassword(
    BuildContext context,
    OrganizationAdminUser administrator,
  ) => _open(
    context,
    AppRoutes.platformOrganizationAdminPasswordPath(
      organizationId,
      administrator.id,
    ),
  );

  Future<void> delete(
    BuildContext context,
    OrganizationAdminUser administrator,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    controller.clearActionError();
    if (controller.isLastActiveAdministrator(administrator.id)) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(OrganizationAdminRules.lastActiveAdminMessage),
          duration: const Duration(seconds: 6),
        ),
      );
      return;
    }
    final deleted = await _confirmDelete(
      context,
      administrator,
      onConfirm: () async {
        controller.clearActionError();
        return await controller.deleteAdministrator(
          organizationId,
          administrator.id,
        );
      },
    );
    if (!deleted || !context.mounted) return;
    messenger.showSnackBar(
      SnackBar(content: Text('${administrator.name} deleted.')),
    );
  }

  Future<bool> _confirmDelete(
    BuildContext context,
    OrganizationAdminUser administrator, {
    required Future<bool> Function() onConfirm,
  }) => showAsyncConfirmationDialog(
    context: context,
    title: 'Delete administrator?',
    content: Text(
      '${administrator.name} will be removed from this organization and '
      'can no longer sign in. This cannot be undone.',
    ),
    confirmLabel: 'Delete administrator',
    destructive: true,
    onConfirm: onConfirm,
    failureMessage: () => controller.actionErrorMessage,
    dialogBuilder: (context, content, actions) => PlatformDialogFrame(
      title: 'Delete administrator?',
      body: content,
      actions: actions,
    ),
  );

  Future<void> _open(BuildContext context, String location) async {
    await context.push<void>(location);
  }

  Future<void> changeStatus(
    BuildContext context,
    OrganizationAdminUser administrator,
    OrganizationAdminStatus next,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    controller.clearActionError();
    // Explain the refusal before asking for confirmation, so the user is not
    // asked to confirm a change that cannot happen.
    if (next == OrganizationAdminStatus.suspended &&
        controller.isLastActiveAdministrator(administrator.id)) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(OrganizationAdminRules.lastActiveAdminMessage),
          duration: const Duration(seconds: 6),
        ),
      );
      return;
    }
    final confirmed = await _confirm(
      context,
      administrator,
      next,
      onConfirm: () async {
        controller.clearActionError();
        return await controller.setAdministratorStatus(
          organizationId,
          administrator.id,
          next,
        );
      },
    );
    if (!confirmed || !context.mounted) return;
    final suspended = next == OrganizationAdminStatus.suspended;
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          '${administrator.name} ${suspended ? 'suspended' : 'restored'}.',
        ),
      ),
    );
  }

  Future<bool> _confirm(
    BuildContext context,
    OrganizationAdminUser administrator,
    OrganizationAdminStatus next, {
    required Future<bool> Function() onConfirm,
  }) {
    final suspend = next == OrganizationAdminStatus.suspended;
    final title = suspend ? 'Suspend administrator?' : 'Restore administrator?';
    return showAsyncConfirmationDialog(
      context: context,
      title: title,
      content: Text(
        suspend
            ? '${administrator.name} will no longer be able to sign in. '
                  'You can restore access later.'
            : 'Allow ${administrator.name} to sign in to WorkAxis again?',
      ),
      confirmLabel: suspend ? 'Suspend' : 'Restore',
      destructive: suspend,
      onConfirm: onConfirm,
      failureMessage: () => controller.actionErrorMessage,
      dialogBuilder: (context, content, actions) =>
          PlatformDialogFrame(title: title, body: content, actions: actions),
    );
  }
}
