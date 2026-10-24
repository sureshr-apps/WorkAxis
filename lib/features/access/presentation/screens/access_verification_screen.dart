import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:workaxis/app/routing/app_routes.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/app/theme/app_typography.dart';
import 'package:workaxis/core/constants/app_breakpoints.dart';
import 'package:workaxis/core/responsive/responsive_container.dart';
import 'package:workaxis/core/widgets/app_button.dart';
import 'package:workaxis/features/access/presentation/controllers/access_controller.dart';
import 'package:workaxis/features/access/presentation/controllers/branch_context_controller.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';
import 'package:workaxis/features/authentication/presentation/controllers/auth_controller.dart';

/// Access Verification screen matching the approved Stitch design.
///
/// Resolves organizational boundaries, branch assignments, and routing permissions.
class AccessVerificationScreen extends StatefulWidget {
  const AccessVerificationScreen({super.key});

  @override
  State<AccessVerificationScreen> createState() =>
      _AccessVerificationScreenState();
}

class _AccessVerificationScreenState extends State<AccessVerificationScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startVerification();
    });
  }

  Future<void> _startVerification() async {
    final authController = context.read<AuthController>();
    final accessController = context.read<AccessController>();
    final branchController = context.read<BranchContextController>();

    final user = authController.currentUser;
    if (user == null) {
      if (mounted) context.go(AppRoutes.signIn);
      return;
    }

    final success = await accessController.resolveAccess(user);
    if (!mounted) return;

    if (success && accessController.accessContext != null) {
      final contextObj = accessController.accessContext!;
      branchController.initFromAccessContext(contextObj);

      _navigateAfterResolution(
        contextObj.user.role,
        contextObj.requiresBranchSelection,
      );
    }
  }

  void _navigateAfterResolution(UserRole role, bool requiresBranchSelection) {
    if (!mounted) return;

    if (role == UserRole.branchManager && requiresBranchSelection) {
      context.go(AppRoutes.selectBranch);
      return;
    }

    switch (role) {
      case UserRole.platformOwner:
      case UserRole.platformAdmin:
        context.go(AppRoutes.platformWorkspace);
        break;
      case UserRole.orgAdmin:
        context.go(AppRoutes.orgAdminWorkspace);
        break;
      case UserRole.branchManager:
        context.go(AppRoutes.branchManagerWorkspace);
        break;
      case UserRole.employee:
        context.go(AppRoutes.employeeWorkspace);
        break;
    }
  }

  Future<void> _handleRetry() async {
    final accessController = context.read<AccessController>();
    final branchController = context.read<BranchContextController>();

    final success = await accessController.retryResolveAccess();
    if (!mounted) return;

    if (success && accessController.accessContext != null) {
      final contextObj = accessController.accessContext!;
      branchController.initFromAccessContext(contextObj);
      _navigateAfterResolution(
        contextObj.user.role,
        contextObj.requiresBranchSelection,
      );
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
    final accessController = context.watch<AccessController>();
    final hasError = accessController.errorMessage != null;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Center(
          child: ResponsiveContainer(
            maxWidth: AppBreakpoints.maxFormCardWidth,
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: hasError ? _buildErrorState() : _buildVerifyingState(),
          ),
        ),
      ),
    );
  }

  Widget _buildVerifyingState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Operations Hub Verification Icon
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: AppColors.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(
          'Setting up your workspace',
          textAlign: TextAlign.center,
          style: AppTypography.headlineMedium.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Checking your account and access...',
          textAlign: TextAlign.center,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: AppSpacing.roundedMd,
        side: const BorderSide(color: AppColors.outlineSubtle),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.statusUrgentContainer,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(
                  Icons.lock_person_outlined,
                  size: 32,
                  color: AppColors.statusUrgentText,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              "We couldn't verify your access",
              textAlign: TextAlign.center,
              style: AppTypography.titleLarge.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Check your connection and try again.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            AppButton(
              text: 'Try Again',
              onPressed: _handleRetry,
              variant: AppButtonVariant.primary,
            ),
            const SizedBox(height: AppSpacing.md),
            AppButton(
              text: 'Sign Out',
              onPressed: _handleSignOut,
              variant: AppButtonVariant.outlined,
            ),
          ],
        ),
      ),
    );
  }
}
