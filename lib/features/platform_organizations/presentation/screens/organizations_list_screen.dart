import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:workaxis/app/routing/app_routes.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/core/responsive/responsive_layout.dart';
import 'package:workaxis/core/widgets/app_button.dart';
import 'package:workaxis/core/widgets/app_page_header.dart';
import 'package:workaxis/core/widgets/kpi/app_kpi_card.dart';
import 'package:workaxis/core/widgets/kpi/responsive_kpi_section.dart';
import 'package:workaxis/features/platform_organizations/domain/models/customer_organization.dart';
import 'package:workaxis/features/platform_organizations/domain/models/organization_status.dart';
import 'package:workaxis/features/platform_organizations/presentation/controllers/platform_organizations_controller.dart';
import 'package:workaxis/features/platform_organizations/presentation/widgets/organization_card_item.dart';
import 'package:workaxis/features/platform_organizations/presentation/widgets/organizations_table.dart';

/// Screen displaying the catalog of customer organizations with search, filtering, and CRUD navigation.
class OrganizationsListScreen extends StatefulWidget {
  const OrganizationsListScreen({super.key});

  @override
  State<OrganizationsListScreen> createState() =>
      _OrganizationsListScreenState();
}

class _OrganizationsListScreenState extends State<OrganizationsListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PlatformOrganizationsController>().loadOrganizations();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PlatformOrganizationsController>();
    final isCompact = context.isCompact;
    final isTablet = context.isMedium;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: controller.loadOrganizations,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ResponsivePageContent(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                    // Page Header with Action
                    AppPageHeader(
                      title: 'Organizations',
                      subtitle: 'Manage customer organizations and their operational status across all deployed branch hubs.',
                      eyebrow: 'Platform Catalog',
                      action: AppButton.primary(
                        text: 'Add Organization',
                        iconData: Icons.add,
                        isFullWidth: false,
                        onPressed: () =>
                            context.push(AppRoutes.platformOrganizationsAdd),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Executive KPI Overview Tiles
                    _buildKpiMetrics(context, controller),
                    const SizedBox(height: AppSpacing.lg),

                    // Search and Filter Bar Card
                    _buildSearchAndFilterBar(context, controller),
                    const SizedBox(height: AppSpacing.lg),

                    // Main Content Area: Loading, Error, Empty, or Data
                    if (controller.isLoading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 48),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (controller.errorMessage != null)
                      _buildErrorState(context, controller)
                    else if (controller.organizations.isEmpty)
                      _buildEmptyState(context, controller)
                    else if (!isCompact && !isTablet)
                      // Desktop Web: Structured Data Table
                      OrganizationsTable(
                        organizations: controller.organizations,
                        onSelect: (org) => _navigateToDetails(context, org),
                        onEdit: (org) => _navigateToEdit(context, org),
                      )
                    else if (isTablet)
                      // Tablet: 2-Column Responsive Card Grid
                      _buildTabletGrid(context, controller.organizations)
                    else
                      // Smartphone: Single Column Cards
                      _buildMobileList(context, controller.organizations),

                    const SizedBox(height: AppSpacing.xxl),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

  Widget _buildKpiMetrics(
    BuildContext context,
    PlatformOrganizationsController controller,
  ) {
    return ResponsiveKpiSection(
      cardHeight: 96,
      cards: [
        AppKpiCard(
          title: 'Total Tenants',
          value: '${controller.totalCount}',
          accentColor: const Color(0xFF003366),
          icon: Icons.business_outlined,
          iconColor: AppColors.primary,
          iconBgColor: AppColors.primaryContainer,
          iconPosition: AppKpiIconPosition.bottomRight,
        ),
        AppKpiCard(
          title: 'Active Fleet',
          value: '${controller.activeCount}',
          valueColor: const Color(0xFF15803D),
          accentColor: const Color(0xFF16A34A),
          icon: Icons.check_circle_outline_rounded,
          iconColor: const Color(0xFF16A34A),
          iconBgColor: const Color(0xFFDCFCE7),
          iconPosition: AppKpiIconPosition.bottomRight,
        ),
        AppKpiCard(
          title: 'Suspended',
          value: '${controller.suspendedCount}',
          accentColor: const Color(0xFFDC2626),
          valueColor: controller.suspendedCount > 0
              ? const Color(0xFFDC2626)
              : null,
          icon: Icons.pause_circle_outline_rounded,
          iconColor: const Color(0xFFDC2626),
          iconBgColor: const Color(0xFFFEE2E2),
          iconPosition: AppKpiIconPosition.bottomRight,
        ),
      ],
    );
  }

  Widget _buildSearchAndFilterBar(
    BuildContext context,
    PlatformOrganizationsController controller,
  ) {
    final isCompact = context.isCompact;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.outlineSubtle, width: 1),
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
      child: isCompact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSearchField(controller),
                const SizedBox(height: AppSpacing.sm),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(children: _buildFilterChips(controller)),
                ),
              ],
            )
          : Row(
              children: [
                Expanded(
                  child: _buildSearchField(controller),
                ),
                const SizedBox(width: AppSpacing.md),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: _buildFilterChips(controller),
                ),
              ],
            ),
    );
  }

  Widget _buildSearchField(PlatformOrganizationsController controller) {
    return SizedBox(
      height: 36,
      child: TextField(
        controller: _searchController,
        onChanged: (val) {
          controller.setSearchQuery(val);
          setState(() {});
        },
        style: GoogleFonts.inter(fontSize: 12),
        decoration: InputDecoration(
          hintText: 'Search by name or code (e.g. Apex, ORG-APX)...',
          hintStyle: GoogleFonts.inter(
            fontSize: 11,
            color: AppColors.textMuted,
          ),
          prefixIcon: const Icon(
            Icons.search,
            size: 16,
            color: AppColors.secondary,
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 32,
            minHeight: 32,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? InkWell(
                  onTap: () {
                    _searchController.clear();
                    controller.setSearchQuery('');
                    setState(() {});
                  },
                  child: const Icon(
                    Icons.clear,
                    size: 16,
                    color: AppColors.secondary,
                  ),
                )
              : null,
          suffixIconConstraints: const BoxConstraints(
            minWidth: 32,
            minHeight: 32,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 0,
          ),
          filled: true,
          fillColor: AppColors.surfaceContainerLow,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(100),
            borderSide: const BorderSide(
              color: AppColors.outlineSubtle,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(100),
            borderSide: const BorderSide(
              color: AppColors.outlineSubtle,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(100),
            borderSide: const BorderSide(
              color: AppColors.primary,
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildFilterChips(PlatformOrganizationsController controller) {
    final current = controller.statusFilter;

    return [
      Text(
        'Status: ',
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColors.secondary,
        ),
      ),
      const SizedBox(width: AppSpacing.xs),
      _FilterButton(
        label: 'All (${controller.totalCount})',
        isSelected: current == null,
        onTap: () => controller.setStatusFilter(null),
      ),
      const SizedBox(width: AppSpacing.xs),
      _FilterButton(
        label: 'Active (${controller.activeCount})',
        dotColor: AppColors.statusActive,
        isSelected: current == OrganizationStatus.active,
        onTap: () => controller.setStatusFilter(OrganizationStatus.active),
      ),
      const SizedBox(width: AppSpacing.xs),
      _FilterButton(
        label: 'Suspended (${controller.suspendedCount})',
        dotColor: AppColors.statusUrgent,
        isSelected: current == OrganizationStatus.suspended,
        onTap: () => controller.setStatusFilter(OrganizationStatus.suspended),
      ),
    ];
  }

  Widget _buildTabletGrid(
    BuildContext context,
    List<CustomerOrganization> organizations,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: organizations.map((org) {
            final cardWidth = (constraints.maxWidth - AppSpacing.md) / 2;
            return SizedBox(
              width: cardWidth,
              child: OrganizationCardItem(
                organization: org,
                onTap: () => _navigateToDetails(context, org),
                onEdit: () => _navigateToEdit(context, org),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildMobileList(
    BuildContext context,
    List<CustomerOrganization> organizations,
  ) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: organizations.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) {
        final org = organizations[index];
        return OrganizationCardItem(
          organization: org,
          onTap: () => _navigateToDetails(context, org),
          onEdit: () => _navigateToEdit(context, org),
        );
      },
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    PlatformOrganizationsController controller,
  ) {
    final hasFilter =
        controller.searchQuery.isNotEmpty || controller.statusFilter != null;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.outlineSubtle),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHigh,
                shape: BoxShape.circle,
              ),
              child: Icon(
                hasFilter ? Icons.search_off : Icons.business_outlined,
                size: 26,
                color: AppColors.secondary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              hasFilter
                  ? 'No matching customer organizations'
                  : 'No customer organizations registered',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              hasFilter
                  ? 'Try adjusting your search terms or status filters.'
                  : 'Get started by creating your first customer organization.',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.secondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (hasFilter) ...[
              const SizedBox(height: AppSpacing.md),
              OutlinedButton(
                onPressed: () {
                  _searchController.clear();
                  controller.setSearchQuery('');
                  controller.setStatusFilter(null);
                },
                child: const Text('Reset filters'),
              ),
            ] else ...[
              const SizedBox(height: AppSpacing.md),
              ElevatedButton.icon(
                onPressed: () =>
                    context.push(AppRoutes.platformOrganizationsAdd),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Organization'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(
    BuildContext context,
    PlatformOrganizationsController controller,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.statusUrgentContainer,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.statusUrgentBorder),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline,
            color: AppColors.statusUrgent,
            size: 28,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Error loading organizations',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.statusUrgentText,
                  ),
                ),
                Text(
                  controller.errorMessage ?? 'An unexpected error occurred.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.statusUrgentText,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: controller.loadOrganizations,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  void _navigateToDetails(BuildContext context, CustomerOrganization org) {
    context.push(AppRoutes.platformOrganizationDetailsPath(org.id));
  }

  void _navigateToEdit(BuildContext context, CustomerOrganization org) {
    context.push(AppRoutes.platformOrganizationEditPath(org.id));
  }
}

class _FilterButton extends StatelessWidget {
  final String label;
  final Color? dotColor;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterButton({
    required this.label,
    this.dotColor,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(100),
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary
                : AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(100),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.outlineSubtle,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      offset: const Offset(0, 1),
                      blurRadius: 4,
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (dotColor != null) ...[
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white : dotColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? Colors.white : AppColors.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
