import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:workaxis/app/routing/app_routes.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/core/responsive/responsive_layout.dart';
import 'package:workaxis/core/widgets/app_button.dart';
import 'package:workaxis/core/widgets/empty_state.dart';
import 'package:workaxis/core/widgets/error_banner.dart';
import 'package:workaxis/core/widgets/error_state.dart';
import 'package:workaxis/features/platform_organizations/domain/models/customer_organization.dart';
import 'package:workaxis/features/platform_organizations/domain/models/organization_status.dart';
import 'package:workaxis/features/platform_organizations/presentation/controllers/platform_organizations_controller.dart';
import 'package:workaxis/features/platform_organizations/presentation/widgets/organization_details/organization_admin_flow.dart';
import 'package:workaxis/features/platform_organizations/presentation/widgets/organization_details/organization_administrators_tab.dart';
import 'package:workaxis/features/platform_organizations/presentation/widgets/organization_details/organization_details_header.dart';
import 'package:workaxis/features/platform_organizations/presentation/widgets/organization_details/organization_details_tab_bar.dart';
import 'package:workaxis/features/platform_organizations/presentation/widgets/organization_details/organization_license_tab.dart';
import 'package:workaxis/features/platform_organizations/presentation/widgets/organization_details/organization_overview_tab.dart';
import 'package:workaxis/features/platform_organizations/presentation/widgets/organization_status_dialogs.dart';

/// Platform organization master record with overview, administrators and
/// license tabs.
class OrganizationDetailsScreen extends StatefulWidget {
  const OrganizationDetailsScreen({super.key, required this.organizationId});

  final String organizationId;

  @override
  State<OrganizationDetailsScreen> createState() =>
      _OrganizationDetailsScreenState();
}

class _OrganizationDetailsScreenState extends State<OrganizationDetailsScreen> {
  OrganizationDetailsTab _selectedTab = OrganizationDetailsTab.overview;

  /// False until this screen has asked the controller for its organization,
  /// so a previously selected organization is never shown on the first frame.
  bool _loadRequested = false;

  @override
  void initState() {
    super.initState();
    _loadOrganization();
  }

  @override
  void didUpdateWidget(covariant OrganizationDetailsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.organizationId != widget.organizationId) {
      _selectedTab = OrganizationDetailsTab.overview;
      _loadOrganization();
    }
  }

  void _loadOrganization() {
    _loadRequested = false;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final controller = context.read<PlatformOrganizationsController>();
      controller.clearActionError();
      setState(() => _loadRequested = true);
      controller.loadOrganizationDetails(widget.organizationId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PlatformOrganizationsController>();
    final selected = controller.selectedOrganization;
    final organization = selected?.id == widget.organizationId
        ? selected
        : null;

    if (organization == null) {
      final waiting = !_loadRequested || controller.isDetailLoading;
      if (waiting && controller.detailErrorMessage == null) {
        return const Scaffold(
          backgroundColor: AppColors.surface,
          body: Center(child: CircularProgressIndicator()),
        );
      }
      return _NotFound(
        errorMessage: controller.detailErrorMessage,
        onRetry: () =>
            controller.loadOrganizationDetails(widget.organizationId),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          child: ResponsivePageContent(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                OrganizationDetailsBreadcrumb(
                  organization: organization,
                  onBack: () => context.go(AppRoutes.platformOrganizations),
                ),
                const SizedBox(height: AppSpacing.md),
                OrganizationDetailsHeader(
                  organization: organization,
                  planName: controller.selectedLicenseDetails?.planName,
                  isActionLoading: controller.isActionLoading,
                  onEdit: () {
                    controller.clearActionError();
                    context.push(
                      AppRoutes.platformOrganizationEditPath(organization.id),
                    );
                  },
                  onToggleStatus: () => organization.isActive
                      ? _confirmSuspend(organization, controller)
                      : _confirmReactivate(organization, controller),
                  onCopyCode: () => _copyOrganizationCode(organization.code),
                ),
                const SizedBox(height: AppSpacing.md),
                OrganizationDetailsTabBar(
                  selected: _selectedTab,
                  administratorCount: organization.admins.length,
                  onChanged: (tab) => setState(() => _selectedTab = tab),
                ),
                const SizedBox(height: AppSpacing.md),
                _buildSelectedTab(organization, controller),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedTab(
    CustomerOrganization organization,
    PlatformOrganizationsController controller,
  ) {
    switch (_selectedTab) {
      case OrganizationDetailsTab.overview:
        return OrganizationOverviewTab(
          organization: organization,
          license: controller.selectedLicenseDetails,
          onUpload: _showUnavailable,
        );
      case OrganizationDetailsTab.administrators:
        final flow = OrganizationAdminFlow(
          controller: controller,
          organizationId: organization.id,
        );
        return OrganizationAdministratorsTab(
          organizationName: organization.name,
          administrators: organization.admins,
          enabled: !controller.isActionLoading,
          canSuspend: (admin) =>
              !controller.isLastActiveAdministrator(admin.id),
          onAddAdministrator: () => flow.add(context),
          onAdministratorAction: (admin, action) =>
              flow.dispatch(context, admin, action),
        );
      case OrganizationDetailsTab.license:
        final license = controller.selectedLicenseDetails;
        if (controller.isDetailLoading) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.xl),
              child: CircularProgressIndicator(),
            ),
          );
        }
        if (controller.detailErrorMessage != null) {
          return ErrorBanner(
            message: controller.detailErrorMessage!,
            onRetry: () => controller.loadOrganizationDetails(organization.id),
          );
        }
        if (license == null) {
          return OrganizationLicenseEmptyState(
            onAssignLicense: () => _showUnavailable('Assign License'),
          );
        }
        return OrganizationLicenseTab(
          license: license,
          onAction: _showUnavailable,
        );
    }
  }

  Future<void> _copyOrganizationCode(String code) async {
    final messenger = ScaffoldMessenger.of(context);
    await Clipboard.setData(ClipboardData(text: code));
    messenger.showSnackBar(
      const SnackBar(content: Text('Organization code copied')),
    );
  }

  void _showUnavailable(String action) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('$action is not available yet.')));
  }

  void _confirmSuspend(
    CustomerOrganization organization,
    PlatformOrganizationsController controller,
  ) {
    controller.clearActionError();
    final messenger = ScaffoldMessenger.of(context);
    showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => SuspendOrganizationDialog(
        organization: organization,
        failureMessage: () => controller.actionErrorMessage,
        onConfirm: () async {
          final ok = await controller.updateStatus(
            organization.id,
            OrganizationStatus.suspended,
          );
          if (ok) {
            messenger.showSnackBar(
              SnackBar(
                content: Text('${organization.name} marked as Suspended.'),
                backgroundColor: AppColors.statusUrgent,
              ),
            );
          }
          return ok;
        },
      ),
    );
  }

  void _confirmReactivate(
    CustomerOrganization organization,
    PlatformOrganizationsController controller,
  ) {
    controller.clearActionError();
    final messenger = ScaffoldMessenger.of(context);
    showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ReactivateOrganizationDialog(
        organization: organization,
        failureMessage: () => controller.actionErrorMessage,
        onConfirm: () async {
          final ok = await controller.updateStatus(
            organization.id,
            OrganizationStatus.active,
          );
          if (ok) {
            messenger.showSnackBar(
              SnackBar(
                content: Text('${organization.name} successfully reactivated.'),
                backgroundColor: AppColors.statusActive,
              ),
            );
          }
          return ok;
        },
      ),
    );
  }
}

class _NotFound extends StatelessWidget {
  const _NotFound({required this.errorMessage, required this.onRetry});

  final String? errorMessage;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final backButton = AppButton.secondary(
      text: 'Back to Organizations',
      onPressed: () => context.go(AppRoutes.platformOrganizations),
      isFullWidth: false,
    );
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: errorMessage != null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ErrorState(message: errorMessage!, onRetry: onRetry),
                  backButton,
                ],
              )
            : EmptyState(
                icon: Icons.business_outlined,
                title: 'Organization not found',
                action: backButton,
              ),
      ),
    );
  }
}
