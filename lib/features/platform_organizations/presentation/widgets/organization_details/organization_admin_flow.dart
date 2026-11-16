import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:workaxis/app/routing/app_routes.dart';
import 'package:workaxis/core/widgets/app_button.dart';
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
    final confirmed = await _confirmDelete(context, administrator);
    if (!confirmed) return;
    final ok = await controller.deleteAdministrator(
      organizationId,
      administrator.id,
    );
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? '${administrator.name} deleted.'
              : _failure('The administrator could not be deleted.'),
        ),
      ),
    );
  }

  Future<bool> _confirmDelete(
    BuildContext context,
    OrganizationAdminUser administrator,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => PlatformDialogFrame(
        title: 'Delete administrator?',
        body: Text(
          '${administrator.name} will be removed from this organization and '
          'can no longer sign in. This cannot be undone.',
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
    final confirmed = await _confirm(context, administrator, next);
    if (!confirmed) return;
    final ok = await controller.setAdministratorStatus(
      organizationId,
      administrator.id,
      next,
    );
    final suspended = next == OrganizationAdminStatus.suspended;
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? '${administrator.name} ${suspended ? 'suspended' : 'restored'}.'
              : _failure(
                  'The administrator could not be '
                  '${suspended ? 'suspended' : 'restored'}.',
                ),
        ),
      ),
    );
  }

  String _failure(String fallback) => controller.actionErrorMessage ?? fallback;

  Future<bool> _confirm(
    BuildContext context,
    OrganizationAdminUser administrator,
    OrganizationAdminStatus next,
  ) async {
    final suspend = next == OrganizationAdminStatus.suspended;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => PlatformDialogFrame(
        title: suspend ? 'Suspend administrator?' : 'Restore administrator?',
        body: Text(
          suspend
              ? '${administrator.name} will no longer be able to sign in. '
                    'You can restore access later.'
              : 'Allow ${administrator.name} to sign in to WorkAxis again?',
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
            text: suspend ? 'Suspend' : 'Restore',
            isFullWidth: false,
            onPressed: () => Navigator.of(dialogContext).pop(true),
          ),
        ],
      ),
    );
    return confirmed == true;
  }
}
