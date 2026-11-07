import 'package:flutter/material.dart';
import 'package:workaxis/core/widgets/app_button.dart';
import 'package:workaxis/features/platform_organizations/domain/models/organization_admin_status.dart';
import 'package:workaxis/features/platform_organizations/domain/models/organization_admin_user.dart';
import 'package:workaxis/features/platform_organizations/presentation/controllers/platform_organizations_controller.dart';
import 'package:workaxis/features/platform_organizations/presentation/widgets/organization_details/organization_admin_dialog.dart';
import 'package:workaxis/features/platform_organizations/presentation/widgets/organization_details/organization_admin_password_dialog.dart';
import 'package:workaxis/features/platform_users/presentation/widgets/platform_dialog_frame.dart';

/// Runs the dialogs for one administrator action and reports the outcome.
///
/// All account changes go through [PlatformOrganizationsController]; this
/// class only sequences dialogs and snackbars.
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
    OrganizationAdminAction.restore => changeStatus(
      context,
      administrator,
      OrganizationAdminStatus.active,
    ),
  };

  Future<void> add(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    controller.clearActionError();
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => OrganizationAdminDialog(
        onSubmit: (draft) async {
          final ok = await controller.createAdministrator(
            organizationId,
            draft,
          );
          return ok ? null : _failure('The administrator could not be added.');
        },
      ),
    );
    if (saved == true) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Administrator added.')),
      );
    }
  }

  Future<void> edit(
    BuildContext context,
    OrganizationAdminUser administrator,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    controller.clearActionError();
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => OrganizationAdminDialog(
        existingAdministrator: administrator,
        onSubmit: (draft) async {
          final ok = await controller.updateAdministrator(
            organizationId,
            administrator.copyWith(
              name: draft.name,
              email: draft.email,
              phone: draft.phone,
            ),
          );
          return ok
              ? null
              : _failure('The administrator could not be updated.');
        },
      ),
    );
    if (saved == true) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Administrator details updated.')),
      );
    }
  }

  Future<void> resetPassword(
    BuildContext context,
    OrganizationAdminUser administrator,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    controller.clearActionError();
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => OrganizationAdminPasswordDialog(
        administrator: administrator,
        onSubmit: (password) async {
          final ok = await controller.resetAdministratorPassword(
            organizationId,
            administrator.id,
            password,
          );
          return ok ? null : _failure('The password could not be reset.');
        },
      ),
    );
    if (saved == true) {
      messenger.showSnackBar(
        SnackBar(content: Text('Password reset for ${administrator.name}.')),
      );
    }
  }

  Future<void> changeStatus(
    BuildContext context,
    OrganizationAdminUser administrator,
    OrganizationAdminStatus next,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    controller.clearActionError();
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
