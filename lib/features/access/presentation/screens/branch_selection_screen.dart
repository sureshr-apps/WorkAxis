import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:workaxis/app/routing/app_routes.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/app/theme/app_typography.dart';
import 'package:workaxis/core/constants/app_breakpoints.dart';
import 'package:workaxis/core/responsive/responsive_container.dart';
import 'package:workaxis/core/widgets/app_text_field.dart';
import 'package:workaxis/features/access/domain/models/branch_summary.dart';
import 'package:workaxis/features/access/presentation/controllers/access_controller.dart';
import 'package:workaxis/features/access/presentation/controllers/branch_context_controller.dart';
import 'package:workaxis/features/access/presentation/screens/widgets/branch_list_tile.dart';
import 'package:workaxis/features/authentication/presentation/controllers/auth_controller.dart';

/// Branch Selection screen for Branch Managers with multiple assigned branches.
///
/// Follows the refined compact smartphone layout from Stitch project 600623576580245702.
class BranchSelectionScreen extends StatefulWidget {
  const BranchSelectionScreen({super.key});

  @override
  State<BranchSelectionScreen> createState() => _BranchSelectionScreenState();
}

class _BranchSelectionScreenState extends State<BranchSelectionScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onBranchSelected(BranchSummary branch) {
    final branchController = context.read<BranchContextController>();
    final success = branchController.selectBranch(branch);
    if (success && mounted) {
      context.go(AppRoutes.branchManagerWorkspace);
    }
  }

  Future<void> _handleSignOut() async {
    final authController = context.read<AuthController>();
    final accessController = context.read<AccessController>();
    final branchController = context.read<BranchContextController>();

    await authController.signOut();
    accessController.clear();
    branchController.clear();

    if (mounted) {
      context.go(AppRoutes.signIn);
    }
  }

  @override
  Widget build(BuildContext context) {
    final branchController = context.watch<BranchContextController>();
    final assignedBranches = branchController.assignedBranches;

    final filteredBranches = assignedBranches.where((branch) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return branch.name.toLowerCase().contains(q) ||
          branch.code.toLowerCase().contains(q) ||
          branch.location.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(
          'Branch Selection',
          style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            tooltip: 'Sign Out',
            icon: const Icon(Icons.logout_rounded),
            onPressed: _handleSignOut,
          ),
        ],
      ),
      body: SafeArea(
        child: ResponsiveContainer(
          maxWidth: AppBreakpoints.maxFormCardWidth + 120,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Compact Header Area
              Text(
                'Select Branch',
                style: AppTypography.headlineMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Choose the active branch context for your operational workspace.',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Search Field
              AppTextField(
                controller: _searchController,
                hintText: 'Search branch by name, code, or location',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                onChanged: (value) =>
                    setState(() => _searchQuery = value.trim()),
              ),
              const SizedBox(height: AppSpacing.md),

              // Branch Count Metadata
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xs,
                  vertical: AppSpacing.xs,
                ),
                child: Text(
                  '${filteredBranches.length} ${filteredBranches.length == 1 ? "branch" : "branches"} available',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),

              // Branch List
              Expanded(
                child: filteredBranches.isEmpty
                    ? _buildEmptyState()
                    : ListView.separated(
                        itemCount: filteredBranches.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: AppSpacing.sm),
                        itemBuilder: (context, index) {
                          final branch = filteredBranches[index];
                          return BranchListTile(
                            branch: branch,
                            onTap: () => _onBranchSelected(branch),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.search_off_rounded,
              size: 48,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No branches found',
              style: AppTypography.titleMedium.copyWith(
                color: AppColors.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'No assigned branches match "$_searchQuery".',
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
