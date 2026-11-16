import 'package:flutter/material.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/core/time/business_time.dart';
import 'package:workaxis/core/time/calendar_date.dart';
import 'package:workaxis/core/time/clock.dart';
import 'package:workaxis/core/widgets/error_state.dart';
import 'package:workaxis/features/platform_organizations/domain/models/customer_organization.dart';
import 'package:workaxis/features/platform_organizations/domain/organization_license_rules.dart';
import 'package:workaxis/features/platform_organizations/presentation/controllers/organization_license_controller.dart';
import 'package:workaxis/features/platform_organizations/presentation/widgets/organization_details/license/license_empty_state.dart';
import 'package:workaxis/features/platform_organizations/presentation/widgets/organization_details/license/license_history_panel.dart';
import 'package:workaxis/features/platform_organizations/presentation/widgets/organization_details/license/license_plan_panel.dart';
import 'package:workaxis/features/platform_organizations/presentation/widgets/organization_details/license/license_summary_card.dart';
import 'package:workaxis/features/platform_organizations/presentation/widgets/organization_details/license/organization_license_action.dart';

/// License tab of the organization details: loading, error and empty states,
/// then the summary, plan entitlements and history.
///
/// Status is shown as the server derived it. Each license change is reported
/// through [onAction]; the screen opens its page. [now] only supplies the
/// business date for the contextual term line.
class OrganizationLicenseTab extends StatelessWidget {
  const OrganizationLicenseTab({
    super.key,
    required this.organization,
    required this.controller,
    required this.onAction,
    this.now = systemNow,
  });

  final CustomerOrganization organization;
  final OrganizationLicenseController controller;
  final ValueChanged<OrganizationLicenseAction> onAction;
  final Now now;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) => _buildFor(context),
  );

  Widget _buildFor(BuildContext context) {
    final id = organization.id;
    if (controller.isLoadingFor(id)) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.xl),
          child: CircularProgressIndicator(),
        ),
      );
    }
    final error = controller.errorFor(id);
    if (error != null) {
      return ErrorState(message: error, onRetry: () => controller.load(id));
    }
    final license = controller.licenseFor(id);
    if (license == null) {
      return OrganizationLicenseEmptyState(
        onAssignLicense: () => onAction(OrganizationLicenseAction.assign),
      );
    }
    final today = CalendarDate.of(BusinessTime.today(now));
    final canChangePlan = OrganizationLicenseRules.changeTargets(
      controller.activePlans,
      license.plan.level,
    ).isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LicenseSummaryCard(
          license: license,
          today: today,
          canChangePlan: canChangePlan,
          onChangePlan: () => onAction(OrganizationLicenseAction.changePlan),
          onModifyTerms: () =>
              onAction(OrganizationLicenseAction.commercialTerms),
          onRenew: () => onAction(OrganizationLicenseAction.renew),
        ),
        const SizedBox(height: AppSpacing.md),
        LicensePlanPanel(plan: license.plan),
        const SizedBox(height: AppSpacing.md),
        LicenseHistoryPanel(history: controller.historyFor(id)),
      ],
    );
  }
}
