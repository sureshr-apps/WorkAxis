import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:workaxis/app/routing/app_routes.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/core/constants/app_breakpoints.dart';
import 'package:workaxis/core/responsive/responsive_sliver_page.dart';
import 'package:workaxis/core/widgets/app_button.dart';
import 'package:workaxis/core/widgets/app_page_header.dart';
import 'package:workaxis/core/widgets/app_text_field.dart';
import 'package:workaxis/core/widgets/empty_state.dart';
import 'package:workaxis/core/widgets/error_banner.dart';
import 'package:workaxis/core/widgets/error_state.dart';
import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/access/presentation/controllers/access_controller.dart';
import 'package:workaxis/features/branches/domain/models/branch_record.dart';
import 'package:workaxis/features/branches/presentation/controllers/branch_management_controller.dart';
import 'package:workaxis/features/branches/presentation/widgets/branch_delete_dialog.dart';
import 'package:workaxis/features/branches/presentation/screens/widgets/branch_card.dart';
import 'package:workaxis/features/branches/presentation/screens/widgets/branch_summary_strip.dart';

class BranchManagementScreen extends StatefulWidget {
  const BranchManagementScreen({super.key});

  @override
  State<BranchManagementScreen> createState() => _BranchManagementScreenState();
}

class _BranchManagementScreenState extends State<BranchManagementScreen> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    // Seed from the controller so an applied filter is always visible.
    _searchController = TextEditingController(
      text: context.read<BranchManagementController>().searchQuery,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Entry loads reuse recently resolved access; pull-to-refresh and retry
  /// pass [force] to re-resolve it.
  Future<void> _load({bool force = false}) async {
    await context.read<AccessController>().refreshAccess(force: force);
    if (!mounted) return;
    final access = context.read<AccessController>().accessContext;
    if (access == null) return;
    final controller = context.read<BranchManagementController>();
    await controller.loadBranches(access);
    await controller.loadManagerOptions(access);
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<BranchManagementController>();
    final access = context.watch<AccessController>().accessContext;
    final branches = controller.filteredBranches;
    final hasQuery = controller.searchQuery.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: ResponsiveSliverPage(
          onRefresh: () => _load(force: true),
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppPageHeader(
                    eyebrow: 'Organization Operations',
                    title: 'Branch Management',
                    subtitle:
                        'Configure locations, geofences, managers, and kiosks.',
                    action: AppButton.responsive(
                      text: 'Add Branch',
                      iconData: Icons.add,
                      onPressed: access == null ? null : () => _openEditor(),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  BranchSummaryStrip(branches: controller.branches),
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLowest,
                      borderRadius: AppSpacing.roundedMd,
                      border: Border.all(color: AppColors.outlineSubtle),
                    ),
                    child: AppTextField.search(
                      controller: _searchController,
                      hintText: 'Search branch name, code, or district',
                      onChanged: controller.setSearchQuery,
                    ),
                  ),
                  if (controller.actionErrorMessage != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    ErrorBanner(
                      message: controller.actionErrorMessage!,
                      onDismiss: controller.clearActionError,
                    ),
                  ],
                  const SizedBox(height: AppSpacing.md),
                ],
              ),
            ),
            if (controller.isLoading)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.xxl),
                  child: Center(child: CircularProgressIndicator()),
                ),
              )
            else if (controller.errorMessage != null)
              SliverToBoxAdapter(
                child: ErrorState(
                  message: controller.errorMessage!,
                  onRetry: () => _load(force: true),
                ),
              )
            else if (branches.isEmpty)
              SliverToBoxAdapter(
                child: EmptyState(
                  icon: Icons.store_outlined,
                  title: hasQuery ? 'No matches found' : 'No branches yet',
                  message: hasQuery ? 'Try a different branch name or code.' : 'Add a branch to configure its location and operations.',
                  action: !hasQuery && access != null
                      ? AppButton.secondary(
                          text: 'Add Branch',
                          iconData: Icons.add,
                          isFullWidth: false,
                          onPressed: () {
                            _openEditor();
                          },
                        )
                      : null,
                ),
              )
            else
              _BranchList(
                branches: branches,
                onOpen: _openDetails,
                onEdit: access == null
                    ? null
                    : (branch) => _openEditor(branch: branch),
                onToggleActive: access == null
                    ? null
                    : (branch) => _toggleActive(access, branch),
                onDelete: access == null
                    ? null
                    : (branch) {
                        _confirmDelete(access, branch);
                      },
              ),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
          ],
        ),
      ),
    );
  }

  void _toast(String message) =>
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));

  /// Add and edit are routed pages; the list reloads when it is shown again.
  void _openEditor({BranchRecord? branch}) {
    context.push(
      branch == null
          ? AppRoutes.orgAdminBranchAddPath
          : AppRoutes.orgAdminBranchEditPath(branch.id),
    );
  }

  /// Suspends an active branch or reactivates a suspended one.
  Future<void> _toggleActive(
    UserAccessContext access,
    BranchRecord branch,
  ) async {
    final controller = context.read<BranchManagementController>()
      ..clearActionError();
    final suspending = branch.isActive;
    final updated = await controller.setBranchActive(
      access: access,
      branchId: branch.id,
      isActive: !suspending,
    );
    if (!mounted) return;
    _toast(
      updated == null
          ? controller.actionErrorMessage ??
                'The branch could not be updated. Try again.'
          : suspending
          ? '${branch.name} suspended.'
          : '${branch.name} reactivated.',
    );
  }

  Future<void> _confirmDelete(
    UserAccessContext access,
    BranchRecord branch,
  ) async {
    final controller = context.read<BranchManagementController>()
      ..clearActionError();
    final deleted = await confirmBranchDelete(
      context,
      branch,
      onConfirm: () async {
        controller.clearActionError();
        return await controller.deleteBranch(
          access: access,
          branchId: branch.id,
        );
      },
      failureMessage: () => controller.actionErrorMessage,
    );
    if (!deleted || !mounted) return;
    await context.read<AccessController>().refreshAccess();
    if (!mounted) return;
    _toast('${branch.name} deleted.');
  }

  void _openDetails(BranchRecord branch) {
    context.push(AppRoutes.orgAdminBranchDetailsPath(branch.id));
  }
}

/// Branch cards in one or more columns, sized to their content like the plan
/// cards. Rows are built lazily.
class _BranchList extends StatelessWidget {
  const _BranchList({
    required this.branches,
    required this.onOpen,
    required this.onEdit,
    required this.onToggleActive,
    required this.onDelete,
  });

  final List<BranchRecord> branches;
  final void Function(BranchRecord branch) onOpen;
  final FutureOr<void> Function(BranchRecord branch)? onEdit;
  final FutureOr<void> Function(BranchRecord branch)? onToggleActive;
  final FutureOr<void> Function(BranchRecord branch)? onDelete;

  @override
  Widget build(BuildContext context) {
    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.crossAxisExtent;
        final columns = width < AppBreakpoints.mediumMin
            ? 1
            : width < AppBreakpoints.wideContent
            ? 2
            : 3;
        final rowCount = (branches.length / columns).ceil();
        return SliverList.separated(
          itemCount: rowCount,
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
          itemBuilder: (context, row) {
            Widget cardAt(int index) {
              final branch = branches[index];
              return BranchCard(
                branch: branch,
                onOpen: () => onOpen(branch),
                onEdit: onEdit == null ? null : () => onEdit!(branch),
                onToggleActive: onToggleActive == null
                    ? null
                    : () => onToggleActive!(branch),
                onDelete: onDelete == null ? null : () => onDelete!(branch),
              );
            }

            if (columns == 1) return cardAt(row);

            final cells = <Widget>[];
            for (var col = 0; col < columns; col++) {
              final index = row * columns + col;
              if (col > 0) cells.add(const SizedBox(width: AppSpacing.md));
              cells.add(
                Expanded(
                  child: index < branches.length
                      ? cardAt(index)
                      : const SizedBox.shrink(),
                ),
              );
            }
            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: cells,
              ),
            );
          },
        );
      },
    );
  }
}
