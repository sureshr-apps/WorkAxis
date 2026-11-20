import 'dart:async';

import 'package:flutter/material.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/app/theme/app_typography.dart';
import 'package:workaxis/core/formatting/date_time_formatters.dart';
import 'package:workaxis/core/time/business_time.dart';
import 'package:workaxis/core/widgets/app_button.dart';
import 'package:workaxis/core/widgets/app_icon_button.dart';
import 'package:workaxis/core/widgets/status_chip.dart';
import 'package:workaxis/features/assets/domain/models/employee_asset.dart';

class EmployeeAssetCard extends StatelessWidget {
  const EmployeeAssetCard({
    super.key,
    required this.asset,
    required this.canEdit,
    this.isEmployeeView = false,
    this.canAcknowledge = false,
    this.isAcknowledging = false,
    this.onEdit,
    this.onDelete,
    this.onAcknowledge,
  });

  final EmployeeAsset asset;
  final bool canEdit;
  final bool isEmployeeView;
  final bool canAcknowledge;
  final bool isAcknowledging;
  final FutureOr<void> Function()? onEdit;
  final FutureOr<void> Function()? onDelete;
  final FutureOr<void> Function()? onAcknowledge;

  @override
  Widget build(BuildContext context) {
    final status = switch (asset.status) {
      AssetStatus.assigned => (asset.status.label, StatusType.active),
      AssetStatus.maintenance => (asset.status.label, StatusType.urgent),
      AssetStatus.returned => (asset.status.label, StatusType.neutral),
    };
    final acknowledgement = _acknowledgementAction();

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
                  AppIconButton(
                    tooltip: 'Edit asset',
                    onPressed: onEdit,
                    icon: Icons.edit_outlined,
                  ),
                  AppIconButton(
                    tooltip: 'Delete asset',
                    onPressed: onDelete,
                    icon: Icons.delete_outline,
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
            const Divider(height: AppSpacing.lg),
            _MetadataLine(
              icon: Icons.person_outline,
              label: isEmployeeView
                  ? 'Assigned to you'
                  : 'Assigned to: ${asset.employeeName}',
            ),
            const SizedBox(height: AppSpacing.xs),
            _MetadataLine(
              icon: Icons.store_outlined,
              label: 'Branch: ${asset.branchName}',
            ),
            const SizedBox(height: AppSpacing.xs),
            _MetadataLine(
              icon: Icons.assignment_ind_outlined,
              label: 'Assigned by: ${_displayName(asset.assignedByName)}',
            ),
            const SizedBox(height: AppSpacing.xs),
            _MetadataLine(
              icon: Icons.schedule_outlined,
              label: 'Assigned: ${_formatTimestamp(asset.assignedAt)}',
            ),
            if (asset.serialNumber != null &&
                asset.serialNumber!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              _MetadataLine(
                icon: Icons.qr_code_2,
                label: 'Serial: ${asset.serialNumber!}',
              ),
            ],
            if (acknowledgement != null) ...[
              const SizedBox(height: AppSpacing.sm),
              acknowledgement,
            ],
            if (asset.acknowledgementStatus ==
                AssetAcknowledgementStatus.acknowledged) ...[
              const SizedBox(height: AppSpacing.xs),
              _MetadataLine(
                icon: Icons.verified_user_outlined,
                label:
                    'Acknowledged by: ${_displayName(asset.acknowledgedByName)}',
              ),
              const SizedBox(height: AppSpacing.xs),
              _MetadataLine(
                icon: Icons.schedule_outlined,
                label:
                    'Acknowledged: ${_formatTimestamp(asset.acknowledgedAt)}',
              ),
            ],
            if (asset.notes != null && asset.notes!.trim().isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              _MetadataLine(
                icon: Icons.notes_outlined,
                label: 'Notes: ${asset.notes!.trim()}',
                maxLines: 2,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget? _acknowledgementAction() {
    if (!asset.acknowledgementRequired ||
        asset.acknowledgementStatus == AssetAcknowledgementStatus.notRequired) {
      return null;
    }
    if (asset.acknowledgementStatus == AssetAcknowledgementStatus.pending) {
      if (canAcknowledge && onAcknowledge != null) {
        return AppButton.primary(
          text: 'Acknowledge receipt',
          iconData: Icons.check_circle_outline,
          isLoading: isAcknowledging,
          onPressed: isAcknowledging ? null : onAcknowledge,
        );
      }
      return const _AcknowledgementStatus(
        icon: Icons.hourglass_top_rounded,
        label: 'Awaiting employee acknowledgment',
        color: AppColors.statusUrgentText,
      );
    }
    return const _AcknowledgementStatus(
      icon: Icons.verified_outlined,
      label: 'Acknowledged',
      color: AppColors.statusActive,
    );
  }

  String _displayName(String? value) =>
      value == null || value.trim().isEmpty ? 'Not recorded' : value.trim();

  String _formatTimestamp(DateTime? value) {
    if (value == null) return 'Not recorded';
    final businessTime = value.toUtc().add(kBusinessUtcOffset);
    return '${AppFormatters.formatDateTime(businessTime)} IST';
  }
}

class _AcknowledgementStatus extends StatelessWidget {
  const _AcknowledgementStatus({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 17, color: color),
      const SizedBox(width: AppSpacing.xs),
      Expanded(
        child: Text(
          label,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.labelSmall.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ],
  );
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
  const _MetadataLine({
    required this.icon,
    required this.label,
    this.maxLines = 1,
  });

  final IconData icon;
  final String label;
  final int maxLines;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 16, color: AppColors.onSurfaceVariant),
      const SizedBox(width: AppSpacing.sm),
      Expanded(
        child: Text(
          label,
          maxLines: maxLines,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ),
    ],
  );
}
