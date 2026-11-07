import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:workaxis/app/routing/app_routes.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/core/constants/app_breakpoints.dart';
import 'package:workaxis/core/responsive/responsive_layout.dart';
import 'package:workaxis/core/widgets/app_button.dart';
import 'package:workaxis/core/widgets/app_page_header.dart';
import 'package:workaxis/core/widgets/empty_state.dart';
import 'package:workaxis/core/widgets/error_banner.dart';
import 'package:workaxis/core/widgets/error_state.dart';
import 'package:workaxis/core/widgets/kpi/app_kpi_card.dart';
import 'package:workaxis/core/widgets/kpi/responsive_kpi_section.dart';
import 'package:workaxis/features/platform_organizations/domain/models/customer_organization.dart';
import 'package:workaxis/features/platform_organizations/presentation/controllers/platform_organizations_controller.dart';
import 'package:workaxis/features/platform_organizations/presentation/widgets/organization_card_list.dart';
import 'package:workaxis/features/platform_organizations/presentation/widgets/organizations_filter_bar.dart';
import 'package:workaxis/features/platform_organizations/presentation/widgets/organizations_table.dart';

/// Catalog of customer organizations with search, filtering and paging.
class OrganizationsListScreen extends StatefulWidget {
  const OrganizationsListScreen({super.key});

  @override
  State<OrganizationsListScreen> createState() =>
      _OrganizationsListScreenState();
}

class _OrganizationsListScreenState extends State<OrganizationsListScreen> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    final controller = context.read<PlatformOrganizationsController>();
    // The controller outlives this screen; show the query it still applies.
    _searchController = TextEditingController(text: controller.searchQuery);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      controller
        ..clearActionError()
        ..loadOrganizations();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _resetFilters(PlatformOrganizationsController controller) {
    _searchController.clear();
    controller
      ..setSearchQuery('')
      ..setStatusFilter(null);
  }

  void _openDetails(CustomerOrganization org) =>
      context.push(AppRoutes.platformOrganizationDetailsPath(org.id));

  void _openEdit(CustomerOrganization org) =>
      context.push(AppRoutes.platformOrganizationEditPath(org.id));

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PlatformOrganizationsController>();

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: controller.loadOrganizations,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: ResponsivePageContent(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppPageHeader(
                        title: 'Organizations',
                        subtitle:
                            'Manage customer organizations and their '
                            'operational status across all deployed branch hubs.',
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
                      _KpiMetrics(controller: controller),
                      const SizedBox(height: AppSpacing.lg),
                      OrganizationsFilterBar(
                        searchController: _searchController,
                        onSearchChanged: controller.setSearchQuery,
                        statusFilter: controller.statusFilter,
                        onStatusFilterChanged: controller.setStatusFilter,
                        totalCount: controller.totalCount,
                        activeCount: controller.activeCount,
                        suspendedCount: controller.suspendedCount,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      if (controller.actionErrorMessage != null) ...[
                        ErrorBanner(
                          message: controller.actionErrorMessage!,
                          onDismiss: controller.clearActionError,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                      ],
                    ],
                  ),
                ),
              ),
              ..._buildContent(controller),
              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildContent(PlatformOrganizationsController controller) {
    final organizations = controller.organizations;

    if (controller.isListLoading && organizations.isEmpty) {
      return const [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.xxl),
            child: Center(child: CircularProgressIndicator()),
          ),
        ),
      ];
    }
    if (controller.listErrorMessage != null) {
      return [
        SliverToBoxAdapter(
          child: ErrorState(
            message: controller.listErrorMessage!,
            onRetry: controller.loadOrganizations,
          ),
        ),
      ];
    }
    if (organizations.isEmpty) {
      return [SliverToBoxAdapter(child: _buildEmptyState(controller))];
    }

    return [
      SliverPadding(
        padding: _pagePadding(context),
        sliver: SliverLayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.crossAxisExtent;
            if (width >= AppBreakpoints.wideTable) {
              return OrganizationsTable(
                organizations: organizations,
                onSelect: _openDetails,
                onEdit: _openEdit,
                hasMore: controller.hasMore,
                isLoadingMore: controller.isLoadingMore,
                onLoadMore: controller.loadMore,
              );
            }
            return SliverMainAxisGroup(
              slivers: [
                OrganizationCardList(
                  organizations: organizations,
                  columns: width >= AppBreakpoints.mediumMin ? 2 : 1,
                  onSelect: _openDetails,
                  onEdit: _openEdit,
                ),
                if (controller.hasMore)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.md),
                      child: AppButton.outlined(
                        text: 'Load more',
                        isLoading: controller.isLoadingMore,
                        onPressed: controller.loadMore,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    ];
  }

  /// Matches the horizontal padding of [ResponsivePageContent], including its
  /// centered maximum width, so slivers align with the header above.
  EdgeInsets _pagePadding(BuildContext context) {
    final inset = context.responsivePagePadding.horizontal / 2;
    final extra = (context.screenWidth - AppBreakpoints.maxPageWidth) / 2;
    return EdgeInsets.symmetric(horizontal: inset + (extra > 0 ? extra : 0));
  }

  Widget _buildEmptyState(PlatformOrganizationsController controller) {
    final hasFilter =
        controller.searchQuery.isNotEmpty || controller.statusFilter != null;
    return Padding(
      padding: _pagePadding(context),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: AppSpacing.roundedMd,
          border: Border.all(color: AppColors.outlineSubtle),
        ),
        child: EmptyState(
          icon: hasFilter ? Icons.search_off : Icons.business_outlined,
          title: hasFilter
              ? 'No matching customer organizations'
              : 'No customer organizations registered',
          message: hasFilter
              ? 'Try adjusting your search terms or status filters.'
              : 'Get started by creating your first customer organization.',
          action: hasFilter
              ? AppButton.outlined(
                  text: 'Reset filters',
                  isFullWidth: false,
                  onPressed: () => _resetFilters(controller),
                )
              : AppButton.primary(
                  text: 'Add Organization',
                  iconData: Icons.add,
                  isFullWidth: false,
                  onPressed: () =>
                      context.push(AppRoutes.platformOrganizationsAdd),
                ),
        ),
      ),
    );
  }
}

class _KpiMetrics extends StatelessWidget {
  const _KpiMetrics({required this.controller});

  final PlatformOrganizationsController controller;

  @override
  Widget build(BuildContext context) {
    return ResponsiveKpiSection(
      cardHeight: AppKpiCard.minHeight,
      cards: [
        AppKpiCard(
          title: 'Total Tenants',
          value: '${controller.totalCount}',
          accentColor: AppColors.primaryDark,
          icon: Icons.business_outlined,
          iconColor: AppColors.primary,
          iconBgColor: AppColors.primaryContainer,
          iconPosition: AppKpiIconPosition.bottomRight,
        ),
        AppKpiCard(
          title: 'Active Fleet',
          value: '${controller.activeCount}',
          valueColor: AppColors.kpiPositive,
          accentColor: AppColors.kpiPositiveAccent,
          icon: Icons.check_circle_outline_rounded,
          iconColor: AppColors.kpiPositiveAccent,
          iconBgColor: AppColors.kpiPositiveBackground,
          iconPosition: AppKpiIconPosition.bottomRight,
        ),
        AppKpiCard(
          title: 'Suspended',
          value: '${controller.suspendedCount}',
          accentColor: AppColors.kpiCritical,
          valueColor: controller.suspendedCount > 0
              ? AppColors.kpiCritical
              : null,
          icon: Icons.pause_circle_outline_rounded,
          iconColor: AppColors.kpiCritical,
          iconBgColor: AppColors.kpiCriticalBackground,
          iconPosition: AppKpiIconPosition.bottomRight,
        ),
      ],
    );
  }
}
