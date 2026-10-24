import 'package:flutter/material.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/app/theme/app_typography.dart';
import 'package:workaxis/core/widgets/app_button.dart';
import 'package:workaxis/core/widgets/status_chip.dart';
import 'package:workaxis/features/returns/domain/models/return_item.dart';

class ReturnDetailsDialog extends StatefulWidget {
  final ReturnItem item;
  final bool canReview;
  final Future<void> Function(ReturnStatus decision, String notes)? onReviewDecision;

  const ReturnDetailsDialog({
    super.key,
    required this.item,
    this.canReview = false,
    this.onReviewDecision,
  });

  @override
  State<ReturnDetailsDialog> createState() => _ReturnDetailsDialogState();
}

class _ReturnDetailsDialogState extends State<ReturnDetailsDialog> {
  final _notesController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleDecision(ReturnStatus decision) async {
    if (widget.onReviewDecision == null) return;
    setState(() => _isSubmitting = true);
    try {
      await widget.onReviewDecision!(decision, _notesController.text.trim());
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final isPending = item.status == ReturnStatus.pending;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      backgroundColor: AppColors.surfaceContainerLowest,
      insetPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.lg),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Return Request #${item.id}',
                          style: AppTypography.titleLarge.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${item.branchName} · Submitted by ${item.employeeName}',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  StatusChip(
                    label: item.status.label,
                    type: item.status.chipType,
                    width: 96,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              const Divider(height: 1, thickness: 1, color: AppColors.outlineSubtle),
              const SizedBox(height: AppSpacing.md),

              // Product Info Block
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(color: AppColors.outlineSubtle),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.productTitle,
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        _buildDetailItem(
                          icon: Icons.scale_outlined,
                          label: 'Quantity',
                          value: '${item.quantity % 1 == 0 ? item.quantity.toInt() : item.quantity} ${item.unit}',
                        ),
                        const SizedBox(width: AppSpacing.xl),
                        _buildDetailItem(
                          icon: Icons.receipt_long_outlined,
                          label: 'Bill / Invoice',
                          value: item.invoiceNumber,
                        ),
                        const SizedBox(width: AppSpacing.xl),
                        _buildDetailItem(
                          icon: item.reason.icon,
                          label: 'Reason',
                          value: item.reason.label,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Employee Remarks
              if (item.remarks != null && item.remarks!.isNotEmpty) ...[
                Text(
                  'Employee Remarks',
                  style: AppTypography.labelMedium.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    border: Border.all(color: AppColors.outlineSubtle),
                  ),
                  child: Text(
                    item.remarks!,
                    style: AppTypography.bodyMedium,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],

              // Attached Bill Image Simulation Card
              Text(
                'Attached Bill / Proof of Return',
                style: AppTypography.labelMedium.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                height: 120,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(color: AppColors.outlineSubtle),
                ),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLowest,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.receipt_outlined,
                          size: 28,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Invoice_${item.invoiceNumber}.pdf',
                            style: AppTypography.labelLarge.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Verified OCR bill attachment · 1.2 MB',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Prior Review Section if already reviewed
              if (!isPending && item.reviewedBy != null) ...[
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: item.status == ReturnStatus.approved
                        ? AppColors.statusActiveContainer
                        : AppColors.statusUrgentContainer,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            item.status == ReturnStatus.approved
                                ? Icons.check_circle_outline
                                : Icons.cancel_outlined,
                            size: 18,
                            color: item.status == ReturnStatus.approved
                                ? AppColors.statusActiveText
                                : AppColors.statusUrgentText,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            'Decision by ${item.reviewedBy}',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: item.status == ReturnStatus.approved
                                  ? AppColors.statusActiveText
                                  : AppColors.statusUrgentText,
                            ),
                          ),
                        ],
                      ),
                      if (item.reviewerNotes != null && item.reviewerNotes!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          item.reviewerNotes!,
                          style: TextStyle(
                            fontSize: 12,
                            color: item.status == ReturnStatus.approved
                                ? AppColors.statusActiveText
                                : AppColors.statusUrgentText,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],

              // Review actions for authorized managers
              if (widget.canReview && isPending) ...[
                Text(
                  'Reviewer Decision Remarks',
                  style: AppTypography.labelMedium.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                TextField(
                  controller: _notesController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    hintText: 'Enter reason or credit approval notes...',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.all(10),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    AppButton(
                      text: 'Reject Request',
                      variant: AppButtonVariant.outlined,
                      isLoading: _isSubmitting,
                      onPressed: () => _handleDecision(ReturnStatus.rejected),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    AppButton(
                      text: 'Approve Return',
                      variant: AppButtonVariant.primary,
                      isLoading: _isSubmitting,
                      onPressed: () => _handleDecision(ReturnStatus.approved),
                    ),
                  ],
                ),
              ] else ...[
                const SizedBox(height: AppSpacing.sm),
                Align(
                  alignment: Alignment.centerRight,
                  child: AppButton(
                    text: 'Close',
                    variant: AppButtonVariant.outlined,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 13, color: AppColors.textMuted),
            const SizedBox(width: 4),
            Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                fontSize: 11,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTypography.labelMedium.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
