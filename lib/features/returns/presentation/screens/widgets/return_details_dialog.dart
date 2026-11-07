import 'package:flutter/material.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/app/theme/app_typography.dart';
import 'package:workaxis/core/formatting/date_time_formatters.dart';
import 'package:workaxis/core/widgets/app_button.dart';
import 'package:workaxis/core/widgets/app_text_field.dart';
import 'package:workaxis/core/widgets/error_banner.dart';
import 'package:workaxis/core/widgets/status_chip.dart';
import 'package:workaxis/features/returns/domain/models/return_item.dart';
import 'package:workaxis/features/returns/presentation/return_presentation.dart';

/// Reviews a return decision. Returns null on success, or the message to show
/// inline when the decision could not be saved.
typedef ReturnReviewHandler = Future<String?> Function(
  ReturnStatus decision,
  String notes,
);

class ReturnDetailsDialog extends StatefulWidget {
  final ReturnItem item;
  final bool canReview;
  final ReturnReviewHandler? onReviewDecision;

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
  String? _errorMessage;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleDecision(ReturnStatus decision) async {
    final handler = widget.onReviewDecision;
    if (handler == null) return;
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    String? error;
    try {
      error = await handler(decision, _notesController.text.trim());
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _errorMessage = error;
        });
      }
    }
    if (error == null && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final isPending = item.status == ReturnStatus.pending;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedLg),
      backgroundColor: AppColors.surfaceContainerLowest,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.lg,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 580,
          maxHeight: MediaQuery.sizeOf(context).height * 0.9,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              _Header(item: item),
              const SizedBox(height: AppSpacing.lg),
              const Divider(
                height: 1,
                thickness: 1,
                color: AppColors.outlineSubtle,
              ),
              const SizedBox(height: AppSpacing.md),
              _ProductBlock(item: item),
              const SizedBox(height: AppSpacing.md),
              if (item.remarks != null && item.remarks!.isNotEmpty) ...[
                const _SectionLabel('Employee Remarks'),
                const SizedBox(height: AppSpacing.xs),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    borderRadius: AppSpacing.roundedSm,
                    border: Border.all(color: AppColors.outlineSubtle),
                  ),
                  child: Text(item.remarks!, style: AppTypography.bodyMedium),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              const _SectionLabel('Bill / Proof of Return'),
              const SizedBox(height: AppSpacing.xs),
              _BillAttachmentTile(hasBill: item.billImageUrl != null),
              const SizedBox(height: AppSpacing.md),
              if (!isPending && item.reviewedBy != null) ...[
                _DecisionSummary(item: item),
                const SizedBox(height: AppSpacing.md),
              ],
              if (_errorMessage != null) ...[
                ErrorBanner(message: _errorMessage!),
                const SizedBox(height: AppSpacing.md),
              ],
              if (widget.canReview && isPending) ...[
                const _SectionLabel('Reviewer Decision Remarks'),
                const SizedBox(height: AppSpacing.xs),
                AppTextField(
                  controller: _notesController,
                  maxLines: 2,
                  hintText: 'Enter reason or credit approval notes...',
                ),
                const SizedBox(height: AppSpacing.lg),
                Wrap(
                  alignment: WrapAlignment.end,
                  spacing: AppSpacing.md,
                  runSpacing: AppSpacing.sm,
                  children: [
                    AppButton.outlined(
                      text: 'Reject Request',
                      isFullWidth: false,
                      isLoading: _isSubmitting,
                      onPressed: () => _handleDecision(ReturnStatus.rejected),
                    ),
                    AppButton.primary(
                      text: 'Approve Return',
                      isFullWidth: false,
                      isLoading: _isSubmitting,
                      onPressed: () => _handleDecision(ReturnStatus.approved),
                    ),
                  ],
                ),
              ] else ...[
                const SizedBox(height: AppSpacing.sm),
                Align(
                  alignment: Alignment.centerRight,
                  child: AppButton.outlined(
                    text: 'Close',
                    isFullWidth: false,
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
}

class _Header extends StatelessWidget {
  const _Header({required this.item});

  final ReturnItem item;

  @override
  Widget build(BuildContext context) {
    return Row(
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
              const SizedBox(height: AppSpacing.xxs),
              Text(
                '${item.branchName} · Submitted by ${item.employeeName}',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        StatusChip(label: item.status.label, type: item.status.chipType),
      ],
    );
  }
}

class _ProductBlock extends StatelessWidget {
  const _ProductBlock({required this.item});

  final ReturnItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: AppSpacing.roundedMd,
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
          Wrap(
            spacing: AppSpacing.xl,
            runSpacing: AppSpacing.sm,
            children: [
              _DetailItem(
                icon: Icons.scale_outlined,
                label: 'Quantity',
                value: item.quantityLabel,
              ),
              _DetailItem(
                icon: Icons.receipt_long_outlined,
                label: 'Bill / Invoice',
                value: item.invoiceNumber,
              ),
              _DetailItem(
                icon: item.reason.icon,
                label: 'Reason',
                value: item.reason.label,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailItem extends StatelessWidget {
  const _DetailItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: AppColors.textMuted),
            const SizedBox(width: AppSpacing.xs),
            Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xxs),
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

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w700),
  );
}

/// Reflects only what the record knows: whether a bill image URL exists.
class _BillAttachmentTile extends StatelessWidget {
  const _BillAttachmentTile({required this.hasBill});

  final bool hasBill;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.kpiNeutralBackground,
        borderRadius: AppSpacing.roundedMd,
        border: Border.all(color: AppColors.outlineSubtle),
      ),
      child: Row(
        children: [
          Icon(
            hasBill
                ? Icons.receipt_outlined
                : Icons.image_not_supported_outlined,
            color: hasBill ? AppColors.primary : AppColors.textMuted,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              hasBill
                  ? 'A bill image is attached to this request.'
                  : 'No bill image was attached to this request.',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DecisionSummary extends StatelessWidget {
  const _DecisionSummary({required this.item});

  final ReturnItem item;

  @override
  Widget build(BuildContext context) {
    final approved = item.status == ReturnStatus.approved;
    final foreground = approved
        ? AppColors.statusActiveText
        : AppColors.statusUrgentText;
    final reviewedAt = item.reviewedAt;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: approved
            ? AppColors.statusActiveContainer
            : AppColors.statusUrgentContainer,
        borderRadius: AppSpacing.roundedMd,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                approved ? Icons.check_circle_outline : Icons.cancel_outlined,
                size: 18,
                color: foreground,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  reviewedAt == null
                      ? 'Decision by ${item.reviewedBy}'
                      : 'Decision by ${item.reviewedBy} · ${AppFormatters.formatDateTime(reviewedAt)}',
                  style: AppTypography.labelMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: foreground,
                  ),
                ),
              ),
            ],
          ),
          if (item.reviewerNotes != null && item.reviewerNotes!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              item.reviewerNotes!,
              style: AppTypography.bodySmall.copyWith(color: foreground),
            ),
          ],
        ],
      ),
    );
  }
}
