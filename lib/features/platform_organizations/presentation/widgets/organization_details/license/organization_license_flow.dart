import 'package:flutter/material.dart';
import 'package:workaxis/core/time/business_time.dart';
import 'package:workaxis/core/time/calendar_date.dart';
import 'package:workaxis/core/time/clock.dart';
import 'package:workaxis/features/platform_organizations/domain/models/organization_license.dart';
import 'package:workaxis/features/platform_organizations/presentation/controllers/organization_license_controller.dart';
import 'package:workaxis/features/platform_organizations/presentation/widgets/organization_details/license/dialogs/assign_license_dialog.dart';
import 'package:workaxis/features/platform_organizations/presentation/widgets/organization_details/license/dialogs/change_plan_dialog.dart';
import 'package:workaxis/features/platform_organizations/presentation/widgets/organization_details/license/dialogs/modify_commercial_terms_dialog.dart';
import 'package:workaxis/features/platform_organizations/presentation/widgets/organization_details/license/dialogs/renew_license_dialog.dart';

/// Opens the license action dialogs and reports their outcome. Each dialog
/// saves through [OrganizationLicenseController]; this class only sequences
/// dialogs and snackbars, as the administrator flow does.
class OrganizationLicenseFlow {
  OrganizationLicenseFlow({
    required this.controller,
    required this.organizationName,
    required this.now,
  });

  final OrganizationLicenseController controller;
  final String organizationName;

  /// Source of the business date used for default dates.
  final Now now;

  Future<void> assign(BuildContext context) {
    final today = CalendarDate.of(BusinessTime.today(now));
    return _open(
      context,
      successMessage: 'License successfully assigned to organization.',
      build: () => AssignLicenseDialog(
        organizationName: organizationName,
        activePlans: controller.activePlans,
        today: today,
        onSubmit: controller.assignLicense,
      ),
    );
  }

  Future<void> changePlan(BuildContext context, OrganizationLicense license) =>
      _open(
        context,
        successMessage: 'Plan upgraded successfully.',
        build: () => ChangePlanDialog(
          organizationName: organizationName,
          license: license,
          activePlans: controller.activePlans,
          onSubmit: controller.changePlan,
        ),
      );

  Future<void> modifyCommercialTerms(
    BuildContext context,
    OrganizationLicense license,
  ) => _open(
    context,
    successMessage: 'Commercial terms updated successfully.',
    build: () => ModifyCommercialTermsDialog(
      organizationName: organizationName,
      license: license,
      onSubmit: controller.modifyCommercialTerms,
    ),
  );

  Future<void> renew(BuildContext context, OrganizationLicense license) =>
      _open(
        context,
        successMessage: 'License renewed successfully.',
        build: () => RenewLicenseDialog(
          organizationName: organizationName,
          license: license,
          activePlans: controller.activePlans,
          onSubmit: controller.renewLicense,
        ),
      );

  Future<void> _open(
    BuildContext context, {
    required String successMessage,
    required Widget Function() build,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => build(),
    );
    if (saved == true) {
      messenger.showSnackBar(SnackBar(content: Text(successMessage)));
    }
  }
}
