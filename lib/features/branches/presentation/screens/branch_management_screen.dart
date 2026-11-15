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
import 'package:workaxis/features/branches/presentation/screens/widgets/branch_card.dart';
import 'package:workaxis/features/branches/presentation/screens/widgets/branch_editor_dialog.dart';
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
                      onPressed: access == null
                          ? null
                          : () => _openEditor(access),
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
                          onPressed: () => _openEditor(access),
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
                    : (branch) => _openEditor(access, branch: branch),
                onToggleActive: access == null
                    ? null
                    : (branch) => _toggleActive(access, branch),
                onDelete: access == null
                    ? null
                    : (branch) => _confirmDelete(access, branch),
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

  Future<void> _openEditor(
    UserAccessContext access, {
    BranchRecord? branch,
  }) async {
    final organizationId = access.organization?.id;
    if (organizationId == null) return;
    final controller = context.read<BranchManagementController>()
      ..clearActionError();
    await controller.loadManagerOptions(access);
    final editable = branch == null
        ? null
        : await controller.getBranch(access, branch.id);
    if (!mounted || (branch != null && editable == null)) return;
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => BranchEditorDialog(
        branch: editable,
        organizationId: organizationId,
        managerOptions: controller.managerOptions,
        isSaving: controller.isSaving,
        readActionError: () => controller.actionErrorMessage,
        onSave: (record) =>
            controller.saveBranch(access: access, branch: record),
      ),
    );
    if (saved == true && mounted) {
      await context.read<AccessController>().refreshAccess();
      if (!mounted) return;
      final freshAccess =
          context.read<AccessController>().accessContext ?? access;
      await controller.loadBranches(freshAccess);
    }
  }

  /// Suspends an active branch or reactivates a suspended one, by saving the
  /// branch with its flag flipped.
  Future<void> _toggleActive(
    UserAccessContext access,
    BranchRecord branch,
  ) async {
    final controller = context.read<BranchManagementController>()
      ..clearActionError();
    final current = await controller.getBranch(access, branch.id);
    if (!mounted || current == null) return;
    final suspending = current.isActive;
    final updated = await controller.saveBranch(
      access: access,
      branch: current.copyWith(
        summary: current.summary.copyWith(isActive: !suspending),
      ),
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${branch.name}?'),
        content: const Text(
          'The branch is removed for good. A branch with employees, returns '
          'or attendance cannot be deleted; suspend it instead.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.statusUrgentText,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final controller = context.read<BranchManagementController>()
      ..clearActionError();
    final deleted = await controller.deleteBranch(
      access: access,
      branchId: branch.id,
    );
    if (!mounted) return;
    if (deleted) {
      await context.read<AccessController>().refreshAccess();
      if (!mounted) return;
      _toast('${branch.name} deleted.');
    } else {
      _toast(
        controller.actionErrorMessage ??
            'The branch could not be deleted. Try again.',
      );
    }
  }

  void _openDetails(BranchRecord branch) =>
      context.push(AppRoutes.orgAdminBranchDetailsPath(branch.id));
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
  final void Function(BranchRecord branch)? onEdit;
  final void Function(BranchRecord branch)? onToggleActive;
  final void Function(BranchRecord branch)? onDelete;

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
