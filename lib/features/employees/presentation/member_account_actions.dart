import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/authentication/domain/models/account_status.dart';
import 'package:workaxis/features/employees/domain/models/organization_member.dart';
import 'package:workaxis/features/employees/presentation/controllers/organization_members_controller.dart';
import 'package:workaxis/features/employees/presentation/widgets/member_action_dialogs.dart';

/// Account actions for an employee or branch manager, shared by the directory
/// and the details page. Each one confirms first where needed and reports the
/// outcome in a message.

/// Suspends or restores [member]. Returns the saved account, or null when the
/// change was cancelled or failed.
Future<OrganizationMember?> toggleMemberStatus(
  BuildContext context, {
  required UserAccessContext access,
  required OrganizationMember member,
  String? activeBranchId,
}) async {
  final suspend = member.status == AccountStatus.active;
  final controller = context.read<OrganizationMembersController>()
    ..clearActionError();
  OrganizationMember? saved;
  final confirmed = await confirmMemberStatusChange(
    context,
    member: member,
    suspend: suspend,
    onConfirm: () async {
      controller.clearActionError();
      saved = await controller.setMemberStatus(
        access: access,
        member: member,
        status: suspend ? AccountStatus.suspended : AccountStatus.active,
        activeBranchId: activeBranchId,
      );
      return saved != null;
    },
    failureMessage: () => controller.actionErrorMessage,
  );
  if (!confirmed || !context.mounted) return null;
  showMemberMessage(
    context,
    '${member.fullName} ${suspend ? 'suspended' : 'restored'}.',
  );
  return saved;
}

/// Asks for a new password and sets it. Returns whether the password changed.
Future<bool> resetMemberPassword(
  BuildContext context, {
  required UserAccessContext access,
  required OrganizationMember member,
  String? activeBranchId,
}) async {
  final controller = context.read<OrganizationMembersController>()
    ..clearActionError();
  final ok = await showResetMemberPasswordDialog(
    context,
    member: member,
    onSubmit: (password) async {
      controller.clearActionError();
      return controller.resetMemberPassword(
        access: access,
        member: member,
        newPassword: password,
        activeBranchId: activeBranchId,
      );
    },
    failureMessage: () => controller.actionErrorMessage,
  );
  if (!context.mounted) return ok;
  if (ok) showMemberMessage(context, 'Password reset for ${member.fullName}.');
  return ok;
}

/// Permanently deletes [member] after confirmation. Returns whether it was
/// deleted.
Future<bool> deleteMember(
  BuildContext context, {
  required UserAccessContext access,
  required OrganizationMember member,
  String? activeBranchId,
}) async {
  final controller = context.read<OrganizationMembersController>()
    ..clearActionError();
  final deleted = await confirmMemberDelete(
    context,
    member: member,
    onConfirm: () async {
      controller.clearActionError();
      return controller.deleteMember(
        access: access,
        member: member,
        activeBranchId: activeBranchId,
      );
    },
    failureMessage: () => controller.actionErrorMessage,
  );
  if (!context.mounted) return deleted;
  if (deleted) showMemberMessage(context, '${member.fullName} deleted.');
  return deleted;
}

void showMemberMessage(BuildContext context, String message) =>
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
