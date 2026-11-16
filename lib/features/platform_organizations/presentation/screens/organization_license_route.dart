import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:workaxis/app/routing/app_routes.dart';
import 'package:workaxis/core/time/business_time.dart';
import 'package:workaxis/core/time/calendar_date.dart';
import 'package:workaxis/core/time/clock.dart';
import 'package:workaxis/core/widgets/record_not_found_page.dart';
import 'package:workaxis/features/platform_organizations/domain/models/customer_organization.dart';
import 'package:workaxis/features/platform_organizations/domain/models/organization_license.dart';
import 'package:workaxis/features/platform_organizations/presentation/controllers/organization_license_controller.dart';
import 'package:workaxis/features/platform_organizations/presentation/controllers/platform_organizations_controller.dart';
import 'package:workaxis/features/platform_organizations/presentation/widgets/organization_details/license/organization_license_action.dart';
import 'package:workaxis/features/platform_organizations/presentation/widgets/organization_details/license/pages/assign_license_page.dart';
import 'package:workaxis/features/platform_organizations/presentation/widgets/organization_details/license/pages/change_plan_page.dart';
import 'package:workaxis/features/platform_organizations/presentation/widgets/organization_details/license/pages/modify_commercial_terms_page.dart';
import 'package:workaxis/features/platform_organizations/presentation/widgets/organization_details/license/pages/renew_license_page.dart';

/// Routed entry for one license action on an organization: assign, change
/// plan, modify commercial terms or renew. It loads the license, picks the
/// page for [action], and on success shows the outcome and returns to the
/// organization. Saves go through [OrganizationLicenseController].
class OrganizationLicenseRoute extends StatefulWidget {
  const OrganizationLicenseRoute({
    super.key,
    required this.organizationId,
    required this.action,
  });

  final String organizationId;

  /// One of `assign`, `change-plan`, `commercial-terms` or `renew`.
  final String action;

  @override
  State<OrganizationLicenseRoute> createState() =>
      _OrganizationLicenseRouteState();
}

class _OrganizationLicenseRouteState extends State<OrganizationLicenseRoute> {
  CustomerOrganization? _organization;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  /// Loads the organization when it is not already selected, then the license
  /// and active plans. The organization load also starts a license load; the
  /// explicit one here supersedes it, so the page never reads a stale license.
  Future<void> _load() async {
    setState(() => _loading = true);
    final organizations = context.read<PlatformOrganizationsController>();
    final selected = organizations.selectedOrganization;
    final organization = selected?.id == widget.organizationId
        ? selected
        : await organizations.loadOrganizationDetails(widget.organizationId);
    if (organization != null) {
      await organizations.license.load(organization.id);
    }
    if (!mounted) return;
    setState(() {
      _organization = organization;
      _loading = false;
    });
  }

  void _leave() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(
        AppRoutes.platformOrganizationDetailsPath(widget.organizationId),
      );
    }
  }

  void _saved(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
    _leave();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final organization = _organization;
    final action = OrganizationLicenseAction.fromRouteSegment(widget.action);
    final license = context.watch<PlatformOrganizationsController>().license;
    if (organization == null || action == null) {
      return _notFound(
        message: organization == null
            ? 'This organization could not be found.'
            : 'This license action could not be found.',
      );
    }
    final loadError = license.errorFor(organization.id);
    if (loadError != null) return _notFound(message: loadError);

    if (action == OrganizationLicenseAction.assign) {
      return _assignPage(organization, license);
    }
    final current = license.licenseFor(organization.id);
    if (current == null) {
      return _notFound(message: 'This organization has no license to change.');
    }
    return switch (action) {
      OrganizationLicenseAction.assign => _assignPage(organization, license),
      OrganizationLicenseAction.changePlan => _changePlanPage(
        organization,
        license,
        current,
      ),
      OrganizationLicenseAction.commercialTerms => _commercialTermsPage(
        organization,
        license,
        current,
      ),
      OrganizationLicenseAction.renew => _renewPage(
        organization,
        license,
        current,
      ),
    };
  }

  RecordNotFoundPage _notFound({required String message}) => RecordNotFoundPage(
    backLabel: _organization?.name ?? 'Organizations',
    currentLabel: 'License',
    onBack: _leave,
    message: message,
    onRetry: _load,
  );

  Widget _assignPage(
    CustomerOrganization organization,
    OrganizationLicenseController license,
  ) => AssignLicensePage(
    organizationName: organization.name,
    activePlans: license.activePlans,
    today: CalendarDate.of(BusinessTime.today(systemNow)),
    onSubmit: license.assignLicense,
    onClose: _leave,
    onSaved: () => _saved('License successfully assigned to organization.'),
  );

  Widget _changePlanPage(
    CustomerOrganization organization,
    OrganizationLicenseController license,
    OrganizationLicense current,
  ) => ChangePlanPage(
    organizationName: organization.name,
    license: current,
    activePlans: license.activePlans,
    onSubmit: license.changePlan,
    onClose: _leave,
    onSaved: () => _saved('Plan upgraded successfully.'),
  );

  Widget _commercialTermsPage(
    CustomerOrganization organization,
    OrganizationLicenseController license,
    OrganizationLicense current,
  ) => ModifyCommercialTermsPage(
    organizationName: organization.name,
    license: current,
    onSubmit: license.modifyCommercialTerms,
    onClose: _leave,
    onSaved: () => _saved('Commercial terms updated successfully.'),
  );

  Widget _renewPage(
    CustomerOrganization organization,
    OrganizationLicenseController license,
    OrganizationLicense current,
  ) => RenewLicensePage(
    organizationName: organization.name,
    license: current,
    activePlans: license.activePlans,
    onSubmit: license.renewLicense,
    onClose: _leave,
    onSaved: () => _saved('License renewed successfully.'),
  );
}
