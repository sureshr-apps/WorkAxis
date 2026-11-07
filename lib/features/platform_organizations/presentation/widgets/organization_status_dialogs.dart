import 'package:flutter/material.dart';
import 'package:workaxis/features/platform_organizations/domain/models/customer_organization.dart';
import 'package:workaxis/features/platform_organizations/presentation/widgets/organization_status_change_dialog.dart';

export 'package:workaxis/features/platform_organizations/presentation/widgets/organization_status_change_dialog.dart';

/// Confirmation dialog for suspending an organization.
class SuspendOrganizationDialog extends StatelessWidget {
  const SuspendOrganizationDialog({
    super.key,
    required this.organization,
    required this.onConfirm,
    this.failureMessage,
  });

  final CustomerOrganization organization;
  final Future<bool> Function() onConfirm;
  final String? Function()? failureMessage;

  @override
  Widget build(BuildContext context) => OrganizationStatusChangeDialog(
    organization: organization,
    change: OrganizationStatusChange.suspend,
    onConfirm: onConfirm,
    failureMessage: failureMessage,
  );
}

/// Confirmation dialog for reactivating an organization.
class ReactivateOrganizationDialog extends StatelessWidget {
  const ReactivateOrganizationDialog({
    super.key,
    required this.organization,
    required this.onConfirm,
    this.failureMessage,
  });

  final CustomerOrganization organization;
  final Future<bool> Function() onConfirm;
  final String? Function()? failureMessage;

  @override
  Widget build(BuildContext context) => OrganizationStatusChangeDialog(
    organization: organization,
    change: OrganizationStatusChange.reactivate,
    onConfirm: onConfirm,
    failureMessage: failureMessage,
  );
}
