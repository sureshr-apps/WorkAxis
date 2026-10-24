import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/app/theme/app_typography.dart';
import 'package:workaxis/core/responsive/responsive_layout.dart';
import 'package:workaxis/core/widgets/app_page_header.dart';
import 'package:workaxis/core/widgets/kpi/app_kpi_card.dart';
import 'package:workaxis/core/widgets/kpi/responsive_kpi_section.dart';
import 'package:workaxis/core/widgets/status_chip.dart';
import 'package:workaxis/features/access/presentation/controllers/access_controller.dart';
import 'package:workaxis/features/access/presentation/controllers/branch_context_controller.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';
import 'package:workaxis/features/returns/domain/models/return_item.dart';
import 'package:workaxis/features/returns/presentation/controllers/returns_controller.dart';
import 'package:workaxis/features/returns/presentation/screens/widgets/return_card_item.dart';
import 'package:workaxis/features/returns/presentation/screens/widgets/return_details_dialog.dart';

class ReturnsOperationsScreen extends StatefulWidget {
  const ReturnsOperationsScreen({super.key});

  @override
  State<ReturnsOperationsScreen> createState() => _ReturnsOperationsScreenState();
}

class _ReturnsOperationsScreenState extends State<ReturnsOperationsScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final access = context.read<AccessController>().accessContext;
    if (access == null) return;
    final activeBranchId = context.read<BranchContextController>().activeBranch?.branchId;
    await context.read<ReturnsController>().loadReturns(
      access: access,
      activeBranchId: activeBranchId,
    );
  }

  void _showDetails(ReturnItem item, bool canReview) {
    final access = context.read<AccessController>().accessContext;
    showDialog(
      context: context,
      builder: (ctx) => ReturnDetailsDialog(
        item: item,
        canReview: canReview,
        onReviewDecision: (decision, notes) async {
          final success = await context.read<ReturnsController>().reviewReturn(
            returnId: item.id,
            decision: decision,
            reviewerNotes: notes,
            reviewerName: access?.user.name ?? 'Manager Reviewer',
          );
          if (success && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  decision == ReturnStatus.approved
                      ? 'Return request #${item.id} approved.'
                      : 'Return request #${item.id} rejected.',
                ),
                backgroundColor: decision == ReturnStatus.approved
                    ? AppColors.statusActive
                    : AppColors.statusUrgent,
              ),
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ReturnsController>();
    final access = context.watch<AccessController>().accessContext;
    final branchContext = context.watch<BranchContextController>().activeBranch;
    final role = access?.user.role;
    final isManager = role == UserRole.branchManager;
    final title = isManager ? 'Branch Returns' : 'Organization Returns';
    final subtitle = isManager
        ? 'Review and verify return requests for ${branchContext?.branchName ?? "active branch"}.'
        : 'Verify customer and inventory return requests across all branches.';
    final canReview = role == UserRole.orgAdmin || role == UserRole.branchManager;
    final items = controller.filteredItems;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ResponsivePageContent(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppPageHeader(
                    eyebrow: isManager ? 'Branch Operations' : 'Inventory & Returns',
                    title: title,
                    subtitle: subtitle,
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // KPI Cards
                  ResponsiveKpiSection(
                    cardHeight: 96,
                    cards: [
                      AppKpiCard(
                        title: 'Pending review',
                        value: '${controller.pendingCount}',
                        accentColor: controller.pendingCount > 0 ? AppColors.statusUrgent : null,
                        icon: Icons.pending_actions_outlined,
                        iconColor: controller.pendingCount > 0
                            ? AppColors.statusUrgentText
                            : AppColors.secondary,
                        iconBgColor: controller.pendingCount > 0
                            ? AppColors.statusUrgentContainer
                            : const Color(0xFFF1F5F9),
                        valueColor: controller.pendingCount > 0 ? AppColors.statusUrgentText : null,
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
                        iconBgColor: const Color(0xFFF1F5F9),
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
                  const SizedBox(height: AppSpacing.lg),

                  // Filter Row & Search
                  _buildFilterBar(context, controller),
                  const SizedBox(height: AppSpacing.md),

                  // Main Content: Table or Cards
                  if (controller.isLoading)
                    const Padding(
                      padding: EdgeInsets.all(AppSpacing.xxl),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (controller.errorMessage != null)
                    _buildErrorMessage(controller.errorMessage!)
                  else if (items.isEmpty)
                    _buildEmptyState()
                  else if (!context.isCompact && !context.isMedium)
                    _buildDesktopTable(items, canReview)
                  else if (context.isMedium)
                    _buildTabletGrid(items, canReview)
                  else
                    _buildSmartphoneList(items, canReview),
                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterBar(BuildContext context, ReturnsController controller) {
    final isCompact = context.isCompact;

    final searchField = SizedBox(
      height: 48,
      child: TextField(
        controller: _searchController,
        onChanged: controller.setSearchQuery,
        decoration: InputDecoration(
          hintText: 'Search product, invoice, or employee...',
          prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.onSurfaceVariant),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            borderSide: const BorderSide(color: AppColors.outlineSubtle),
          ),
          filled: true,
          fillColor: AppColors.surfaceContainerLowest,
        ),
      ),
    );

    final statusTabs = SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChip(
            label: 'All (${controller.totalCount})',
            isSelected: controller.statusFilter == null,
            onSelected: () => controller.setFilter(null),
          ),
          const SizedBox(width: AppSpacing.xs),
          _buildFilterChip(
            label: 'Pending (${controller.pendingCount})',
            isSelected: controller.statusFilter == ReturnStatus.pending,
            onSelected: () => controller.setFilter(ReturnStatus.pending),
          ),
          const SizedBox(width: AppSpacing.xs),
          _buildFilterChip(
            label: 'Approved (${controller.approvedCount})',
            isSelected: controller.statusFilter == ReturnStatus.approved,
            onSelected: () => controller.setFilter(ReturnStatus.approved),
          ),
          const SizedBox(width: AppSpacing.xs),
          _buildFilterChip(
            label: 'Rejected (${controller.rejectedCount})',
            isSelected: controller.statusFilter == ReturnStatus.rejected,
            onSelected: () => controller.setFilter(ReturnStatus.rejected),
          ),
        ],
      ),
    );

    if (isCompact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          searchField,
          const SizedBox(height: AppSpacing.sm),
          statusTabs,
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: searchField),
        const SizedBox(width: AppSpacing.md),
        statusTabs,
      ],
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onSelected,
  }) {
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected ? AppColors.onPrimary : AppColors.onSurface,
        ),
      ),
      selected: isSelected,
      onSelected: (_) => onSelected(),
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.surfaceContainerLowest,
      side: BorderSide(
        color: isSelected ? AppColors.primary : AppColors.outlineSubtle,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
    );
  }

  Widget _buildDesktopTable(List<ReturnItem> items, bool canReview) {
    return Card(
      elevation: 0,
      color: AppColors.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        side: const BorderSide(color: AppColors.outlineSubtle),
      ),
      child: Table(
        columnWidths: const {
          0: FlexColumnWidth(3.0), // Product
          1: FlexColumnWidth(1.4), // Quantity
          2: FlexColumnWidth(1.6), // Invoice #
          3: FlexColumnWidth(1.8), // Employee
          4: FlexColumnWidth(1.8), // Branch
          5: FixedColumnWidth(110), // Status
          6: FixedColumnWidth(100), // Action
        },
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        children: [
          TableRow(
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              border: Border(bottom: BorderSide(color: AppColors.outlineSubtle)),
            ),
            children: [
              _headerCell('Product & Reason'),
              _headerCell('Quantity'),
              _headerCell('Invoice #'),
              _headerCell('Requested By'),
              _headerCell('Branch'),
              _headerCell('Status'),
              _headerCell('Action', alignRight: true),
            ],
          ),
          ...items.map((item) {
            return TableRow(
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.outlineSubtle)),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.productTitle,
                        style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        item.reason.label,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.onSurfaceVariant,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 12),
                  child: Text(
                    '${item.quantity % 1 == 0 ? item.quantity.toInt() : item.quantity} ${item.unit}',
                    style: AppTypography.labelMono.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 12),
                  child: Text(
                    item.invoiceNumber,
                    style: AppTypography.labelMono.copyWith(fontSize: 12),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 12),
                  child: Text(item.employeeName, style: AppTypography.bodySmall),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 12),
                  child: Text(item.branchName, style: AppTypography.bodySmall),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 12),
                  child: StatusChip(
                    label: item.status.label,
                    type: item.status.chipType,
                    width: 96,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 12),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => _showDetails(item, canReview),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        minimumSize: const Size(0, 32),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        foregroundColor: AppColors.primary,
                      ),
                      child: Text(
                        canReview && item.status == ReturnStatus.pending ? 'Review' : 'Details >',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                    ),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _headerCell(String title, {bool alignRight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 10),
      child: Text(
        title,
        textAlign: alignRight ? TextAlign.right : TextAlign.left,
        style: AppTypography.labelSmall.copyWith(
          color: AppColors.textMuted,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildTabletGrid(List<ReturnItem> items, bool canReview) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - AppSpacing.md) / 2;
        return Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: items.map((item) {
            return SizedBox(
              width: cardWidth,
              child: ReturnCardItem(
                item: item,
                showReviewAction: canReview,
                onTap: () => _showDetails(item, canReview),
                onReview: () => _showDetails(item, canReview),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildSmartphoneList(List<ReturnItem> items, bool canReview) {
    return Column(
      children: [
        for (final item in items) ...[
          ReturnCardItem(
            item: item,
            showReviewAction: canReview,
            onTap: () => _showDetails(item, canReview),
            onReview: () => _showDetails(item, canReview),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }

  Widget _buildErrorMessage(String msg) {
    return Card(
      elevation: 0,
      color: AppColors.statusUrgentContainer,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          children: [
            const Icon(Icons.cloud_off_outlined, color: AppColors.statusUrgentText, size: 36),
            const SizedBox(height: AppSpacing.sm),
            Text(msg, style: const TextStyle(color: AppColors.statusUrgentText)),
            const SizedBox(height: AppSpacing.sm),
            TextButton(onPressed: _loadData, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          children: [
            const Icon(Icons.assignment_turned_in_outlined, size: 48, color: AppColors.textMuted),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No return requests found',
              style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              'There are no returned products matching your filter criteria.',
              style: AppTypography.bodySmall.copyWith(color: AppColors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
