import 'package:flutter/material.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/app/theme/app_typography.dart';
import 'package:workaxis/features/branches/domain/models/branch_record.dart';

/// Locations / active / paired-kiosk counts above the branch list.
class BranchSummaryStrip extends StatelessWidget {
  const BranchSummaryStrip({super.key, required this.branches});

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
      borderRadius: AppSpacing.roundedPill,
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.secondary),
        const SizedBox(width: AppSpacing.xs),
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ],
    ),
  );
}
