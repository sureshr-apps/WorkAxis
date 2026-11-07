import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workaxis/app/session/session_controller.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/app/theme/app_typography.dart';
import 'package:workaxis/core/constants/app_breakpoints.dart';
import 'package:workaxis/core/responsive/responsive_container.dart';
import 'package:workaxis/core/widgets/app_button.dart';

/// State screen for a Branch Manager who has no active branch assignment.
///
/// Branch-scoped screens are unreachable until an administrator assigns at
/// least one active branch, so the only action offered is signing out.
class NoBranchAssignedScreen extends StatelessWidget {
  const NoBranchAssignedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Center(
          child: ResponsiveContainer(
            maxWidth: AppBreakpoints.maxFormCardWidth,
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    color: AppColors.statusPendingContainer,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.store_mall_directory_outlined,
                    size: 28,
                    color: AppColors.statusPendingText,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'No branch assigned',
                  textAlign: TextAlign.center,
                  style: AppTypography.titleLarge.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Your account is not assigned to an active branch yet. '
                  'Ask your administrator to assign you to a branch, then sign in again.',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                AppButton.outlined(
                  text: 'Sign Out',
                  onPressed: () => context.read<SessionController>().signOut(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
