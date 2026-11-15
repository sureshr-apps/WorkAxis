import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:workaxis/app/routing/app_routes.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/core/responsive/responsive_layout.dart';
import 'package:workaxis/core/widgets/app_button.dart';
import 'package:workaxis/core/widgets/app_page_header.dart';
import 'package:workaxis/core/widgets/error_state.dart';
import 'package:workaxis/core/widgets/page_breadcrumb.dart';
import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/access/presentation/controllers/access_controller.dart';
import 'package:workaxis/features/branches/domain/models/branch_record.dart';
import 'package:workaxis/features/branches/presentation/controllers/branch_management_controller.dart';
import 'package:workaxis/features/branches/presentation/screens/widgets/branch_details_view.dart';
import 'package:workaxis/shared/widgets/dashboard_surface_card.dart';

/// Full page for one branch, reached from Branch Management. Kiosk pairing
/// actions live here; the pairing code is shown once and never stored.
class BranchDetailsScreen extends StatefulWidget {
  const BranchDetailsScreen({super.key, required this.branchId});

  final String branchId;

  @override
  State<BranchDetailsScreen> createState() => _BranchDetailsScreenState();
}

class _BranchDetailsScreenState extends State<BranchDetailsScreen> {
  BranchRecord? _branch;
  List<String> _managerNames = const [];
  KioskPairingToken? _token;
  bool _loading = true;
  bool _isSaving = false;
  String? _error;

  UserAccessContext? get _access =>
      context.read<AccessController>().accessContext;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  @override
  void didUpdateWidget(covariant BranchDetailsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.branchId != widget.branchId) _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _isSaving = false;
      _token = null;
      _error = null;
    });
    final access = _access;
    final controller = context.read<BranchManagementController>()
      ..clearActionError();
    final branch = access == null
        ? null
        : await controller.getBranch(access, widget.branchId);
    if (access != null) await controller.loadManagerOptions(access);
    if (!mounted) return;
    setState(() {
      _branch = branch;
      _managerNames = branch == null
          ? const []
          : controller.managerOptions
                .where((option) => branch.managerIds.contains(option.id))
                .map((option) => option.name)
                .toList(growable: false);
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.surface,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final branch = _branch;
    if (branch == null) return _notFound();
    final actions = _kioskActions(branch);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          child: ResponsivePageContent(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PageBreadcrumb(
                  backLabel: 'Branch Management',
                  currentLabel: branch.name,
                  onBack: () => context.go(AppRoutes.orgAdminBranches),
                ),
                const SizedBox(height: AppSpacing.md),
                const AppPageHeader(
                  eyebrow: 'Organization Operations',
                  title: 'Branch details',
                  subtitle:
                      'Location, geofence and kiosk pairing for this branch.',
                ),
                const SizedBox(height: AppSpacing.lg),
                DashboardSurfaceCard(
                  child: BranchDetailsView(
                    branch: branch,
                    managerNames: _managerNames,
                    token: _token,
                    error: _error,
                  ),
                ),
                if (actions.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.lg),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: actions,
                  ),
                ],
                const SizedBox(height: AppSpacing.xxl),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _kioskActions(BranchRecord branch) {
    final isCompact = context.isCompact;
    return [
      if (_token == null && branch.kioskStatus != KioskPairingStatus.paired)
        AppButton.secondary(
          text: 'Generate pairing code',
          isFullWidth: isCompact,
          isLoading: _isSaving,
          onPressed: _generateToken,
        ),
      if (_token != null)
        AppButton.primary(
          text: 'Mark terminal paired',
          isFullWidth: isCompact,
          isLoading: _isSaving,
          onPressed: _completePairing,
        ),
    ];
  }

  Future<void> _generateToken() async {
    final access = _access;
    final branch = _branch;
    if (access == null || branch == null) return;
    final controller = context.read<BranchManagementController>();
    setState(() {
      _isSaving = true;
      _error = null;
    });
    final token = await controller.createPairingToken(
      access: access,
      branchId: branch.id,
    );
    if (!mounted) return;
    setState(() {
      _token = token;
      _isSaving = false;
      if (token == null) {
        _error =
            controller.actionErrorMessage ??
            'A pairing code could not be generated.';
      }
    });
  }

  Future<void> _completePairing() async {
    final access = _access;
    final branch = _branch;
    if (access == null || branch == null) return;
    final controller = context.read<BranchManagementController>();
    setState(() {
      _isSaving = true;
      _error = null;
    });
    final paired = await controller.completePairing(
      access: access,
      branchId: branch.id,
    );
    if (!mounted) return;
    if (paired) {
      // Reload so the kiosk status shown is the saved one.
      await _load();
      return;
    }
    setState(() {
      _isSaving = false;
      _error =
          controller.actionErrorMessage ?? 'The kiosk could not be paired.';
    });
  }

  Widget _notFound() {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: ResponsivePageContent(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PageBreadcrumb(
                backLabel: 'Branch Management',
                currentLabel: 'Branch',
                onBack: () => context.go(AppRoutes.orgAdminBranches),
              ),
              const SizedBox(height: AppSpacing.md),
              ErrorState(
                message: 'This branch could not be found.',
                onRetry: _load,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
