import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/features/access/domain/models/active_branch_context.dart';

/// Shows the Branch Manager's active branch with an optional change action.
class BranchContextCard extends StatelessWidget {
  const BranchContextCard({
    super.key,
    required this.branch,
    this.onChangeBranch,
  });

  final ActiveBranchContext branch;

  /// When non-null (manager has several branches) a change button is shown.
  final VoidCallback? onChangeBranch;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: AppSpacing.roundedSm,
        border: Border.all(color: AppColors.outlineSubtle),
      ),
      child: Row(
        children: [
          const Icon(Icons.storefront, size: 18, color: AppColors.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    branch.branchName,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    branch.branchCode,
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 11,
                      color: AppColors.onSurfaceVariant,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
          if (onChangeBranch != null)
            IconButton(
              icon: const Icon(Icons.swap_horiz, size: 20),
              tooltip: 'Change Branch',
              onPressed: onChangeBranch,
              constraints: const BoxConstraints(
                minWidth: AppSpacing.minTouchTarget,
                minHeight: AppSpacing.minTouchTarget,
              ),
            ),
        ],
      ),
    );
  }
}
