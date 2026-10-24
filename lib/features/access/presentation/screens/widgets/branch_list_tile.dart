import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/app/theme/app_typography.dart';
import 'package:workaxis/core/widgets/status_chip.dart';
import 'package:workaxis/features/access/domain/models/branch_summary.dart';

/// Compact selectable branch item matching the refined Stitch Branch Selection design.
///
/// Layout per Stitch spec:
/// - Left: Branch initials/monogram badge ([CH], [ER], [WF], [PN]) in a compact rounded container.
/// - Middle:
///   - Line 1: Branch name (font-semibold, text-on-surface).
///   - Line 2: Branch code and city/location on one line (e.g. "CH-001 · Tumakuru").
///   - Line 3: Active employee count or unavailable notice.
/// - Right: Status chip ("Active" / "Unavailable") + trailing chevron icon.
class BranchListTile extends StatelessWidget {
  const BranchListTile({super.key, required this.branch, required this.onTap});

  final BranchSummary branch;
  final VoidCallback onTap;

  String get _monogram {
    final codeParts = branch.code.split('-');
    if (codeParts.isNotEmpty && codeParts.first.isNotEmpty) {
      return codeParts.first.toUpperCase();
    }
    final words = branch.name.trim().split(RegExp(r'\s+'));
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
    return branch.name.length >= 2
        ? branch.name.substring(0, 2).toUpperCase()
        : branch.name.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final isSelectable = branch.isActive;

    return Opacity(
      opacity: isSelectable ? 1.0 : 0.6,
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.roundedMd,
          side: BorderSide(
            color: isSelectable
                ? AppColors.outlineSubtle
                : AppColors.statusNeutralBorder,
          ),
        ),
        color: AppColors.surfaceContainerLowest,
        child: InkWell(
          onTap: isSelectable ? onTap : null,
          borderRadius: AppSpacing.roundedMd,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Row(
              children: [
                // Branch Monogram Badge
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: isSelectable
                        ? AppColors.primaryContainer
                        : AppColors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelectable
                          ? AppColors.primary.withValues(alpha: 0.15)
                          : AppColors.outlineVariant,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      _monogram,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isSelectable
                            ? AppColors.onPrimaryContainer
                            : AppColors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),

                // Branch Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        branch.name,
                        style: AppTypography.titleMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: isSelectable
                              ? AppColors.onSurface
                              : AppColors.textMuted,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${branch.code} · ${branch.location}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.labelMono.copyWith(
                          color: AppColors.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 2),
                      if (isSelectable)
                        Row(
                          children: [
                            const Icon(
                              Icons.badge_outlined,
                              size: 13,
                              color: AppColors.textMuted,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                '${branch.activeEmployeeCount} active employees',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.textMuted,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        )
                      else
                        Text(
                          'Temporarily offline · Terminal sync paused',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.statusUrgentText,
                            fontSize: 11,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),

                // Status chip & trailing chevron
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    StatusChip(
                      label: isSelectable ? 'Active' : 'Unavailable',
                      type: isSelectable
                          ? StatusType.active
                          : StatusType.neutral,
                      width: 96,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: isSelectable
                          ? AppColors.onSurfaceVariant
                          : AppColors.textMuted,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
