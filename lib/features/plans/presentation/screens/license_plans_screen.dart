import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:workaxis/app/routing/app_routes.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/app/theme/app_typography.dart';
import 'package:workaxis/core/constants/app_breakpoints.dart';
import 'package:workaxis/core/responsive/responsive_layout.dart';
import 'package:workaxis/core/widgets/app_button.dart';
import 'package:workaxis/core/widgets/app_page_header.dart';
import 'package:workaxis/core/widgets/empty_state.dart';
import 'package:workaxis/core/widgets/error_banner.dart';
import 'package:workaxis/core/widgets/error_state.dart';
import 'package:workaxis/features/plans/domain/models/license_plan.dart';
import 'package:workaxis/features/plans/presentation/controllers/license_plans_controller.dart';
import 'package:workaxis/features/plans/presentation/widgets/license_plan_card_list.dart';
import 'package:workaxis/features/plans/presentation/widgets/license_plan_confirm_dialog.dart';
import 'package:workaxis/features/plans/presentation/widgets/license_plans_filter_bar.dart';
import 'package:workaxis/features/plans/presentation/widgets/license_plans_kpi_section.dart';

/// Platform catalogue of license plans: summary, search and filters, and one
/// card per plan with edit, activate/deactivate and delete actions.
class LicensePlansScreen extends StatefulWidget {
  const LicensePlansScreen({super.key});

  @override
  State<LicensePlansScreen> createState() => _LicensePlansScreenState();
}

/// Space below the list for the circular add button: 56dp button, 16dp edge
/// margin and a little breathing room.
const double _floatingButtonClearance = 96;

class _LicensePlansScreenState extends State<LicensePlansScreen> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    final controller = context.read<LicensePlansController>();
    // The controller outlives this screen; show the query it still applies.
    _searchController = TextEditingController(text: controller.searchQuery);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      controller
        ..clearActionError()
        ..loadPlans();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _resetFilters(LicensePlansController controller) {
    _searchController.clear();
    controller.resetFilters();
  }

  void _openEdit(LicensePlan plan) {
    context.push(AppRoutes.platformPlanEditPath(plan.id));
  }

  Future<void> _confirmToggleStatus(
    LicensePlan plan,
    LicensePlansController controller,
  ) async {
    controller.clearActionError();
    final messenger = ScaffoldMessenger.of(context);
    final deactivating = plan.isActive;
    final target = deactivating ? PlanStatus.inactive : PlanStatus.active;
    final changed = await showLicensePlanConfirmDialog(
      context,
      title: deactivating
          ? 'Deactivate ${plan.name}?'
          : 'Activate ${plan.name}?',
      message: deactivating
          ? 'This plan will no longer be available for new license assignments. '
                'Organizations already on it keep their current limits.'
          : 'This plan becomes available for new license assignments.',
      confirmLabel: deactivating ? 'Deactivate Plan' : 'Activate Plan',
      destructive: deactivating,
      icon: deactivating ? Icons.archive_outlined : Icons.unarchive_outlined,
      onConfirm: () => controller.changeStatus(plan.id, target),
      failureMessage: () => controller.actionErrorMessage,
    );
    if (!changed || !mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          deactivating
              ? 'Plan "${plan.name}" deactivated.'
              : 'Plan "${plan.name}" is now active.',
        ),
        backgroundColor: AppColors.statusActive,
      ),
    );
  }

  Future<void> _confirmDelete(
    LicensePlan plan,
    LicensePlansController controller,
  ) async {
    controller.clearActionError();
    final messenger = ScaffoldMessenger.of(context);
    final deleted = await showLicensePlanConfirmDialog(
      context,
      title: 'Delete ${plan.name}?',
      message:
          'Deleting is only possible when the plan has no license or history '
          'references. This cannot be undone.',
      confirmLabel: 'Delete Plan',
      icon: Icons.delete_outline,
      onConfirm: () => controller.deletePlan(plan.id),
      failureMessage: () => controller.actionErrorMessage,
    );
    if (!deleted || !mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text('Plan "${plan.name}" was deleted.'),
        backgroundColor: AppColors.statusActive,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<LicensePlansController>();

    return Scaffold(
      backgroundColor: AppColors.surface,
      floatingActionButton: FloatingActionButton(
        tooltip: 'Add Plan',
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        onPressed: () {
          context.push(AppRoutes.platformPlansAdd);
        },
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: controller.loadPlans,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: ResponsivePageContent(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppPageHeader(
                        eyebrow: 'Platform Licensing',
                        title: 'Plans & Licensing',
                        subtitle:
                            'Define usage limits available to organizations.',
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      LicensePlansKpiSection(
                        summary: controller.summary,
                        highestPlan: controller.highestVisiblePlan,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      LicensePlansFilterBar(
                        searchController: _searchController,
                        onSearchChanged: controller.setSearchQuery,
                        statusFilter: controller.statusFilter,
                        onStatusFilterChanged: controller.setStatusFilter,
                        totalCount: controller.summary.totalPlans,
                        levels: controller.availableLevels,
                        levelFilter: controller.levelFilter,
                        onLevelFilterChanged: controller.setLevelFilter,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _CaptionRow(count: controller.plans.length),
                      const SizedBox(height: AppSpacing.md),
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
              // Keeps the last row scrollable above the floating add button.
              const SliverToBoxAdapter(
                child: SizedBox(height: _floatingButtonClearance),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildContent(LicensePlansController controller) {
    final plans = controller.plans;

    if (controller.isListLoading && plans.isEmpty) {
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
            onRetry: controller.loadPlans,
          ),
        ),
      ];
    }
    if (plans.isEmpty) {
      return [SliverToBoxAdapter(child: _buildEmptyState(controller))];
    }

    return [
      SliverPadding(
        padding: _pagePadding(context),
        sliver: SliverLayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.crossAxisExtent;
            final columns = width >= AppBreakpoints.wideTable
                ? 3
                : (width >= AppBreakpoints.mediumMin ? 2 : 1);
            return LicensePlanCardList(
              plans: plans,
              columns: columns,
              onEdit: (plan) {
                _openEdit(plan);
              },
              onToggleStatus: (plan) {
                _confirmToggleStatus(plan, controller);
              },
              onDelete: (plan) {
                _confirmDelete(plan, controller);
              },
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

  Widget _buildEmptyState(LicensePlansController controller) {
    final hasFilter = controller.hasActiveFilters;
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
          icon: hasFilter ? Icons.search_off : Icons.layers_outlined,
          title: hasFilter ? 'No matching plans' : 'No license plans yet',
          message: hasFilter ? 'Try adjusting your search or filters.' : 'Create the first plan to define store and user limits for organizations.',
          action: hasFilter
              ? AppButton.outlined(
                  text: 'Reset filters',
                  isFullWidth: false,
                  onPressed: () => _resetFilters(controller),
                )
              : null,
        ),
      ),
    );
  }
}

/// "SHOWING N PLANS" on the left and the sort note on the right.
class _CaptionRow extends StatelessWidget {
  const _CaptionRow({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final style = AppTypography.labelSmall.copyWith(
      fontWeight: FontWeight.w700,
      letterSpacing: 0.6,
      color: AppColors.secondary,
    );
    return Row(
      children: [
        Expanded(
          child: Text(
            'SHOWING $count ${count == 1 ? 'PLAN' : 'PLANS'}',
            style: style,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(
          'Auto-sorted by Level',
          style: AppTypography.labelSmall.copyWith(color: AppColors.secondary),
        ),
      ],
    );
  }
}
