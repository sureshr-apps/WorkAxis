import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/app/theme/app_typography.dart';
import 'package:workaxis/core/responsive/responsive_layout.dart';
import 'package:workaxis/core/widgets/app_button.dart';
import 'package:workaxis/core/widgets/async_confirmation_dialog.dart';
import 'package:workaxis/core/widgets/app_page_header.dart';
import 'package:workaxis/core/widgets/app_text_field.dart';
import 'package:workaxis/core/widgets/empty_state.dart';
import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/access/presentation/controllers/access_controller.dart';
import 'package:workaxis/features/access/presentation/controllers/branch_context_controller.dart';
import 'package:workaxis/features/assets/domain/models/asset_queue.dart';
import 'package:workaxis/features/assets/domain/models/employee_asset.dart';
import 'package:workaxis/features/assets/presentation/controllers/assets_controller.dart';
import 'package:workaxis/features/assets/presentation/widgets/asset_editor_dialog.dart';
import 'package:workaxis/features/assets/presentation/widgets/employee_asset_card.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';

class AssetsScreen extends StatefulWidget {
  const AssetsScreen({super.key});

  @override
  State<AssetsScreen> createState() => _AssetsScreenState();
}

class _AssetsScreenState extends State<AssetsScreen> {
  final _searchController = TextEditingController();
  String? _loadedScope;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final access = Provider.of<AccessController>(context).accessContext;
    final branches = Provider.of<BranchContextController>(context);
    if (access == null) return;

    final role = access.user.role;
    final activeBranchId = role == UserRole.branchManager
        ? branches.activeBranch?.branchId
        : null;
    final scope =
        '${access.user.id}:${access.organization?.id}:$activeBranchId';
    if (_loadedScope == scope) return;
    _loadedScope = scope;
    _searchController.clear();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _loadedScope != scope) return;
      unawaited(
        context.read<AssetsController>().load(
          access,
          activeBranchId: activeBranchId,
          // The search box was cleared for the new scope; match it.
          query: '',
        ),
      );
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final access = context.watch<AccessController>().accessContext;
    final branchContext = context.watch<BranchContextController>();
    final controller = context.watch<AssetsController>();
    if (access == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final role = access.user.role;
    final isEmployee = role == UserRole.employee;
    final isManager = role == UserRole.branchManager;
    final canEdit = role == UserRole.orgAdmin || isManager;
    final activeBranchId = isManager
        ? branchContext.activeBranch?.branchId
        : null;
    final activeBranches = branchContext.assignedBranches.where(
      (branch) => branch.id == activeBranchId,
    );
    final activeBranch = isManager && activeBranches.isNotEmpty
        ? activeBranches.first
        : null;
    final visibleAssets = controller.assets;
    final isOwnQueue = controller.queue == AssetQueue.mine;
    final canAddHere = canEdit && !(isManager && isOwnQueue);
    final padding = context.responsivePagePadding;
    Widget buildAssetCard(EmployeeAsset asset) {
      final canManageAsset =
          canEdit &&
          !(isManager &&
              (asset.employeeUid == access.user.id ||
                  asset.branchId != activeBranchId));
      return EmployeeAssetCard(
        asset: asset,
        canEdit: canManageAsset,
        isEmployeeView: isEmployee,
        canAcknowledge: isEmployee,
        isAcknowledging: controller.isAcknowledging,
        onEdit: canManageAsset
            ? () {
                _openEditor(
                  access: access,
                  controller: controller,
                  activeBranchId: activeBranchId,
                  asset: asset,
                );
              }
            : null,
        onDelete: canManageAsset
            ? () {
                _confirmDelete(
                  access: access,
                  controller: controller,
                  activeBranchId: activeBranchId,
                  asset: asset,
                );
              }
            : null,
        onAcknowledge:
            isEmployee &&
                asset.status != AssetStatus.returned &&
                asset.acknowledgementRequired &&
                asset.acknowledgementStatus ==
                    AssetAcknowledgementStatus.pending
            ? () {
                _confirmReceipt(
                  access: access,
                  controller: controller,
                  asset: asset,
                );
              }
            : null,
      );
    }

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                padding.left,
                padding.top,
                padding.right,
                AppSpacing.md,
              ),
              sliver: SliverList.list(
                children: [
                  AppPageHeader(
                    eyebrow: 'Inventory',
                    title: 'Assets',
                    subtitle: _subtitle(role, activeBranch?.name),
                    action: canEdit
                        ? AppButton.responsive(
                            text: 'Add asset',
                            iconData: Icons.add,
                            onPressed: () {
                              _openEditor(
                                access: access,
                                controller: controller,
                                activeBranchId: activeBranchId,
                              );
                            },
                          )
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppTextField.search(
                    controller: _searchController,
                    hintText: isEmployee
                        ? 'Search your assets'
                        : 'Search assets, employees, or tags',
                    onChanged: (value) => unawaited(
                      controller.setQuery(
                        access,
                        value,
                        activeBranchId: activeBranchId,
                      ),
                    ),
                  ),
                  if (isManager) ...[
                    const SizedBox(height: AppSpacing.md),
                    SegmentedButton<AssetQueue>(
                      segments: const [
                        ButtonSegment(
                          value: AssetQueue.mine,
                          label: Text('My assets'),
                          icon: Icon(Icons.person_outline),
                        ),
                        ButtonSegment(
                          value: AssetQueue.branchEmployees,
                          label: Text('Employee assets'),
                          icon: Icon(Icons.groups_outlined),
                        ),
                      ],
                      selected: {controller.queue ?? AssetQueue.mine},
                      onSelectionChanged: (selection) => unawaited(
                        controller.setQueue(
                          access,
                          selection.first,
                          activeBranchId: activeBranchId,
                        ),
                      ),
                    ),
                  ],
                  if (controller.actionErrorMessage != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    _ActionError(
                      message: controller.actionErrorMessage!,
                      onDismiss: controller.clearActionError,
                    ),
                  ],
                  if (controller.isLoading && controller.assets.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.md),
                    const LinearProgressIndicator(),
                  ],
                  if (!controller.isLoading &&
                      controller.errorMessage == null) ...[
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      '${controller.totalCount} ${controller.totalCount == 1 ? 'asset' : 'assets'}',
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (controller.isLoading && controller.assets.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (controller.errorMessage != null &&
                controller.assets.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _LoadError(
                  message: controller.errorMessage!,
                  onRetry: () => unawaited(
                    controller.load(access, activeBranchId: activeBranchId),
                  ),
                ),
              )
            else if (visibleAssets.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _EmptyAssets(
                  hasSearch: controller.query.trim().isNotEmpty,
                  isEmployee: isEmployee,
                  canEdit: canAddHere,
                  onAdd: canAddHere
                      ? () => _openEditor(
                          access: access,
                          controller: controller,
                          activeBranchId: activeBranchId,
                        )
                      : null,
                  onClearSearch: () {
                    _searchController.clear();
                    unawaited(
                      controller.setQuery(
                        access,
                        '',
                        activeBranchId: activeBranchId,
                      ),
                    );
                  },
                ),
              )
            else ...[
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  padding.left,
                  0,
                  padding.right,
                  controller.hasMore ? AppSpacing.md : padding.bottom,
                ),
                sliver: context.isExpanded
                    ? SliverGrid(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) =>
                              buildAssetCard(visibleAssets[index]),
                          childCount: visibleAssets.length,
                        ),
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 440,
                              mainAxisExtent: 420,
                              mainAxisSpacing: AppSpacing.md,
                              crossAxisSpacing: AppSpacing.md,
                            ),
                      )
                    : SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final isLast = index == visibleAssets.length - 1;
                          return Padding(
                            padding: EdgeInsets.only(
                              bottom: isLast ? 0 : AppSpacing.md,
                            ),
                            child: buildAssetCard(visibleAssets[index]),
                          );
                        }, childCount: visibleAssets.length),
                      ),
              ),
              if (controller.hasMore)
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    padding.left,
                    0,
                    padding.right,
                    padding.bottom,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: Center(
                      child: AppButton.outlined(
                        text: 'Load more',
                        isFullWidth: false,
                        isLoading: controller.isLoadingMore,
                        onPressed: () => unawaited(
                          controller.loadMore(
                            access,
                            activeBranchId: activeBranchId,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  String _subtitle(UserRole role, String? activeBranchName) => switch (role) {
    UserRole.employee => 'View the assets currently assigned to you.',
    UserRole.branchManager =>
      activeBranchName == null
          ? 'View and manage assets for employees at your active outlet.'
          : 'View and manage assets assigned to employees at $activeBranchName.',
    UserRole.orgAdmin =>
      'View and manage assets assigned to employees across your organization.',
    UserRole.platformOwner || UserRole.platformAdmin =>
      'Assets are available to customer organization users.',
  };

  Future<void> _openEditor({
    required UserAccessContext access,
    required AssetsController controller,
    required String? activeBranchId,
    EmployeeAsset? asset,
  }) async {
    final organizationId = access.organization?.id;
    if (organizationId == null) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AssetEditorDialog(
        organizationId: organizationId,
        branches: access.assignedBranches,
        employees: controller.members,
        canAssignManagers: access.user.role == UserRole.orgAdmin,
        asset: asset,
        fixedBranchId: access.user.role == UserRole.branchManager
            ? activeBranchId
            : null,
        onSave: (draft) =>
            controller.saveAsset(access, draft, activeBranchId: activeBranchId),
        actionErrorMessage: () => controller.actionErrorMessage,
      ),
    );
  }

  Future<void> _confirmDelete({
    required UserAccessContext access,
    required AssetsController controller,
    required String? activeBranchId,
    required EmployeeAsset asset,
  }) async {
    controller.clearActionError();
    final deleted = await showAsyncConfirmationDialog(
      context: context,
      title: 'Delete asset?',
      content: Text(
        'Remove ${asset.name} (${asset.assetTag}) from the asset register?',
      ),
      confirmLabel: 'Delete',
      destructive: true,
      onConfirm: () async {
        controller.clearActionError();
        return controller.deleteAsset(
          access,
          asset,
          activeBranchId: activeBranchId,
        );
      },
      failureMessage: () => controller.actionErrorMessage,
    );
    if (!deleted || !mounted) return;
  }

  Future<void> _confirmReceipt({
    required UserAccessContext access,
    required AssetsController controller,
    required EmployeeAsset asset,
  }) async {
    controller.clearActionError();
    final acknowledged = await showAsyncConfirmationDialog(
      context: context,
      title: 'Confirm asset receipt?',
      content: Text(
        'Confirm that you received ${asset.name} (${asset.assetTag}). '
        'Your acknowledgment will be recorded.',
      ),
      confirmLabel: 'Confirm receipt',
      onConfirm: () async {
        controller.clearActionError();
        return controller.acknowledgeAsset(access, asset);
      },
      failureMessage: () => controller.actionErrorMessage,
    );
    if (!acknowledged || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Receipt acknowledged for ${asset.name}.')),
    );
  }
}

class _EmptyAssets extends StatelessWidget {
  const _EmptyAssets({
    required this.hasSearch,
    required this.isEmployee,
    required this.canEdit,
    this.onAdd,
    required this.onClearSearch,
  });

  final bool hasSearch;
  final bool isEmployee;
  final bool canEdit;
  final VoidCallback? onAdd;
  final VoidCallback onClearSearch;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(AppSpacing.xl),
    child: EmptyState(
      icon: hasSearch ? Icons.search_off : Icons.inventory_2_outlined,
      title: hasSearch
          ? 'No matching assets'
          : (isEmployee ? 'No assets assigned yet' : 'No assets yet'),
      message: hasSearch
          ? 'Try another name, employee, or asset tag.'
          : (isEmployee
                ? 'Assets assigned to you will appear here.'
                : 'Add an asset and assign it to an employee at an outlet.'),
      action: hasSearch
          ? AppButton.outlined(
              text: 'Clear search',
              isFullWidth: false,
              onPressed: onClearSearch,
            )
          : (canEdit
                ? AppButton.primary(
                    text: 'Add asset',
                    iconData: Icons.add,
                    isFullWidth: false,
                    onPressed: onAdd,
                  )
                : null),
    ),
  );
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.message, required this.onRetry});

  final String message;
  final FutureOr<void> Function() onRetry;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(AppSpacing.xl),
    child: EmptyState(
      icon: Icons.cloud_off_outlined,
      title: 'Assets could not be loaded',
      message: message,
      action: AppButton.outlined(
        text: 'Try again',
        iconData: Icons.refresh,
        isFullWidth: false,
        onPressed: onRetry,
      ),
    ),
  );
}

class _ActionError extends StatelessWidget {
  const _ActionError({required this.message, required this.onDismiss});

  final String message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: AppColors.statusUrgentContainer,
      borderRadius: AppSpacing.roundedSm,
    ),
    child: Row(
      children: [
        Expanded(
          child: Text(
            message,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.statusUrgentText,
            ),
          ),
        ),
        IconButton(
          tooltip: 'Dismiss',
          onPressed: onDismiss,
          icon: const Icon(Icons.close),
        ),
      ],
    ),
  );
}
