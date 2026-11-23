import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:workaxis/app/routing/app_routes.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/core/responsive/responsive_sliver_page.dart';
import 'package:workaxis/core/widgets/app_button.dart';
import 'package:workaxis/core/widgets/app_page_header.dart';
import 'package:workaxis/core/widgets/kpi/app_kpi_card.dart';
import 'package:workaxis/core/widgets/kpi/responsive_kpi_section.dart';
import 'package:workaxis/features/access/presentation/controllers/access_controller.dart';
import 'package:workaxis/features/access/presentation/controllers/branch_context_controller.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';
import 'package:workaxis/features/returns/domain/models/return_item.dart';
import 'package:workaxis/features/returns/domain/models/return_status_counts.dart';
import 'package:workaxis/features/returns/presentation/controllers/returns_controller.dart';
import 'package:workaxis/features/returns/presentation/screens/widgets/returns_filter_bar.dart';
import 'package:workaxis/features/returns/presentation/screens/widgets/returns_sliver_body.dart';
import 'package:workaxis/features/returns/presentation/screens/widgets/returns_table.dart';

/// Return review queue for Organization Admins and Branch Managers.
class ReturnsOperationsScreen extends StatefulWidget {
  const ReturnsOperationsScreen({super.key});

  @override
  State<ReturnsOperationsScreen> createState() =>
      _ReturnsOperationsScreenState();
}

class _ReturnsOperationsScreenState extends State<ReturnsOperationsScreen> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: context.read<ReturnsController>().searchQuery,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String? get _activeBranchId =>
      context.read<BranchContextController>().activeBranch?.branchId;

  Future<void> _loadData() async {
    final access = context.read<AccessController>().accessContext;
    if (access == null) return;
    await context.read<ReturnsController>().loadReturns(
      access: access,
      activeBranchId: _activeBranchId,
    );
  }

  /// Organization admins and branch managers open the same list, so the page
  /// is picked by role.
  void _openDetails(ReturnItem item) {
    final path = _isManager
        ? AppRoutes.branchManagerReturnDetailsPath(item.id)
        : AppRoutes.orgAdminReturnDetailsPath(item.id);
    context.push(path);
  }

  /// Only branch managers record returns from this list.
  void _openSubmit() {
    context.push(AppRoutes.branchManagerReturnAddPath);
  }

  bool get _isManager =>
      context.read<AccessController>().accessContext?.user.role ==
      UserRole.branchManager;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ReturnsController>();
    final access = context.watch<AccessController>().accessContext;
    final branchName = context
        .watch<BranchContextController>()
        .activeBranch
        ?.branchName;
    final role = access?.user.role;
    final isManager = role == UserRole.branchManager;
    final canReview =
        role == UserRole.orgAdmin || role == UserRole.branchManager;
    final hasPending = controller.pendingCount > 0;
    final showsOwnQueue = isManager && controller.queue == ReturnQueue.mine;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: ResponsiveSliverPage(
          onRefresh: _loadData,
          slivers: [
            SliverToBoxAdapter(
              child: AppPageHeader(
                eyebrow: isManager
                    ? 'Branch Operations'
                    : 'Inventory & Returns',
                title: isManager ? 'Branch Returns' : 'Organization Returns',
                subtitle: isManager
                    ? 'Review and verify return requests for ${branchName ?? 'the active branch'}.'
                    : 'Verify customer and inventory return requests across all branches.',
                action: isManager
                    ? AppButton.responsive(
                        text: 'Record Return',
                        iconData: Icons.add_circle_outline,
                        onPressed: _openSubmit,
                      )
                    : null,
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),
            SliverToBoxAdapter(
              child: ResponsiveKpiSection(
                cards: [
                  AppKpiCard(
                    title: 'Pending review',
                    value: '${controller.pendingCount}',
                    accentColor: hasPending ? AppColors.statusUrgent : null,
                    icon: Icons.pending_actions_outlined,
                    iconColor: hasPending
                        ? AppColors.statusUrgentText
                        : AppColors.secondary,
                    iconBgColor: hasPending
                        ? AppColors.statusUrgentContainer
                        : AppColors.kpiNeutralBackground,
                    valueColor: hasPending ? AppColors.statusUrgentText : null,
                  ),
                  AppKpiCard(
                    title: 'Approved',
                    value: '${controller.approvedCount}',
                    accentColor: AppColors.statusActive,
                    icon: Icons.check_circle_outline,
                    iconColor: AppColors.statusActiveText,
                    iconBgColor: AppColors.statusActiveContainer,
                  ),
                  AppKpiCard(
                    title: 'Rejected',
                    value: '${controller.rejectedCount}',
                    icon: Icons.cancel_outlined,
                    iconColor: AppColors.secondary,
                    iconBgColor: AppColors.kpiNeutralBackground,
                  ),
                  AppKpiCard(
                    title: 'Total returns',
                    value: '${controller.totalCount}',
                    icon: Icons.assignment_return_outlined,
                    iconColor: AppColors.primary,
                    iconBgColor: AppColors.primaryContainer,
                  ),
                ],
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
            if (isManager)
              SliverToBoxAdapter(
                child: SegmentedButton<ReturnQueue>(
                  segments: const [
                    ButtonSegment(
                      value: ReturnQueue.mine,
                      label: Text('My returns'),
                      icon: Icon(Icons.person_outline),
                    ),
                    ButtonSegment(
                      value: ReturnQueue.others,
                      label: Text('Returns filed by others'),
                      icon: Icon(Icons.groups_outlined),
                    ),
                  ],
                  selected: {controller.queue},
                  onSelectionChanged: (selection) =>
                      controller.setQueue(selection.first),
                ),
              ),
            if (isManager)
              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),
            SliverToBoxAdapter(
              child: ReturnsFilterBar(
                controller: controller,
                searchController: _searchController,
                searchHint: 'Search product, invoice, or employee...',
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),
            SliverReturnsBody(
              controller: controller,
              showReviewAction: canReview,
              reviewerUid: isManager ? access?.user.id : null,
              onOpen: _openDetails,
              onRetry: _loadData,
              emptyTitle: showsOwnQueue
                  ? 'No returns filed by you'
                  : 'No return requests found',
              emptyMessage: showsOwnQueue
                  ? 'Returns you submit will appear here.'
                  : 'There are no returned products matching your filter criteria.',
              columns: [
                ReturnsTableColumn.product(),
                ReturnsTableColumn.quantity(),
                ReturnsTableColumn.invoice('Invoice #'),
                ReturnsTableColumn.employee(),
                ReturnsTableColumn.branch(),
                ReturnsTableColumn.status(),
                ReturnsTableColumn.action(
                  canReview: canReview,
                  reviewerUid: isManager ? access?.user.id : null,
                  onOpen: _openDetails,
                ),
              ],
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
          ],
        ),
      ),
    );
  }
}
