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
import 'package:workaxis/features/platform_dashboard/domain/models/recent_organization_summary.dart';
import 'package:workaxis/features/platform_dashboard/presentation/screens/widgets/recent_organizations/recent_organization_card.dart';
import 'package:workaxis/features/platform_dashboard/presentation/screens/widgets/recent_organizations/recent_organization_rows.dart';
import 'package:workaxis/features/platform_dashboard/presentation/screens/widgets/recent_organizations/recent_organizations_filter.dart';
import 'package:workaxis/features/platform_dashboard/presentation/screens/widgets/recent_organizations/recent_organizations_filter_bar.dart';

/// Structured panel of recent customer organizations with search, status
/// filters and a table (desktop), cards (tablet) or rows (phone).
class RecentOrganizationsList extends StatefulWidget {
  const RecentOrganizationsList({
    super.key,
    required this.organizations,
    this.onViewAll,
  });

  final List<RecentOrganizationSummary> organizations;
  final VoidCallback? onViewAll;

  @override
  State<RecentOrganizationsList> createState() =>
      _RecentOrganizationsListState();
}

class _RecentOrganizationsListState extends State<RecentOrganizationsList> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  RecentOrganizationsFilter _filter = RecentOrganizationsFilter.all;

  late List<RecentOrganizationSummary> _filtered;
  late Map<RecentOrganizationsFilter, int> _counts;

  @override
  void initState() {
    super.initState();
    _recompute();
  }

  @override
  void didUpdateWidget(covariant RecentOrganizationsList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.organizations, widget.organizations)) {
      _recompute();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _recompute() {
    _filtered = filterRecentOrganizations(
      widget.organizations,
      filter: _filter,
      query: _query,
    );
    _counts = {
      for (final f in RecentOrganizationsFilter.values)
        f: widget.organizations.where(f.matches).length,
    };
  }

  void _update(VoidCallback change) => setState(() {
    change();
    _recompute();
  });

  @override
  Widget build(BuildContext context) {
    if (widget.organizations.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: AppSpacing.roundedMd,
          border: Border.all(color: AppColors.outlineSubtle),
        ),
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: const EmptyState(
          icon: Icons.business_outlined,
          title: 'No organizations found.',
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= AppBreakpoints.wideContent;
        final isCompact = constraints.maxWidth < AppBreakpoints.mediumMin;
        final isTablet = !isDesktop && !isCompact;

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
                    RecentOrganizationsFilterBar(
                      isCompact: isCompact,
                      searchController: _searchController,
                      selected: _filter,
                      counts: _counts,
                      onSearchChanged: (v) => _update(() => _query = v),
                      onSearchCleared: () => _update(() {
                        _searchController.clear();
                        _query = '';
                      }),
                      onFilterChanged: (f) => _update(() => _filter = f),
                    ),
                  ],
                ),
              ),
              const Divider(color: AppColors.outlineSubtle, height: 1),
              if (isDesktop) const RecentOrganizationsTableHeader(),
              if (_filtered.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(AppSpacing.xl),
                  child: EmptyState(
                    icon: Icons.search_off_outlined,
                    title: 'No matching organizations.',
                  ),
                )
              else if (isTablet)
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Wrap(
                    spacing: AppSpacing.md,
                    runSpacing: AppSpacing.md,
                    children: [
                      for (final org in _filtered)
                        SizedBox(
                          width:
                              (constraints.maxWidth -
                                  AppSpacing.lg * 2 -
                                  AppSpacing.md) /
                              2,
                          child: RecentOrganizationCard(org: org),
                        ),
                    ],
                  ),
                )
              else
                for (var i = 0; i < _filtered.length; i++)
                  isDesktop
                      ? RecentOrganizationDesktopRow(
                          org: _filtered[i],
                          isLast: i == _filtered.length - 1,
                        )
                      : RecentOrganizationCompactRow(
                          org: _filtered[i],
                          isLast: i == _filtered.length - 1,
                        ),
              const Divider(color: AppColors.outlineSubtle, height: 1),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl,
                  vertical: AppSpacing.sm,
                ),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: AppButton.outlined(
                    text: 'View All',
                    iconData: Icons.arrow_forward,
                    isFullWidth: false,
                    onPressed:
                        widget.onViewAll ??
                        () => context.go(AppRoutes.platformOrganizations),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
