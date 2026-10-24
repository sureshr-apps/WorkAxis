import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/core/responsive/responsive_layout.dart';
import 'package:workaxis/core/widgets/app_button.dart';
import 'package:workaxis/core/widgets/app_page_header.dart';
import 'package:workaxis/core/widgets/app_text_field.dart';
import 'package:workaxis/core/widgets/status_chip.dart';
import 'package:workaxis/features/access/presentation/controllers/access_controller.dart';
import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/branches/domain/models/branch_record.dart';
import 'package:workaxis/features/branches/presentation/controllers/branch_management_controller.dart';
import 'package:workaxis/features/branches/presentation/screens/widgets/branch_editor_dialog.dart';

class BranchManagementScreen extends StatefulWidget {
  const BranchManagementScreen({super.key});

  @override
  State<BranchManagementScreen> createState() => _BranchManagementScreenState();
}

class _BranchManagementScreenState extends State<BranchManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
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
    final branches = controller.branches
        .where((branch) {
          final query = _query.trim().toLowerCase();
          return query.isEmpty ||
              '${branch.name} ${branch.code} ${branch.location}'
                  .toLowerCase()
                  .contains(query);
        })
        .toList(growable: false);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ResponsivePageContent(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                    AppPageHeader(
                      eyebrow: 'Organization Operations',
                      title: 'Branch Management',
                      subtitle: 'Configure locations, geofences, managers, and kiosks.',
                      action: AppButton.responsive(
                        text: 'Add Branch',
                        iconData: Icons.add,
                        onPressed: access == null
                            ? null
                            : () => _openEditor(access),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _BranchSummaryStrip(branches: controller.branches),
                    const SizedBox(height: AppSpacing.md),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusMd,
                        ),
                        border: Border.all(color: AppColors.outlineSubtle),
                      ),
                      child: AppTextField.search(
                        controller: _searchController,
                        hintText: 'Search branch name, code, or district',
                        onChanged: (value) => setState(() => _query = value),
                        onClear: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    if (controller.isLoading)
                      const Padding(
                        padding: EdgeInsets.all(AppSpacing.xxl),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (controller.errorMessage != null)
                      _BranchMessage(
                        icon: Icons.cloud_off_outlined,
                        title: 'Branches are unavailable',
                        detail: controller.errorMessage!,
                        action: AppButton.outlined(
                          text: 'Retry',
                          isFullWidth: false,
                          onPressed: _load,
                        ),
                      )
                    else if (branches.isEmpty)
                      _BranchMessage(
                        icon: Icons.store_outlined,
                        title: _query.isEmpty
                            ? 'No branches yet'
                            : 'No matches found',
                        detail: _query.isEmpty
                            ? 'Add a branch to configure its location and operations.'
                            : 'Try a different branch name or code.',
                        action: _query.isEmpty && access != null
                            ? AppButton.secondary(
                                text: 'Add Branch',
                                iconData: Icons.add,
                                isFullWidth: false,
                                onPressed: () => _openEditor(access),
                              )
                            : null,
                      )
                    else
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final columns = context.isCompact
                              ? 1
                              : context.isMedium
                              ? 2
                              : 3;
                          final gap = AppSpacing.md;
                          final width =
                              (constraints.maxWidth - gap * (columns - 1)) /
                              columns;
                          return Wrap(
                            spacing: gap,
                            runSpacing: gap,
                            children: [
                              for (final branch in branches)
                                SizedBox(
                                  width: width,
                                  child: _BranchCard(
                                    branch: branch,
                                    onView: () => _openDetails(branch, access),
                                    onEdit: access == null
                                        ? null
                                        : () => _openEditor(
                                            access,
                                            branch: branch,
                                          ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    const SizedBox(height: AppSpacing.xxl),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

  Future<void> _openEditor(
    UserAccessContext access, {
    BranchRecord? branch,
  }) async {
    final controller = context.read<BranchManagementController>();
    await controller.loadManagerOptions(access);
    if (!mounted) return;
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => BranchEditorDialog(
        branch: branch,
        organizationId: access.organization!.id,
        managerOptions: controller.managerOptions,
        isSaving: controller.isSaving,
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
    final controller = context.read<BranchManagementController>();
    await showDialog<void>(
      context: context,
      builder: (context) => _BranchDetailsDialog(
        branch: branch,
        managerNames: controller.managerOptions
            .where((option) => branch.managerIds.contains(option.id))
            .map((option) => option.name)
            .toList(growable: false),
        onGenerateToken: () =>
            controller.createPairingToken(access: access, branchId: branch.id),
        onCompletePairing: () =>
            controller.completePairing(access: access, branchId: branch.id),
        pairingToken: controller.pairingToken,
        isSaving: controller.isSaving,
      ),
    );
    if (mounted) await controller.loadBranches(access);
  }
}

class _BranchSummaryStrip extends StatelessWidget {
  const _BranchSummaryStrip({required this.branches});

  final List<BranchRecord> branches;

  @override
  Widget build(BuildContext context) {
    final active = branches.where((branch) => branch.isActive).length;
    final paired = branches
        .where((branch) => branch.kioskStatus == KioskPairingStatus.paired)
        .length;
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        _SummaryPill(
          label: '${branches.length} locations',
          icon: Icons.store_outlined,
        ),
        _SummaryPill(label: '$active active', icon: Icons.check_circle_outline),
        _SummaryPill(
          label: '$paired kiosks paired',
          icon: Icons.tablet_android_outlined,
        ),
      ],
    );
  }
}

class _SummaryPill extends StatelessWidget {
  const _SummaryPill({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.md,
      vertical: AppSpacing.sm,
    ),
    decoration: BoxDecoration(
      color: AppColors.surfaceContainerLowest,
      border: Border.all(color: AppColors.outlineSubtle),
      borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.secondary),
        const SizedBox(width: AppSpacing.xs),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ],
    ),
  );
}

class _BranchCard extends StatelessWidget {
  const _BranchCard({
    required this.branch,
    required this.onView,
    required this.onEdit,
  });

  final BranchRecord branch;
  final VoidCallback onView;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final kiosk = switch (branch.kioskStatus) {
      KioskPairingStatus.paired => 'Kiosk paired',
      KioskPairingStatus.pairingPending => 'Pairing in progress',
      KioskPairingStatus.notPaired => 'No kiosk paired',
    };
    return Material(
      color: AppColors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: InkWell(
        onTap: onView,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.outlineSubtle),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      branch.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                      ),
                    ),
                  ),
                  StatusChip.fromStatus(
                    branch.isActive ? 'Active' : 'Inactive',
                    width: 96,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '${branch.code}  ·  ${branch.location}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              const Divider(height: 1, color: AppColors.outlineSubtle),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  const Icon(
                    Icons.badge_outlined,
                    size: 18,
                    color: AppColors.secondary,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      '${branch.activeEmployeeCount} active employees',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  const Icon(Icons.radar, size: 18, color: AppColors.secondary),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      '${branch.geofenceRadiusMeters} m geofence',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.circle,
                    size: 8,
                    color: branch.kioskStatus == KioskPairingStatus.paired
                        ? AppColors.statusActive
                        : AppColors.secondary,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    kiosk,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: AppButton.outlined(
                      text: 'View details',
                      iconData: Icons.visibility_outlined,
                      onPressed: onView,
                    ),
                  ),
                  if (onEdit != null) ...[
                    const SizedBox(width: AppSpacing.sm),
                    Tooltip(
                      message: 'Edit branch',
                      child: FilledButton(
                        onPressed: onEdit,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.onPrimary,
                          minimumSize: const Size(
                            AppSpacing.minTouchTarget,
                            AppSpacing.minTouchTarget,
                          ),
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusSm,
                            ),
                          ),
                        ),
                        child: const Icon(Icons.edit_outlined, size: 18),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BranchMessage extends StatelessWidget {
  const _BranchMessage({
    required this.icon,
    required this.title,
    required this.detail,
    this.action,
  });

  final IconData icon;
  final String title;
  final String detail;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(AppSpacing.xl),
    decoration: BoxDecoration(
      color: AppColors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      border: Border.all(color: AppColors.outlineSubtle),
    ),
    child: Column(
      children: [
        Icon(icon, size: 32, color: AppColors.secondary),
        const SizedBox(height: AppSpacing.sm),
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          detail,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.onSurfaceVariant),
        ),
        if (action != null) ...[const SizedBox(height: AppSpacing.md), action!],
      ],
    ),
  );
}

class _BranchDetailsDialog extends StatefulWidget {
  const _BranchDetailsDialog({
    required this.branch,
    required this.managerNames,
    required this.onGenerateToken,
    required this.onCompletePairing,
    required this.pairingToken,
    required this.isSaving,
  });

  final BranchRecord branch;
  final List<String> managerNames;
  final Future<Object?> Function() onGenerateToken;
  final Future<bool> Function() onCompletePairing;
  final KioskPairingToken? pairingToken;
  final bool isSaving;

  @override
  State<_BranchDetailsDialog> createState() => _BranchDetailsDialogState();
}

class _BranchDetailsDialogState extends State<_BranchDetailsDialog> {
  KioskPairingToken? _token;
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    final branch = widget.branch;
    final kioskLabel = _token != null
        ? 'Pairing in progress'
        : switch (branch.kioskStatus) {
            KioskPairingStatus.paired => 'Paired',
            KioskPairingStatus.pairingPending => 'Pairing in progress',
            KioskPairingStatus.notPaired => 'Not paired',
          };
    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _DetailRow(label: 'Branch code', value: branch.code),
        _DetailRow(label: 'Location', value: branch.location),
        _DetailRow(
          label: 'Status',
          value: branch.isActive ? 'Active' : 'Inactive',
        ),
        _DetailRow(
          label: 'Active employees',
          value: '${branch.activeEmployeeCount}',
        ),
        _DetailRow(
          label: 'Geofence radius',
          value: '${branch.geofenceRadiusMeters} metres',
        ),
        _DetailRow(
          label: 'Coordinates',
          value: '${branch.latitude}, ${branch.longitude}',
        ),
        _DetailRow(label: 'Kiosk terminal', value: kioskLabel),
        _DetailRow(
          label: 'Branch managers',
          value: widget.managerNames.isEmpty
              ? 'Unassigned'
              : widget.managerNames.join(', '),
        ),
        if (_token != null) ...[
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.key_outlined,
                  color: AppColors.onPrimaryContainer,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: SelectableText(
                    _token!.value,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          const Text(
            'This mock pairing code is shown once and is not stored.',
            style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
          ),
        ],
      ],
    );
    final actions = [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Close'),
      ),
      if (_token == null && branch.kioskStatus != KioskPairingStatus.paired)
        AppButton.secondary(
          text: 'Generate pairing code',
          isLoading: _isSaving,
          onPressed: _generateToken,
        ),
      if (_token != null)
        AppButton.primary(
          text: 'Mark terminal paired',
          isLoading: _isSaving,
          onPressed: _completePairing,
        ),
    ];
    if (context.isCompact) {
      return Dialog.fullscreen(
        child: Scaffold(
          appBar: AppBar(title: const Text('Branch details')),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    branch.name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  details,
                ],
              ),
            ),
          ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(mainAxisSize: MainAxisSize.min, children: actions),
            ),
          ),
        ),
      );
    }
    return AlertDialog(
      title: Text(branch.name),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(child: details),
      ),
      actions: actions,
    );
  }

  Future<void> _generateToken() async {
    setState(() => _isSaving = true);
    final result = await widget.onGenerateToken();
    if (mounted) {
      setState(() {
        _token = result is KioskPairingToken ? result : null;
        _isSaving = false;
      });
    }
  }

  Future<void> _completePairing() async {
    setState(() => _isSaving = true);
    final paired = await widget.onCompletePairing();
    if (mounted) {
      setState(() => _isSaving = false);
      if (paired) Navigator.of(context).pop();
    }
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 150,
          child: Text(
            label,
            style: const TextStyle(color: AppColors.onSurfaceVariant),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
      ],
    ),
  );
}
