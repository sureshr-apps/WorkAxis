import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
import 'package:workaxis/features/branches/presentation/screens/widgets/branch_details_dialog.dart';
import 'package:workaxis/features/branches/presentation/screens/widgets/branch_editor_dialog.dart';
import 'package:workaxis/features/branches/presentation/screens/widgets/branch_summary_strip.dart';

class BranchManagementScreen extends StatefulWidget {
  const BranchManagementScreen({super.key});

  @override
  State<BranchManagementScreen> createState() => _BranchManagementScreenState();
}

class _BranchManagementScreenState extends State<BranchManagementScreen> {
  static const double _cardExtent = 252;

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

  Future<void> _load() async {
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
          onRefresh: _load,
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
                  onRetry: _load,
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
              _BranchGrid(
                branches: branches,
                cardExtent:
                    _cardExtent * MediaQuery.textScalerOf(context).scale(1),
                onView: (branch) => _openDetails(branch, access),
                onEdit: access == null
                    ? null
                    : (branch) => _openEditor(access, branch: branch),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
          ],
        ),
      ),
    );
  }

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
    if (saved == true && mounted) await controller.loadBranches(access);
  }

  Future<void> _openDetails(
    BranchRecord branch,
    UserAccessContext? access,
  ) async {
    if (access == null) return;
    final controller = context.read<BranchManagementController>()
      ..clearActionError();
    final details = await controller.getBranch(access, branch.id);
    await controller.loadManagerOptions(access);
    if (!mounted || details == null) return;
    await showDialog<void>(
      context: context,
      builder: (context) => BranchDetailsDialog(
        branch: details,
        managerNames: controller.managerOptions
            .where((option) => details.managerIds.contains(option.id))
            .map((option) => option.name)
            .toList(growable: false),
        onGenerateToken: () =>
            controller.createPairingToken(access: access, branchId: branch.id),
        onCompletePairing: () =>
            controller.completePairing(access: access, branchId: branch.id),
        readActionError: () => controller.actionErrorMessage,
      ),
    );
    if (mounted) await controller.loadBranches(access);
  }
}

class _BranchGrid extends StatelessWidget {
  const _BranchGrid({
    required this.branches,
    required this.cardExtent,
    required this.onView,
    required this.onEdit,
  });

  final List<BranchRecord> branches;
  final double cardExtent;
  final void Function(BranchRecord branch) onView;
  final void Function(BranchRecord branch)? onEdit;

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
        return SliverGrid.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: AppSpacing.md,
            crossAxisSpacing: AppSpacing.md,
            mainAxisExtent: cardExtent,
          ),
          itemCount: branches.length,
          itemBuilder: (context, index) {
            final branch = branches[index];
            return BranchCard(
              branch: branch,
              onView: () => onView(branch),
              onEdit: onEdit == null ? null : () => onEdit!(branch),
            );
          },
        );
      },
    );
  }
}
