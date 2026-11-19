import 'package:flutter/material.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/app/theme/app_typography.dart';
import 'package:workaxis/core/widgets/status_chip.dart';
import 'package:workaxis/features/assets/domain/models/employee_asset.dart';

class EmployeeAssetCard extends StatelessWidget {
  const EmployeeAssetCard({
    super.key,
    required this.asset,
    required this.canEdit,
    this.onEdit,
    this.onDelete,
  });

  final EmployeeAsset asset;
  final bool canEdit;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final status = switch (asset.status) {
      AssetStatus.assigned => (asset.status.label, StatusType.active),
      AssetStatus.maintenance => (asset.status.label, StatusType.urgent),
      AssetStatus.returned => (asset.status.label, StatusType.neutral),
    };

    return Card(
      elevation: 0,
      color: AppColors.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: AppSpacing.roundedMd,
        side: const BorderSide(color: AppColors.outlineSubtle),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: AppSpacing.roundedSm,
                  ),
                  child: const Icon(
                    Icons.inventory_2_outlined,
                    color: AppColors.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        asset.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.titleMedium.copyWith(
                          color: AppColors.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        asset.category,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (canEdit) ...[
                  IconButton(
                    tooltip: 'Edit asset',
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined),
                  ),
                  IconButton(
                    tooltip: 'Delete asset',
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline),
                  ),
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                StatusChip(label: status.$1, type: status.$2, width: null),
                _Tag(label: asset.assetTag),
              ],
            ),
            const Spacer(),
            const Divider(height: AppSpacing.lg),
            _MetadataLine(
              icon: Icons.person_outline,
              label: asset.employeeName,
            ),
            const SizedBox(height: AppSpacing.xs),
            _MetadataLine(icon: Icons.store_outlined, label: asset.branchName),
            if (asset.serialNumber != null &&
                asset.serialNumber!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              _MetadataLine(icon: Icons.qr_code_2, label: asset.serialNumber!),
            ],
          ],
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.sm,
      vertical: AppSpacing.xs,
    ),
    decoration: BoxDecoration(
      color: AppColors.surfaceContainerLow,
      borderRadius: AppSpacing.roundedPill,
    ),
    child: Text(
      label,
      style: AppTypography.labelSmall.copyWith(
        color: AppColors.onSurfaceVariant,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

class _MetadataLine extends StatelessWidget {
  const _MetadataLine({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 16, color: AppColors.onSurfaceVariant),
      const SizedBox(width: AppSpacing.sm),
      Expanded(
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ),
    ],
  );
}
