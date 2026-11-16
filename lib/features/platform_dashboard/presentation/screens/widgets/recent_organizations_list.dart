import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:workaxis/app/routing/app_routes.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_shadows.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/app/theme/app_typography.dart';
import 'package:workaxis/core/constants/app_breakpoints.dart';
import 'package:workaxis/core/widgets/app_button.dart';
import 'package:workaxis/core/widgets/empty_state.dart';
import 'package:workaxis/core/widgets/error_banner.dart';
import 'package:workaxis/features/platform_organizations/domain/models/customer_organization.dart';
import 'package:workaxis/features/platform_organizations/domain/models/organization_status.dart';
import 'package:workaxis/features/platform_organizations/presentation/widgets/organization_card_list.dart';
import 'package:workaxis/features/platform_organizations/presentation/widgets/organizations_filter_bar.dart';
import 'package:workaxis/features/platform_organizations/presentation/widgets/organizations_table.dart';

/// Dashboard panel with the most recent customer organizations.
///
/// It shows the same table and cards as the Organizations tab. Search and the
/// status filter are sent to the server, so they cover every organization, not
/// just the newest rows. The counts on the filter chips are the platform totals.
class RecentOrganizationsList extends StatefulWidget {
  const RecentOrganizationsList({
    super.key,
    required this.organizations,
    required this.totalCount,
    required this.activeCount,
    required this.suspendedCount,
    required this.onSearchChanged,
    this.errorMessage,
    this.onViewAll,
  });

  final List<CustomerOrganization> organizations;
  final int totalCount;
  final int activeCount;
  final int suspendedCount;

  /// Called with the current search text and status whenever either changes.
  final void Function(String query, OrganizationStatus? status) onSearchChanged;

  /// Failure from the last search; the previous rows stay visible.
  final String? errorMessage;
  final VoidCallback? onViewAll;

  @override
  State<RecentOrganizationsList> createState() =>
      _RecentOrganizationsListState();
}

class _RecentOrganizationsListState extends State<RecentOrganizationsList> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  OrganizationStatus? _status;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _changeQuery(String value) {
    setState(() => _query = value);
    widget.onSearchChanged(_query, _status);
  }

  void _changeStatus(OrganizationStatus? status) {
    setState(() => _status = status);
    widget.onSearchChanged(_query, _status);
  }

  void _openDetails(CustomerOrganization org) =>
      context.push(AppRoutes.platformOrganizationDetailsPath(org.id));

  @override
  Widget build(BuildContext context) {
    final hasFilter = _query.trim().isNotEmpty || _status != null;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: AppSpacing.roundedMd,
        border: Border.all(color: AppColors.outlineSubtle),
        boxShadow: AppShadows.card,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: AppSpacing.lg,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recent Organizations',
                  style: AppTypography.titleLarge.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                OrganizationsFilterBar(
                  searchController: _searchController,
                  onSearchChanged: _changeQuery,
                  statusFilter: _status,
                  onStatusFilterChanged: _changeStatus,
                  totalCount: widget.totalCount,
                  activeCount: widget.activeCount,
                  suspendedCount: widget.suspendedCount,
                ),
              ],
            ),
          ),
          if (widget.errorMessage != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                0,
                AppSpacing.xl,
                AppSpacing.md,
              ),
              child: ErrorBanner(message: widget.errorMessage!),
            ),
          const Divider(color: AppColors.outlineSubtle, height: 1),
          _RecentOrganizationResults(
            organizations: widget.organizations,
            onSelect: _openDetails,
            emptyTitle: hasFilter
                ? 'No matching organizations.'
                : 'No organizations found.',
            emptyIcon: hasFilter
                ? Icons.search_off_outlined
                : Icons.business_outlined,
          ),
          const Divider(color: AppColors.outlineSubtle, height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: AppSpacing.sm,
            ),
            child: Align(
              alignment: Alignment.centerRight,
              child: AppButton.link(
                text: 'View All',
                iconData: Icons.arrow_forward,
                onPressed:
                    widget.onViewAll ??
                    () => context.go(AppRoutes.platformOrganizations),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The organizations as the Organizations tab lays them out: a table on wide
/// layouts, one or two columns of cards otherwise.
class _RecentOrganizationResults extends StatelessWidget {
  const _RecentOrganizationResults({
    required this.organizations,
    required this.onSelect,
    required this.emptyTitle,
    required this.emptyIcon,
  });

  final List<CustomerOrganization> organizations;
  final ValueChanged<CustomerOrganization> onSelect;
  final String emptyTitle;
  final IconData emptyIcon;

  @override
  Widget build(BuildContext context) {
    if (organizations.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: EmptyState(icon: emptyIcon, title: emptyTitle),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        // Slivers need a scrollable parent; the dashboard scrolls the page, so
        // this viewport only sizes itself to its content.
        return CustomScrollView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          slivers: [
            if (width >= AppBreakpoints.wideTable)
              OrganizationsTable(
                organizations: organizations,
                onSelect: onSelect,
                hasMore: false,
                isLoadingMore: false,
                onLoadMore: () {},
              )
            else
              SliverPadding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                sliver: OrganizationCardList(
                  organizations: organizations,
                  columns: width >= AppBreakpoints.mediumMin ? 2 : 1,
                  onSelect: onSelect,
                ),
              ),
          ],
        );
      },
    );
  }
}
