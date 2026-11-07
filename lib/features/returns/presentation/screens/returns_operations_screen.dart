import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/core/responsive/responsive_sliver_page.dart';
import 'package:workaxis/core/widgets/app_page_header.dart';
import 'package:workaxis/core/widgets/kpi/app_kpi_card.dart';
import 'package:workaxis/core/widgets/kpi/responsive_kpi_section.dart';
import 'package:workaxis/features/access/presentation/controllers/access_controller.dart';
import 'package:workaxis/features/access/presentation/controllers/branch_context_controller.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';
import 'package:workaxis/features/returns/domain/models/return_item.dart';
import 'package:workaxis/features/returns/presentation/controllers/returns_controller.dart';
import 'package:workaxis/features/returns/presentation/screens/widgets/return_details_dialog.dart';
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

  void _showDetails(ReturnItem item, bool canReview) {
    final access = context.read<AccessController>().accessContext;
    if (access == null) return;
    final controller = context.read<ReturnsController>();
    final activeBranchId = _activeBranchId;
    controller.clearActionError();
    showDialog<void>(
      context: context,
      builder: (_) => ReturnDetailsDialog(
        item: item,
        canReview: canReview,
        onReviewDecision: (decision, notes) async {
          final saved = await controller.reviewReturn(
            access: access,
            activeBranchId: activeBranchId,
            item: item,
            decision: decision,
            reviewerNotes: notes,
          );
          if (!saved) {
            return controller.actionErrorMessage ??
                'The decision could not be saved.';
          }
          if (mounted) {
            final approved = decision == ReturnStatus.approved;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  approved
                      ? 'Return request #${item.id} approved.'
                      : 'Return request #${item.id} rejected.',
                ),
                backgroundColor: approved
                    ? AppColors.statusActive
                    : AppColors.statusUrgent,
              ),
            );
          }
          return null;
        },
      ),
    );
  }

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
              onOpen: (item) => _showDetails(item, canReview),
              onRetry: _loadData,
              emptyTitle: 'No return requests found',
              emptyMessage: 'There are no returned products matching your filter criteria.',
              columns: [
                ReturnsTableColumn.product(),
                ReturnsTableColumn.quantity(),
                ReturnsTableColumn.invoice('Invoice #'),
                ReturnsTableColumn.employee(),
                ReturnsTableColumn.branch(),
                ReturnsTableColumn.status(),
                ReturnsTableColumn.action(
                  canReview: canReview,
                  onOpen: (item) => _showDetails(item, canReview),
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
