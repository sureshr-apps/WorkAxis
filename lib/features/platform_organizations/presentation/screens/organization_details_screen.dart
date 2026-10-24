import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:workaxis/app/routing/app_routes.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/core/responsive/responsive_layout.dart';
import 'package:workaxis/core/widgets/app_button.dart';
import 'package:workaxis/core/widgets/error_banner.dart';
import 'package:workaxis/core/widgets/status_chip.dart';
import 'package:workaxis/features/platform_organizations/domain/models/customer_organization.dart';
import 'package:workaxis/features/platform_organizations/domain/models/organization_admin_user.dart';
import 'package:workaxis/features/platform_organizations/domain/models/organization_status.dart';
import 'package:workaxis/features/platform_organizations/presentation/controllers/platform_organizations_controller.dart';
import 'package:workaxis/features/platform_organizations/presentation/widgets/organization_details/organization_admin_dialog.dart';
import 'package:workaxis/features/platform_organizations/presentation/widgets/organization_details/organization_administrators_tab.dart';
import 'package:workaxis/features/platform_organizations/presentation/widgets/organization_details/organization_license_tab.dart';
import 'package:workaxis/features/platform_organizations/presentation/widgets/organization_details/organization_overview_tab.dart';
import 'package:workaxis/features/platform_organizations/presentation/widgets/organization_status_dialogs.dart';

enum _OrganizationDetailsTab { overview, administrators, license }

/// Platform organization master record with overview, administrators and license tabs.
class OrganizationDetailsScreen extends StatefulWidget {
  const OrganizationDetailsScreen({super.key, required this.organizationId});

  final String organizationId;

  @override
  State<OrganizationDetailsScreen> createState() =>
      _OrganizationDetailsScreenState();
}

class _OrganizationDetailsScreenState extends State<OrganizationDetailsScreen> {
  _OrganizationDetailsTab _selectedTab = _OrganizationDetailsTab.overview;

  @override
  void initState() {
    super.initState();
    _loadOrganization();
  }

  @override
  void didUpdateWidget(covariant OrganizationDetailsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.organizationId != widget.organizationId) {
      _selectedTab = _OrganizationDetailsTab.overview;
      _loadOrganization();
    }
  }

  void _loadOrganization() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<PlatformOrganizationsController>().loadOrganizationDetails(
        widget.organizationId,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PlatformOrganizationsController>();
    final organization = controller.selectedOrganization;

    if (controller.isLoading && organization == null) {
      return const Scaffold(
        backgroundColor: AppColors.surface,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (organization == null) {
      return _buildNotFound(context, controller.errorMessage);
    }

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          child: ResponsivePageContent(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildBreadcrumb(context, organization),
                const SizedBox(height: AppSpacing.md),
                _buildOrganizationHeader(context, organization, controller),
                const SizedBox(height: AppSpacing.md),
                _buildTabBar(organization),
                const SizedBox(height: AppSpacing.md),
                _buildSelectedTab(context, organization, controller),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotFound(BuildContext context, String? errorMessage) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.business_outlined,
                  size: 48,
                  color: AppColors.secondary,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  errorMessage ?? 'Organization not found',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                AppButton.secondary(
                  text: 'Back to Organizations',
                  onPressed: () => context.go(AppRoutes.platformOrganizations),
                  isFullWidth: false,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBreadcrumb(
    BuildContext context,
    CustomerOrganization organization,
  ) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.xs,
      children: [
        InkWell(
          onTap: () => context.go(AppRoutes.platformOrganizations),
          borderRadius: AppSpacing.roundedXs,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.arrow_back,
                  size: 15,
                  color: AppColors.secondary,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  'Organizations',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.secondary,
                  ),
                ),
              ],
            ),
          ),
        ),
        const Icon(
          Icons.chevron_right,
          size: 14,
          color: AppColors.outlineVariant,
        ),
        Text(
          organization.name,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.onSurface,
          ),
        ),
        _CodeBadge(code: organization.code, compact: true),
      ],
    );
  }

  Widget _buildOrganizationHeader(
    BuildContext context,
    CustomerOrganization organization,
    PlatformOrganizationsController controller,
  ) {
    final headerContent = Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 56,
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.tertiaryContainer.withValues(alpha: 0.1),
            border: Border.all(
              color: AppColors.tertiaryContainer.withValues(alpha: 0.25),
            ),
            borderRadius: AppSpacing.roundedSm,
          ),
          child: Text(
            organization.initials,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.tertiary,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                children: [
                  Text(
                    organization.name,
                    style: GoogleFonts.inter(
                      fontSize: context.isCompact ? 20 : 21,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                    ),
                  ),
                  _CodeBadge(
                    code: organization.code,
                    onCopy: () =>
                        _copyOrganizationCode(context, organization.code),
                  ),
                  StatusChip(
                    label: organization.status.displayName.toUpperCase(),
                    type: organization.isActive
                        ? StatusType.active
                        : StatusType.urgent,
                    width: 96,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.xs,
                children: [
                  _HeaderMetadata(
                    icon: Icons.calendar_today_outlined,
                    label:
                        'Created ${DateFormat('yyyy-MM-dd').format(organization.createdAt)}',
                  ),
                  const Text(
                    '•',
                    style: TextStyle(color: AppColors.outlineVariant),
                  ),
                  _HeaderMetadata(
                    label:
                        'Tier: ${controller.selectedLicenseDetails?.planName ?? 'Unassigned'}',
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );

    final actions = _buildHeaderActions(context, organization, controller);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 980;
        return _HeaderPanel(
          child: isWide
              ? Row(
                  children: [
                    Expanded(child: headerContent),
                    const SizedBox(width: AppSpacing.md),
                    actions,
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    headerContent,
                    const SizedBox(height: AppSpacing.md),
                    actions,
                  ],
                ),
        );
      },
    );
  }

  Widget _buildHeaderActions(
    BuildContext context,
    CustomerOrganization organization,
    PlatformOrganizationsController controller,
  ) {
    final isMobileOrTablet = MediaQuery.sizeOf(context).width < 980;

    final editButton = AppButton.outlined(
      text: 'Edit Organization',
      iconData: Icons.edit_outlined,
      onPressed: () =>
          context.push(AppRoutes.platformOrganizationEditPath(organization.id)),
      isFullWidth: isMobileOrTablet,
    );
    final statusButton = OutlinedButton.icon(
      onPressed: controller.isActionLoading
          ? null
          : () => organization.isActive
                ? _confirmSuspend(context, organization, controller)
                : _confirmReactivate(context, organization, controller),
      icon: Icon(
        organization.isActive ? Icons.power_settings_new : Icons.refresh,
        size: 16,
      ),
      label: Text(
        organization.isActive ? 'Suspend' : 'Reactivate',
        overflow: TextOverflow.ellipsis,
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: organization.isActive
            ? AppColors.statusUrgentText
            : AppColors.tertiary,
        side: BorderSide(
          color: organization.isActive
              ? AppColors.statusUrgentBorder
              : AppColors.tertiaryContainer,
        ),
        minimumSize: Size(
          isMobileOrTablet ? double.infinity : 48,
          AppSpacing.minTouchTarget,
        ),
        shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedSm),
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 980) {
          return Row(
            children: [
              Expanded(child: editButton),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: statusButton),
            ],
          );
        }
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            editButton,
            const SizedBox(width: AppSpacing.sm),
            statusButton,
          ],
        );
      },
    );
  }

  Widget _buildTabBar(CustomerOrganization organization) {
    final tabs = [
      _TabItemData(
        tab: _OrganizationDetailsTab.overview,
        label: 'Overview',
        icon: Icons.apartment_outlined,
      ),
      _TabItemData(
        tab: _OrganizationDetailsTab.administrators,
        label: 'Administrators',
        icon: Icons.people_outline,
        count: organization.admins.length,
      ),
      _TabItemData(
        tab: _OrganizationDetailsTab.license,
        label: 'License',
        icon: Icons.vpn_key_outlined,
      ),
    ];

    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.outlineSubtle)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final tab in tabs)
              _OrganizationDetailsTabButton(
                data: tab,
                selected: _selectedTab == tab.tab,
                onPressed: () => setState(() => _selectedTab = tab.tab),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedTab(
    BuildContext context,
    CustomerOrganization organization,
    PlatformOrganizationsController controller,
  ) {
    switch (_selectedTab) {
      case _OrganizationDetailsTab.overview:
        return OrganizationOverviewTab(
          organization: organization,
          license: controller.selectedLicenseDetails,
          onUpload: (asset) => _showMockAction(asset),
        );
      case _OrganizationDetailsTab.administrators:
        return OrganizationAdministratorsTab(
          organizationName: organization.name,
          administrators: organization.admins,
          onAddAdministrator: () =>
              _showAdministratorDialog(context, organization, controller),
          onAdministratorAction: (administrator, action) =>
              _handleAdministratorAction(
                context,
                organization,
                controller,
                administrator,
                action,
              ),
        );
      case _OrganizationDetailsTab.license:
        final license = controller.selectedLicenseDetails;
        if (controller.isLoading) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.xl),
              child: CircularProgressIndicator(),
            ),
          );
        }
        if (controller.errorMessage != null) {
          return ErrorBanner(
            message: 'Unable to load license details. Please try again.',
            onRetry: () => controller.loadOrganizationDetails(organization.id),
          );
        }
        if (license == null) {
          return OrganizationLicenseEmptyState(
            onAssignLicense: () => _showMockAction('Assign License'),
          );
        }
        return OrganizationLicenseTab(
          license: license,
          onAction: _showMockAction,
        );
    }
  }

  Future<void> _copyOrganizationCode(BuildContext context, String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Organization code copied')));
  }

  void _showMockAction(String action) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$action is shown in this mock-only phase.')),
    );
  }

  Future<void> _showAdministratorDialog(
    BuildContext context,
    CustomerOrganization organization,
    PlatformOrganizationsController controller, {
    OrganizationAdminUser? existingAdministrator,
  }) async {
    final draft = await showDialog<OrganizationAdminDraft>(
      context: context,
      builder: (_) =>
          OrganizationAdminDialog(existingAdministrator: existingAdministrator),
    );
    if (draft == null || !mounted) return;

    final admins = [...organization.admins];
    final existingIndex = admins.indexWhere(
      (admin) => admin.id == draft.administrator.id,
    );
    if (existingIndex == -1) {
      admins.add(draft.administrator);
    } else {
      admins[existingIndex] = draft.administrator;
    }

    // The password is intentionally kept transient and is not written to mock data.
    final saved = await controller.updateOrganization(
      organization.copyWith(admins: admins),
    );
    if (!mounted || !context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          saved == null
              ? controller.actionErrorMessage ?? 'Could not save administrator.'
              : existingAdministrator == null
              ? 'Administrator added to mock organization data.'
              : 'Administrator details updated.',
        ),
      ),
    );
  }

  Future<void> _handleAdministratorAction(
    BuildContext context,
    CustomerOrganization organization,
    PlatformOrganizationsController controller,
    OrganizationAdminUser administrator,
    String action,
  ) async {
    if (action == 'edit') {
      await _showAdministratorDialog(
        context,
        organization,
        controller,
        existingAdministrator: administrator,
      );
      return;
    }

    if (action == 'reset') {
      _showMockAction('Password reset for ${administrator.name}');
      return;
    }

    final admins = [...organization.admins];
    final index = admins.indexWhere((admin) => admin.id == administrator.id);
    if (index == -1) return;

    if (action == 'suspend') {
      admins[index] = administrator.copyWith(
        status: administrator.status.toLowerCase() == 'active'
            ? 'Suspended'
            : 'Active',
      );
      await controller.updateOrganization(
        organization.copyWith(admins: admins),
      );
      return;
    }

    if (action == 'remove') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Remove Administrator?'),
          content: Text(
            'Remove ${administrator.name} from ${organization.name}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Remove'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
      admins.removeAt(index);
      await controller.updateOrganization(
        organization.copyWith(admins: admins),
      );
    }
  }

  void _confirmSuspend(
    BuildContext context,
    CustomerOrganization organization,
    PlatformOrganizationsController controller,
  ) {
    final messenger = ScaffoldMessenger.of(context);
    showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => SuspendOrganizationDialog(
        organization: organization,
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
    BuildContext context,
    CustomerOrganization organization,
    PlatformOrganizationsController controller,
  ) {
    final messenger = ScaffoldMessenger.of(context);
    showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ReactivateOrganizationDialog(
        organization: organization,
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

class _TabItemData {
  const _TabItemData({
    required this.tab,
    required this.label,
    required this.icon,
    this.count,
  });

  final _OrganizationDetailsTab tab;
  final String label;
  final IconData icon;
  final int? count;
}

class _OrganizationDetailsTabButton extends StatelessWidget {
  const _OrganizationDetailsTabButton({
    required this.data,
    required this.selected,
    required this.onPressed,
  });

  final _TabItemData data;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.tertiary : AppColors.secondary;
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onPressed,
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: selected ? AppColors.tertiary : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(data.icon, size: 16, color: color),
              const SizedBox(width: AppSpacing.sm),
              Text(
                data.label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: color,
                ),
              ),
              if (data.count != null) ...[
                const SizedBox(width: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs + 2,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.tertiaryContainer.withValues(alpha: 0.12)
                        : AppColors.surfaceContainerHigh,
                    borderRadius: AppSpacing.roundedPill,
                  ),
                  child: Text(
                    '${data.count}',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: selected
                          ? AppColors.tertiary
                          : AppColors.secondary,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderMetadata extends StatelessWidget {
  const _HeaderMetadata({this.icon, required this.label});

  final IconData? icon;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      if (icon != null) ...[
        Icon(icon, size: 14, color: AppColors.secondary),
        const SizedBox(width: AppSpacing.xs),
      ],
      Text(
        label,
        style: GoogleFonts.inter(fontSize: 11, color: AppColors.secondary),
      ),
    ],
  );
}

class _CodeBadge extends StatelessWidget {
  const _CodeBadge({required this.code, this.onCopy, this.compact = false});

  final String code;
  final VoidCallback? onCopy;
  final bool compact;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(
      horizontal: compact ? AppSpacing.xs : AppSpacing.sm,
      vertical: AppSpacing.xs,
    ),
    decoration: BoxDecoration(
      color: AppColors.surfaceContainerLow,
      border: Border.all(color: AppColors.outlineSubtle),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          code,
          style: GoogleFonts.robotoMono(
            fontSize: compact ? 9 : 10.5,
            fontWeight: FontWeight.w600,
            color: AppColors.onSurface,
          ),
        ),
        if (onCopy != null) ...[
          const SizedBox(width: AppSpacing.xs),
          InkWell(
            onTap: onCopy,
            borderRadius: BorderRadius.circular(4),
            child: const Padding(
              padding: EdgeInsets.all(1),
              child: Icon(
                Icons.copy_outlined,
                size: 12,
                color: AppColors.secondary,
              ),
            ),
          ),
        ],
      ],
    ),
  );
}

class _HeaderPanel extends StatelessWidget {
  const _HeaderPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.all(context.isCompact ? AppSpacing.md : AppSpacing.lg),
    decoration: BoxDecoration(
      color: AppColors.surfaceContainerLowest,
      border: Border.all(color: AppColors.outlineSubtle),
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      boxShadow: const [
        BoxShadow(
          color: Color(0x06000000),
          offset: Offset(0, 2),
          blurRadius: 8,
        ),
        BoxShadow(
          color: Color(0x04000000),
          offset: Offset(0, 1),
          blurRadius: 2,
        ),
      ],
    ),
    child: child,
  );
}
