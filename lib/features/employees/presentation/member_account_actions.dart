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
  final confirmed = await confirmMemberStatusChange(
    context,
    member: member,
    suspend: suspend,
  );
  if (!confirmed || !context.mounted) return null;
  final controller = context.read<OrganizationMembersController>()
    ..clearActionError();
  final saved = await controller.setMemberStatus(
    access: access,
    member: member,
    status: suspend ? AccountStatus.suspended : AccountStatus.active,
    activeBranchId: activeBranchId,
  );
  if (!context.mounted) return saved;
  showMemberMessage(
    context,
    saved == null
        ? controller.actionErrorMessage ??
              'The account status could not be changed. Try again.'
        : '${member.fullName} ${suspend ? 'suspended' : 'restored'}.',
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
  final password = await showResetMemberPasswordDialog(context, member: member);
  if (password == null || !context.mounted) return false;
  final controller = context.read<OrganizationMembersController>()
    ..clearActionError();
  final ok = await controller.resetMemberPassword(
    access: access,
    member: member,
    newPassword: password,
    activeBranchId: activeBranchId,
  );
  if (!context.mounted) return ok;
  showMemberMessage(
    context,
    ok
        ? 'Password reset for ${member.fullName}.'
        : controller.actionErrorMessage ??
              'The password could not be reset. Try again.',
  );
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
  final confirmed = await confirmMemberDelete(context, member: member);
  if (!confirmed || !context.mounted) return false;
  final controller = context.read<OrganizationMembersController>()
    ..clearActionError();
  final deleted = await controller.deleteMember(
    access: access,
    member: member,
    activeBranchId: activeBranchId,
  );
  if (!context.mounted) return deleted;
  showMemberMessage(
    context,
    deleted
        ? '${member.fullName} deleted.'
        : controller.actionErrorMessage ??
              'The account could not be deleted. Try again.',
  );
  return deleted;
}

void showMemberMessage(BuildContext context, String message) =>
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
